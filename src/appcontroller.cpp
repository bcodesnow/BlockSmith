#include "appcontroller.h"

#include <QFile>
#include <QTextStream>
#include <QStandardPaths>
#include <QDesktopServices>
#include <QUrl>
#include <QDir>
#include <QFileInfo>
#include <QGuiApplication>
#include <QtConcurrent>
#include <QClipboard>
#include <QProcess>
#include <QPointer>
#include <functional>

AppController::AppController(QObject *parent)
    : QObject(parent)
    , m_configManager(new ConfigManager(this))
    , m_md4cRenderer(new Md4cRenderer(this))
    , m_projectTreeModel(new ProjectTreeModel(this))
    , m_projectScanner(new ProjectScanner(m_configManager, m_projectTreeModel, this))
    , m_currentDocument(new Document(this))
    , m_blockStore(new BlockStore(
        QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) + "/blocks.db.json", this))
    , m_promptStore(new PromptStore(
        QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) + "/prompts.db.json", this))
    , m_syncEngine(new SyncEngine(m_blockStore, m_projectTreeModel, this))
    , m_fileManager(new FileManager(m_currentDocument, m_configManager, this))
    , m_imageHandler(new ImageHandler(this))
    , m_jsonlStore(new JsonlStore(this))
    , m_exportManager(new ExportManager(m_md4cRenderer, this))
{
    m_currentDocument->setBlockStore(m_blockStore);

    connect(m_projectScanner, &ProjectScanner::scanComplete,
            this, [this](int count) {
                m_syncEngine->rebuildIndex();
                emit scanComplete(count);
            });
    connect(m_currentDocument, &Document::saved,
            m_syncEngine, &SyncEngine::rebuildIndex);
    connect(m_fileManager, &FileManager::fileOperationComplete,
            this, [this]() {
                // Clear JSONL viewer if its file was deleted/moved
                if (!m_jsonlStore->filePath().isEmpty()
                    && !QFileInfo::exists(m_jsonlStore->filePath())) {
                    m_jsonlStore->clear();
                }
                scan();
            });

    // Auto-save: apply initial config and react to changes
    auto applyAutoSave = [this]() {
        m_currentDocument->setAutoSave(m_configManager->autoSaveEnabled(),
                                       m_configManager->autoSaveInterval());
    };
    connect(m_configManager, &ConfigManager::autoSaveEnabledChanged, this, applyAutoSave);
    connect(m_configManager, &ConfigManager::autoSaveIntervalChanged, this, applyAutoSave);
    applyAutoSave();

    // Save on focus loss if auto-save is enabled
    connect(qApp, &QGuiApplication::applicationStateChanged,
            this, [this](Qt::ApplicationState state) {
                if (state == Qt::ApplicationInactive
                    && m_configManager->autoSaveEnabled()
                    && m_currentDocument->modified()) {
                    m_currentDocument->save();
                    // Only signal auto-saved if save succeeded
                    if (!m_currentDocument->modified())
                        emit m_currentDocument->autoSaved();
                }
            });
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
Document *AppController::currentDocument() const { return m_currentDocument; }
BlockStore *AppController::blockStore() const { return m_blockStore; }
PromptStore *AppController::promptStore() const { return m_promptStore; }
SyncEngine *AppController::syncEngine() const { return m_syncEngine; }
FileManager *AppController::fileManager() const { return m_fileManager; }
ImageHandler *AppController::imageHandler() const { return m_imageHandler; }
JsonlStore *AppController::jsonlStore() const { return m_jsonlStore; }
ExportManager *AppController::exportManager() const { return m_exportManager; }
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

    // Route .jsonl files to the JSONL viewer
    if (path.endsWith(QStringLiteral(".jsonl"), Qt::CaseInsensitive)) {
        if (m_currentDocument->modified()) {
            emit unsavedChangesWarning(path);
            return;
        }
        m_currentDocument->clear();
        m_jsonlStore->load(path);
        m_configManager->addRecentFile(path);
        return;
    }

    // Clear JSONL state when switching to a regular file
    if (!m_jsonlStore->filePath().isEmpty())
        m_jsonlStore->clear();

    if (m_currentDocument->modified()) {
        emit unsavedChangesWarning(path);
        return;
    }

    m_currentDocument->load(path);
    m_configManager->addRecentFile(path);
}

void AppController::forceOpenFile(const QString &path)
{
    if (path.endsWith(QStringLiteral(".jsonl"), Qt::CaseInsensitive)) {
        m_currentDocument->clear();
        m_jsonlStore->load(path);
    } else {
        if (!m_jsonlStore->filePath().isEmpty())
            m_jsonlStore->clear();
        m_currentDocument->load(path);
    }
    m_configManager->addRecentFile(path);
}

