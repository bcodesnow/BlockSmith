#include "appcontroller.h"
#include "utils.h"

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
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

using Utils::normalizePath;
using Utils::samePath;

namespace {

QString sessionFilePath()
{
    return QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation)
           + QStringLiteral("/session.json");
}

} // namespace

AppController::AppController(QObject *parent)
    : QObject(parent)
    , m_configManager(new ConfigManager(this))
    , m_md4cRenderer(new Md4cRenderer(this))
    , m_projectTreeModel(new ProjectTreeModel(this))
    , m_projectScanner(new ProjectScanner(m_configManager, m_projectTreeModel, this))
    , m_blockStore(new BlockStore(
        QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) + "/blocks.db.json", this))
    , m_promptStore(new PromptStore(
        QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) + "/prompts.db.json", this))
    , m_syncEngine(new SyncEngine(m_blockStore, m_projectTreeModel, this))
    , m_imageHandler(new ImageHandler(this))
    , m_jsonlStore(new JsonlStore(this))
    , m_exportManager(new ExportManager(m_md4cRenderer, this))
    , m_tabModel(new TabModel(m_blockStore, m_configManager, this))
    , m_searchManager(new SearchManager(m_projectTreeModel, m_configManager, this))
{
    m_fileManager = new FileManager(m_configManager, this);
    m_fileManager->setTabModel(m_tabModel);

    m_navigationManager = new NavigationManager(this);

    // Post-scan: rebuild block index
    connect(m_projectScanner, &ProjectScanner::scanComplete,
            this, [this](int count) {
                m_syncEngine->rebuildIndex();
                emit scanComplete(count);
            });

    // After file operations: clean up JSONL viewer if file gone, then rescan
    connect(m_fileManager, &FileManager::fileOperationComplete,
            this, [this]() {
                if (!m_jsonlStore->filePath().isEmpty()
                    && !QFileInfo::exists(m_jsonlStore->filePath())) {
                    m_jsonlStore->clear();
                }
                scan();
            });

    // Forward NavigationManager signals
    connect(m_navigationManager, &NavigationManager::navHistoryChanged,
            this, &AppController::navHistoryChanged);

    // Back/forward navigates to the path via openFile
    connect(m_navigationManager, &NavigationManager::navigateToPath,
            this, &AppController::openFile);

    // Forward SearchManager signals
    connect(m_searchManager, &SearchManager::searchResultsReady,
            this, &AppController::searchResultsReady);

    // When active tab changes, reconnect signals and update dependent managers
    connect(m_tabModel, &TabModel::activeDocumentChanged, this, [this]() {
        Document *doc = m_tabModel->activeDocument();

        // Disconnect old document signals
        if (m_connectedDocument) {
            disconnectActiveDocument(m_connectedDocument);
            m_connectedDocument = nullptr;
        }

        // Connect new document signals
        if (doc)
            connectActiveDocument(doc);

        m_connectedDocument = doc;

        emit currentDocumentChanged();
    });

    // Auto-save config changes apply to all open tabs
    auto applyAutoSave = [this]() {
        bool enabled = m_configManager->autoSaveEnabled();
        int interval = m_configManager->autoSaveInterval();
        for (int i = 0; i < m_tabModel->count(); ++i) {
            Document *doc = m_tabModel->tabDocument(i);
            if (doc)
                doc->setAutoSave(enabled, interval);
        }
    };
    connect(m_configManager, &ConfigManager::autoSaveEnabledChanged, this, applyAutoSave);
    connect(m_configManager, &ConfigManager::autoSaveIntervalChanged, this, applyAutoSave);

    // Save on focus loss if auto-save is enabled
    connect(qApp, &QGuiApplication::applicationStateChanged,
            this, [this](Qt::ApplicationState state) {
                if (state != Qt::ApplicationInactive || !m_configManager->autoSaveEnabled())
                    return;
                Document *doc = currentDocument();
                if (doc && doc->modified()) {
                    doc->save();
                    if (!doc->modified())
                        emit doc->autoSaved();
                }
            });
}

void AppController::connectActiveDocument(Document *doc)
{
    // Rebuild block index after document save
    m_docConnections.append(
        connect(doc, &Document::saved, m_syncEngine, &SyncEngine::rebuildIndex));

    // Deferred line navigation
    m_docConnections.append(
        connect(doc, &Document::filePathChanged, this, [this]() {
            if (m_pendingLineNumber <= 0 || m_pendingLinePath.isEmpty())
                return;

            Document *d = currentDocument();
            if (!d) return;
            const QString docPath = d->filePath();
            if (docPath.isEmpty())
                return;

            if (samePath(docPath, m_pendingLinePath)) {
                const int line = m_pendingLineNumber;
                m_pendingLinePath.clear();
                m_pendingLineNumber = -1;
                emit navigateToLineRequested(line);
                return;
            }

            m_pendingLinePath.clear();
            m_pendingLineNumber = -1;
        }));
}

void AppController::disconnectActiveDocument(Document *doc)
{
    Q_UNUSED(doc)
    for (auto &conn : m_docConnections)
        disconnect(conn);
    m_docConnections.clear();
}

