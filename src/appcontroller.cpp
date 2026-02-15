#include "appcontroller.h"

#include <QFile>
#include <QTextStream>
#include <QStandardPaths>
#include <QDesktopServices>
#include <QUrl>
#include <QDir>
#include <QFileInfo>
#include <QGuiApplication>
#include <QClipboard>
#include <QProcess>

AppController::AppController(QObject *parent)
    : QObject(parent)
    , m_configManager(new ConfigManager(this))
    , m_md4cRenderer(new Md4cRenderer(this))
    , m_projectTreeModel(new ProjectTreeModel(this))
    , m_projectScanner(new ProjectScanner(m_configManager, m_projectTreeModel, this))
    , m_currentDocument(new MdDocument(this))
    , m_blockStore(new BlockStore(
        QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) + "/blocks.db.json", this))
    , m_promptStore(new PromptStore(
        QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) + "/prompts.db.json", this))
    , m_syncEngine(new SyncEngine(m_blockStore, m_projectTreeModel, this))
    , m_fileManager(new FileManager(m_currentDocument, m_configManager, this))
{
    connect(m_projectScanner, &ProjectScanner::scanComplete,
            this, &AppController::scanComplete);
    connect(m_fileManager, &FileManager::fileOperationComplete,
            this, &AppController::scan);
}

AppController *AppController::create(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(scriptEngine)

    auto *instance = new AppController;
    QJSEngine::setObjectOwnership(instance, QJSEngine::CppOwnership);
    instance->moveToThread(engine->thread());
    return instance;
}

ConfigManager *AppController::configManager() const { return m_configManager; }
Md4cRenderer *AppController::md4cRenderer() const { return m_md4cRenderer; }
ProjectTreeModel *AppController::projectTreeModel() const { return m_projectTreeModel; }
ProjectScanner *AppController::projectScanner() const { return m_projectScanner; }
MdDocument *AppController::currentDocument() const { return m_currentDocument; }
BlockStore *AppController::blockStore() const { return m_blockStore; }
PromptStore *AppController::promptStore() const { return m_promptStore; }
SyncEngine *AppController::syncEngine() const { return m_syncEngine; }
FileManager *AppController::fileManager() const { return m_fileManager; }
QStringList AppController::highlightedFiles() const { return m_highlightedFiles; }

void AppController::highlightBlock(const QString &blockId)
{
    QStringList files;
    if (!blockId.isEmpty())
        files = m_syncEngine->filesContainingBlock(blockId);

    if (m_highlightedFiles != files) {
        m_highlightedFiles = files;
        emit highlightedFilesChanged();
    }
}

void AppController::scan()
{
    m_projectScanner->scan();
}

void AppController::openFile(const QString &path)
{
    if (path == m_currentDocument->filePath())
        return;

    if (m_currentDocument->modified()) {
        emit unsavedChangesWarning(path);
        return;
    }

    m_currentDocument->load(path);
}

void AppController::forceOpenFile(const QString &path)
{
    m_currentDocument->load(path);
}

void AppController::revealInExplorer(const QString &path) const
{
    QFileInfo fi(path);
    QString target = fi.isDir() ? fi.absoluteFilePath() : fi.absolutePath();

#ifdef Q_OS_WIN
    // Select the file in Explorer
    if (fi.isFile()) {
        QStringList args;
        args << "/select," << QDir::toNativeSeparators(fi.absoluteFilePath());
        QProcess::startDetached("explorer.exe", args);
        return;
    }
#endif

    QDesktopServices::openUrl(QUrl::fromLocalFile(target));
}

void AppController::copyToClipboard(const QString &text) const
{
    QGuiApplication::clipboard()->setText(text);
}

QStringList AppController::fileTriggerFiles() const
{
    QStringList result;
    const QStringList triggers = m_configManager->triggerFiles();
    for (const QString &t : triggers) {
        // Keep triggers with a file extension (last '.' not at position 0)
        // This filters out directory markers like ".git"
        int lastDot = t.lastIndexOf('.');
        if (lastDot > 0)
            result.append(t);
    }
    return result;
}

QString AppController::createProject(const QString &folderPath, const QString &triggerFileName)
{
    QDir dir(folderPath);
    if (!dir.exists())
        return QStringLiteral("Folder does not exist");

    QString filePath = dir.absoluteFilePath(triggerFileName);
    if (QFileInfo::exists(filePath))
        return QStringLiteral("File already exists: ") + triggerFileName;

    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        return QStringLiteral("Could not create file");

    QTextStream out(&file);
    out << "# " << dir.dirName() << "\n";
    file.close();

    // Ensure the folder's parent is in search paths
    QString parentPath = QFileInfo(folderPath).absolutePath();
    QStringList paths = m_configManager->searchPaths();
    bool covered = false;
    for (const QString &sp : paths) {
        if (folderPath.startsWith(sp, Qt::CaseInsensitive) || parentPath == sp) {
            covered = true;
            break;
        }
    }
    if (!covered) {
        paths.append(parentPath);
        m_configManager->setSearchPaths(paths);
        m_configManager->save();
    }

    scan();
    return QString();
}

QVariantList AppController::searchFiles(const QString &query) const
{
    QVariantList results;
    if (query.length() < 2) return results;

    const QStringList files = m_syncEngine->allMdFiles();

    for (const QString &filePath : files) {
        QFile file(filePath);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
            continue;

        QString content = QTextStream(&file).readAll();
        file.close();

        const QStringList lines = content.split('\n');
        for (int i = 0; i < lines.size(); i++) {
            int col = lines[i].indexOf(query, 0, Qt::CaseInsensitive);
            if (col < 0) continue;

            QVariantMap hit;
            hit["filePath"] = filePath;
            hit["line"] = i + 1;
            hit["text"] = lines[i].trimmed();
            results.append(hit);

            if (results.size() >= 500) return results;
        }
    }

    return results;
}
