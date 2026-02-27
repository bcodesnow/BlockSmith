#include "filemanager.h"
#include "document.h"
#include "configmanager.h"

#include <QFile>
#include <QDir>
#include <QFileInfo>
#include <QTextStream>

namespace {

Qt::CaseSensitivity pathCaseSensitivity()
{
#ifdef Q_OS_WIN
    return Qt::CaseInsensitive;
#else
    return Qt::CaseSensitive;
#endif
}

QString normalizePath(const QString &path)
{
    return QDir::cleanPath(path).replace(QLatin1Char('\\'), QLatin1Char('/'));
}

} // namespace

FileManager::FileManager(Document *document, ConfigManager *config,
                         QObject *parent)
    : QObject(parent)
    , m_document(document)
    , m_config(config)
{
}

QString FileManager::createFile(const QString &parentDir, const QString &fileName)
{
    QDir dir(parentDir);
    if (!dir.exists())
        return QStringLiteral("Directory does not exist");

    QString name = fileName.trimmed();
    if (name.isEmpty())
        return QStringLiteral("File name cannot be empty");

    // Auto-append .md if no extension
    if (!name.contains('.'))
        name += QStringLiteral(".md");

    QString filePath = dir.absoluteFilePath(name);
    if (QFileInfo::exists(filePath))
        return QStringLiteral("File already exists: ") + name;

    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        return QStringLiteral("Could not create file");

    // Write a default heading from the filename (without extension)
    QTextStream out(&file);
    QString baseName = QFileInfo(name).completeBaseName();
    out << "# " << baseName << "\n";
    file.close();

    emit fileOperationComplete();
    return {};
}

QString FileManager::createFolder(const QString &parentDir, const QString &folderName)
{
    QDir dir(parentDir);
    if (!dir.exists())
        return QStringLiteral("Parent directory does not exist");

    QString name = folderName.trimmed();
    if (name.isEmpty())
        return QStringLiteral("Folder name cannot be empty");

    if (dir.exists(name))
        return QStringLiteral("Folder already exists: ") + name;

    if (!dir.mkdir(name))
        return QStringLiteral("Could not create folder");

    emit fileOperationComplete();
    return {};
}

QString FileManager::renameItem(const QString &oldPath, const QString &newName)
{
    QString name = newName.trimmed();
    if (name.isEmpty())
        return QStringLiteral("Name cannot be empty");

    QFileInfo fi(oldPath);
    if (!fi.exists())
        return QStringLiteral("Item does not exist");

    if (isProjectRoot(oldPath))
        return QStringLiteral("Cannot rename a project root");

    QString newPath = fi.absolutePath() + QDir::separator() + name;
    if (QFileInfo::exists(newPath))
        return QStringLiteral("An item with that name already exists");

    bool ok = false;
    if (fi.isDir()) {
        QDir dir(fi.absolutePath());
        ok = dir.rename(fi.fileName(), name);
    } else {
        ok = QFile::rename(oldPath, newPath);
    }

    if (!ok)
        return QStringLiteral("Rename failed");

    repointOpenDocument(oldPath, newPath, fi.isDir());

    emit fileOperationComplete();
    return {};
}

QString FileManager::moveItem(const QString &sourcePath, const QString &destDir)
{
    QFileInfo srcInfo(sourcePath);
    if (!srcInfo.exists())
        return QStringLiteral("Source does not exist");

    QDir dest(destDir);
    if (!dest.exists())
        return QStringLiteral("Destination directory does not exist");

    if (isProjectRoot(sourcePath))
        return QStringLiteral("Cannot move a project root");

    QString newPath = dest.absoluteFilePath(srcInfo.fileName());
    if (QFileInfo::exists(newPath))
        return QStringLiteral("An item with that name already exists in the destination");

    // Same parent — no-op
    if (srcInfo.absolutePath() == dest.absolutePath())
        return {};

    bool ok = QFile::rename(sourcePath, newPath);
    if (!ok)
        return QStringLiteral("Move failed");

    repointOpenDocument(sourcePath, newPath, srcInfo.isDir());

    emit fileOperationComplete();
    return {};
}

QString FileManager::deleteItem(const QString &path)
{
    QFileInfo fi(path);
    if (!fi.exists())
        return QStringLiteral("Item does not exist");

    if (isProjectRoot(path))
        return QStringLiteral("Cannot delete a project root");

    bool ok = false;
    if (fi.isDir()) {
        QDir dir(path);
        ok = dir.removeRecursively();
    } else {
        ok = QFile::remove(path);
    }

    if (!ok)
        return QStringLiteral("Delete failed");

    clearOpenDocumentForDeletedPath(path, fi.isDir());

    emit fileOperationComplete();
    return {};
}