AppController *AppController::create(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(scriptEngine)

    auto *instance = new AppController;
    QJSEngine::setObjectOwnership(instance, QJSEngine::CppOwnership);
    instance->moveToThread(engine->thread());
    return instance;
}

// --- Property getters ---

ConfigManager *AppController::configManager() const { return m_configManager; }
Md4cRenderer *AppController::md4cRenderer() const { return m_md4cRenderer; }
ProjectTreeModel *AppController::projectTreeModel() const { return m_projectTreeModel; }
ProjectScanner *AppController::projectScanner() const { return m_projectScanner; }

Document *AppController::currentDocument() const
{
    return m_tabModel->activeDocument();
}

BlockStore *AppController::blockStore() const { return m_blockStore; }
PromptStore *AppController::promptStore() const { return m_promptStore; }
SyncEngine *AppController::syncEngine() const { return m_syncEngine; }
FileManager *AppController::fileManager() const { return m_fileManager; }
ImageHandler *AppController::imageHandler() const { return m_imageHandler; }
JsonlStore *AppController::jsonlStore() const { return m_jsonlStore; }
ExportManager *AppController::exportManager() const { return m_exportManager; }
TabModel *AppController::tabModel() const { return m_tabModel; }
QStringList AppController::highlightedFiles() const { return m_highlightedFiles; }

// --- Block highlighting ---

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

// --- Scan ---

void AppController::scan()
{
    m_projectScanner->scan();
}

// --- File opening (now via TabModel) ---

void AppController::openFile(const QString &path)
{
    if (path.isEmpty())
        return;

    // JSONL files use special viewer — clear tabs' active document display
    if (path.endsWith(QStringLiteral(".jsonl"), Qt::CaseInsensitive)) {
        m_jsonlStore->load(path);
        m_configManager->addRecentFile(path);
        m_navigationManager->navPushPublic(path);
        return;
    }

    // Clear JSONL if switching to a non-JSONL file
    if (!m_jsonlStore->filePath().isEmpty())
        m_jsonlStore->clear();

    m_tabModel->openTab(path);
    m_navigationManager->navPushPublic(path);
}

void AppController::forceOpenFile(const QString &path)
{
    openFile(path);
}

void AppController::openFileAtLine(const QString &path, int lineNumber)
{
    if (path.isEmpty())
        return;

    if (lineNumber <= 0) {
        openFile(path);
        return;
    }

    Document *doc = currentDocument();
    if (doc && samePath(path, doc->filePath())) {
        emit navigateToLineRequested(lineNumber);
        return;
    }

    m_pendingLinePath = normalizePath(path);
    m_pendingLineNumber = lineNumber;
    openFile(path);
}

void AppController::goBack() { m_navigationManager->goBack(); }
void AppController::goForward() { m_navigationManager->goForward(); }
bool AppController::canGoBack() const { return m_navigationManager->canGoBack(); }
bool AppController::canGoForward() const { return m_navigationManager->canGoForward(); }

// --- Search forwarding ---

void AppController::searchFiles(const QString &query) { m_searchManager->searchFiles(query); }
bool AppController::fileExists(const QString &path) const { return QFileInfo::exists(path); }
QStringList AppController::getAllFiles() const { return m_searchManager->getAllFiles(); }
QVariantList AppController::fuzzyFilterFiles(const QString &query) const { return m_searchManager->fuzzyFilterFiles(query); }

// --- Session save/restore ---

void AppController::saveSession()
{
    QJsonObject root;
    root[QStringLiteral("tabs")] = m_tabModel->saveSession();
    root[QStringLiteral("activeIndex")] = m_tabModel->activeIndex();

    // Also save JSONL path if active
    if (!m_jsonlStore->filePath().isEmpty())
        root[QStringLiteral("jsonlPath")] = m_jsonlStore->filePath();

    QDir().mkpath(QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation));
    QFile file(sessionFilePath());
    if (file.open(QIODevice::WriteOnly)) {
        file.write(QJsonDocument(root).toJson(QJsonDocument::Compact));
    }
}

void AppController::restoreSession()
{
    QFile file(sessionFilePath());
    if (!file.open(QIODevice::ReadOnly))
        return;

    QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    if (doc.isNull())
        return;

    QJsonObject root = doc.object();
    QJsonArray tabs = root[QStringLiteral("tabs")].toArray();
    int activeIdx = root[QStringLiteral("activeIndex")].toInt(-1);

    if (!tabs.isEmpty())
        m_tabModel->restoreSession(tabs, activeIdx);

    // Restore JSONL if it was open (overlays tab area when active)
    QString jsonlPath = root[QStringLiteral("jsonlPath")].toString();
    if (!jsonlPath.isEmpty() && QFileInfo::exists(jsonlPath))
        m_jsonlStore->load(jsonlPath);
}

// --- Utility methods ---

void AppController::revealInExplorer(const QString &path) const
{
    QFileInfo fi(path);
    QString target = fi.isDir() ? fi.absoluteFilePath() : fi.absolutePath();

#ifdef Q_OS_WIN
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
