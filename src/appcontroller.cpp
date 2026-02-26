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
    , m_navigationManager(new NavigationManager(m_currentDocument, m_jsonlStore, m_configManager, this))
    , m_searchManager(new SearchManager(m_projectTreeModel, m_configManager, this))
{
    m_currentDocument->setBlockStore(m_blockStore);

    // Post-scan: rebuild block index
    connect(m_projectScanner, &ProjectScanner::scanComplete,
            this, [this](int count) {
                m_syncEngine->rebuildIndex();
                emit scanComplete(count);
            });

    // Rebuild block index after document save
    connect(m_currentDocument, &Document::saved,
            m_syncEngine, &SyncEngine::rebuildIndex);

    // After file operations: clean up JSONL viewer if file gone, then rescan
    connect(m_fileManager, &FileManager::fileOperationComplete,
            this, [this]() {
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
                    if (!m_currentDocument->modified())
                        emit m_currentDocument->autoSaved();
                }
            });

    // Forward NavigationManager signals
    connect(m_navigationManager, &NavigationManager::unsavedChangesWarning,
            this, &AppController::unsavedChangesWarning);
    connect(m_navigationManager, &NavigationManager::navHistoryChanged,
            this, &AppController::navHistoryChanged);

    // Forward SearchManager signals
    connect(m_searchManager, &SearchManager::searchResultsReady,
            this, &AppController::searchResultsReady);
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
Document *AppController::currentDocument() const { return m_currentDocument; }
BlockStore *AppController::blockStore() const { return m_blockStore; }
PromptStore *AppController::promptStore() const { return m_promptStore; }
SyncEngine *AppController::syncEngine() const { return m_syncEngine; }
FileManager *AppController::fileManager() const { return m_fileManager; }
ImageHandler *AppController::imageHandler() const { return m_imageHandler; }
JsonlStore *AppController::jsonlStore() const { return m_jsonlStore; }
ExportManager *AppController::exportManager() const { return m_exportManager; }
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

// --- Navigation forwarding ---

void AppController::openFile(const QString &path) { m_navigationManager->openFile(path); }
void AppController::forceOpenFile(const QString &path) { m_navigationManager->forceOpenFile(path); }
void AppController::goBack() { m_navigationManager->goBack(); }
void AppController::goForward() { m_navigationManager->goForward(); }
bool AppController::canGoBack() const { return m_navigationManager->canGoBack(); }
bool AppController::canGoForward() const { return m_navigationManager->canGoForward(); }

// --- Search forwarding ---

void AppController::searchFiles(const QString &query) { m_searchManager->searchFiles(query); }
QStringList AppController::getAllFiles() const { return m_searchManager->getAllFiles(); }
QVariantList AppController::fuzzyFilterFiles(const QString &query) const { return m_searchManager->fuzzyFilterFiles(query); }

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