QString FileManager::duplicateFile(const QString &sourcePath)
{
    QFileInfo fi(sourcePath);
    if (!fi.exists() || !fi.isFile())
        return QStringLiteral("Source file does not exist");

    QString baseName = fi.completeBaseName();
    QString suffix = fi.suffix();
    QString dir = fi.absolutePath();

    // Find a unique name: "file copy.md", "file copy 2.md", etc.
    QString newPath;
    QString copyName = baseName + " copy";
    newPath = dir + QDir::separator() + copyName
              + (suffix.isEmpty() ? QString() : QStringLiteral(".") + suffix);

    int counter = 2;
    while (QFileInfo::exists(newPath)) {
        copyName = baseName + " copy " + QString::number(counter);
        newPath = dir + QDir::separator() + copyName
                  + (suffix.isEmpty() ? QString() : QStringLiteral(".") + suffix);
        ++counter;
    }

    if (!QFile::copy(sourcePath, newPath))
        return QStringLiteral("Duplicate failed");

    emit fileOperationComplete();
    return {};
}

bool FileManager::isProjectRoot(const QString &path) const
{
    // A project root is a directory that directly contains a trigger file
    QFileInfo fi(path);
    if (!fi.isDir())
        return false;

    QDir dir(path);
    const QStringList triggers = m_config->triggerFiles();
    for (const QString &trigger : triggers) {
        if (dir.exists(trigger))
            return true;
    }
    return false;
}

bool FileManager::isSamePath(const QString &a, const QString &b) const
{
    return normalizePath(a).compare(normalizePath(b), pathCaseSensitivity()) == 0;
}

bool FileManager::isPathInside(const QString &path, const QString &directoryPath) const
{
    if (path.isEmpty() || directoryPath.isEmpty())
        return false;

    const QString normalizedPath = normalizePath(path);
    QString normalizedDir = normalizePath(directoryPath);

    if (normalizedDir.isEmpty())
        return false;

    if (normalizedPath.compare(normalizedDir, pathCaseSensitivity()) == 0)
        return true;

    if (!normalizedDir.endsWith(QLatin1Char('/')))
        normalizedDir += QLatin1Char('/');

    return normalizedPath.startsWith(normalizedDir, pathCaseSensitivity());
}

QString FileManager::remapPathPrefix(const QString &path, const QString &oldPrefix,
                                     const QString &newPrefix) const
{
    const QString normalizedPath = normalizePath(path);
    QString normalizedOld = normalizePath(oldPrefix);
    QString normalizedNew = normalizePath(newPrefix);

    if (normalizedPath.compare(normalizedOld, pathCaseSensitivity()) == 0)
        return QDir::toNativeSeparators(normalizedNew);

    if (!normalizedOld.endsWith(QLatin1Char('/')))
        normalizedOld += QLatin1Char('/');
    if (!normalizedNew.endsWith(QLatin1Char('/')))
        normalizedNew += QLatin1Char('/');

    if (!normalizedPath.startsWith(normalizedOld, pathCaseSensitivity()))
        return QString();

    const QString suffix = normalizedPath.mid(normalizedOld.length());
    return QDir::toNativeSeparators(normalizedNew + suffix);
}

void FileManager::repointOpenDocument(const QString &oldPath, const QString &newPath,
                                      bool sourceIsDirectory)
{
    const QString docPath = m_document->filePath();
    if (docPath.isEmpty())
        return;

    QString targetPath;
    if (sourceIsDirectory) {
        if (!isPathInside(docPath, oldPath))
            return;
        targetPath = remapPathPrefix(docPath, oldPath, newPath);
    } else {
        if (!isSamePath(docPath, oldPath))
            return;
        targetPath = newPath;
    }

    if (targetPath.isEmpty() || isSamePath(docPath, targetPath))
        return;

    if (m_document->modified())
        m_document->saveTo(targetPath);
    else
        m_document->load(targetPath);
}

void FileManager::clearOpenDocumentForDeletedPath(const QString &deletedPath, bool isDirectory)
{
    const QString docPath = m_document->filePath();
    if (docPath.isEmpty())
        return;

    if (isDirectory) {
        if (isPathInside(docPath, deletedPath))
            m_document->clear();
        return;
    }

    if (isSamePath(docPath, deletedPath))
        m_document->clear();
}