QStringList AppController::getAllFiles() const
{
    QStringList files;
    std::function<void(TreeNode*)> collect = [&](TreeNode *node) {
        if (!node) return;
        if (node->nodeType() == TreeNode::MdFile) {
            files.append(node->path());
            return;
        }
        for (int i = 0; i < node->childCount(); i++)
            collect(node->child(i));
    };
    collect(m_projectTreeModel->rootNode());
    return files;
}

static int fuzzyScore(const QString &query, const QString &text)
{
    const QString lq = query.toLower();
    const QString lt = text.toLower();

    // Exact substring match gets highest base score
    int subIdx = lt.indexOf(lq);
    if (subIdx >= 0)
        return 1000 - subIdx;

    // Character-by-character: all query chars must appear in order
    int score = 0;
    int qi = 0;
    int lastMatchIdx = -1;
    for (int ti = 0; ti < lt.length() && qi < lq.length(); ti++) {
        if (lt[ti] == lq[qi]) {
            score += 10;
            if (lastMatchIdx == ti - 1) score += 5;  // consecutive bonus
            if (ti == 0 || lt[ti - 1] == '/' || lt[ti - 1] == '\\') score += 8;  // word boundary
            lastMatchIdx = ti;
            qi++;
        }
    }
    return qi == lq.length() ? score : -1;
}

QVariantList AppController::fuzzyFilterFiles(const QString &query) const
{
    const QString trimmed = query.trimmed();
    QVariantList results;

    if (trimmed.isEmpty()) {
        // Return recent files
        const QStringList recent = m_configManager->recentFiles();
        for (int i = 0; i < recent.size(); i++) {
            const QString &fp = recent[i];
            int lastSep = fp.lastIndexOf('/');
            if (lastSep < 0) lastSep = fp.lastIndexOf('\\');
            QVariantMap entry;
            entry[QStringLiteral("filePath")] = fp;
            entry[QStringLiteral("fileName")] = fp.mid(lastSep + 1);
            entry[QStringLiteral("dirPath")] = QString(fp.left(lastSep)).replace('\\', '/');
            entry[QStringLiteral("score")] = 10000 - i;
            entry[QStringLiteral("isRecent")] = true;
            results.append(entry);
        }
        return results;
    }

    // Fuzzy filter all files
    const QStringList allFiles = getAllFiles();
    struct ScoredEntry { QString filePath; QString fileName; QString dirPath; int score; };
    QVector<ScoredEntry> scored;

    for (const QString &fp : allFiles) {
        QString normalized = QString(fp).replace('\\', '/');
        int lastSep = normalized.lastIndexOf('/');
        QString fileName = normalized.mid(lastSep + 1);
        int s = fuzzyScore(trimmed, fileName);
        if (s < 0) {
            s = fuzzyScore(trimmed, normalized);
            if (s >= 0) s = qMax(0, s - 100);
        }
        if (s >= 0) {
            scored.append({fp, fileName, normalized.left(lastSep), s});
        }
    }

    std::sort(scored.begin(), scored.end(), [](const ScoredEntry &a, const ScoredEntry &b) {
        return a.score > b.score;
    });

    int limit = qMin(scored.size(), 20);
    for (int i = 0; i < limit; i++) {
        QVariantMap entry;
        entry[QStringLiteral("filePath")] = scored[i].filePath;
        entry[QStringLiteral("fileName")] = scored[i].fileName;
        entry[QStringLiteral("dirPath")] = scored[i].dirPath;
        entry[QStringLiteral("score")] = scored[i].score;
        entry[QStringLiteral("isRecent")] = false;
        results.append(entry);
    }
    return results;
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

void AppController::searchFiles(const QString &query)
{
    // Cancel any previous search
    if (m_searchCancel)
        m_searchCancel->store(true);

    if (query.length() < 2) {
        emit searchResultsReady({});
        return;
    }

    // Gather file list on main thread (fast — just tree walk)
    const QStringList files = m_syncEngine->allMdFiles();

    // Shared cancel flag for this search run
    auto cancel = std::make_shared<std::atomic<bool>>(false);
    m_searchCancel = cancel;

    // Run file I/O + search on a worker thread
    QPointer<AppController> self(this);
    QtConcurrent::run([self, query, files, cancel]() {
        QVariantList results;

        for (const QString &filePath : files) {
            if (cancel->load()) return;

            QFile file(filePath);
            if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
                continue;

            QTextStream in(&file);
            int lineNum = 0;
            while (!in.atEnd()) {
                if (cancel->load()) return;
                const QString line = in.readLine();
                lineNum++;

                if (line.indexOf(query, 0, Qt::CaseInsensitive) < 0)
                    continue;

                QVariantMap hit;
                hit["filePath"] = filePath;
                hit["line"] = lineNum;
                hit["text"] = line.trimmed();
                results.append(hit);

                if (results.size() >= 200) break;
            }
            if (results.size() >= 200) break;
        }

        if (cancel->load() || !self) return;

        QMetaObject::invokeMethod(self.data(), "searchResultsReady",
                                  Qt::QueuedConnection,
                                  Q_ARG(QVariantList, results));
    });
}
