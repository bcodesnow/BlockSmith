#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QtQml/qqmlregistration.h>
#include <atomic>

#include "configmanager.h"
#include "md4crenderer.h"
#include "projecttreemodel.h"
#include "projectscanner.h"
#include "mddocument.h"
#include "blockstore.h"
#include "promptstore.h"
#include "syncengine.h"
#include "filemanager.h"
#include "imagehandler.h"
#include "jsonlstore.h"
#include "exportmanager.h"

class AppController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(ConfigManager* configManager READ configManager CONSTANT)
    Q_PROPERTY(Md4cRenderer* md4cRenderer READ md4cRenderer CONSTANT)
    Q_PROPERTY(ProjectTreeModel* projectTreeModel READ projectTreeModel CONSTANT)
    Q_PROPERTY(ProjectScanner* projectScanner READ projectScanner CONSTANT)
    Q_PROPERTY(MdDocument* currentDocument READ currentDocument CONSTANT)
    Q_PROPERTY(BlockStore* blockStore READ blockStore CONSTANT)
    Q_PROPERTY(PromptStore* promptStore READ promptStore CONSTANT)
    Q_PROPERTY(SyncEngine* syncEngine READ syncEngine CONSTANT)
    Q_PROPERTY(FileManager* fileManager READ fileManager CONSTANT)
    Q_PROPERTY(ImageHandler* imageHandler READ imageHandler CONSTANT)
    Q_PROPERTY(JsonlStore* jsonlStore READ jsonlStore CONSTANT)
    Q_PROPERTY(ExportManager* exportManager READ exportManager CONSTANT)
    Q_PROPERTY(QStringList highlightedFiles READ highlightedFiles NOTIFY highlightedFilesChanged)

public:
    explicit AppController(QObject *parent = nullptr);

    static AppController *create(QQmlEngine *engine, QJSEngine *scriptEngine);

    ConfigManager *configManager() const;
    Md4cRenderer *md4cRenderer() const;
    ProjectTreeModel *projectTreeModel() const;
    ProjectScanner *projectScanner() const;
    MdDocument *currentDocument() const;
    BlockStore *blockStore() const;
    PromptStore *promptStore() const;
    SyncEngine *syncEngine() const;
    FileManager *fileManager() const;
    ImageHandler *imageHandler() const;
    JsonlStore *jsonlStore() const;
    ExportManager *exportManager() const;
    QStringList highlightedFiles() const;

    Q_INVOKABLE void searchFiles(const QString &query);
    Q_INVOKABLE void revealInExplorer(const QString &path) const;
    Q_INVOKABLE void copyToClipboard(const QString &text) const;
    Q_INVOKABLE QStringList fileTriggerFiles() const;
    Q_INVOKABLE QString createProject(const QString &folderPath, const QString &triggerFileName);

    Q_INVOKABLE void forceOpenFile(const QString &path);
    Q_INVOKABLE QStringList getAllFiles() const;

signals:
    void scanComplete(int projectCount);
    void highlightedFilesChanged();
    void unsavedChangesWarning(const QString &pendingPath);
    void searchResultsReady(const QVariantList &results);

public slots:
    void scan();
    void openFile(const QString &path);
    void highlightBlock(const QString &blockId);

private:
    ConfigManager *m_configManager = nullptr;
    Md4cRenderer *m_md4cRenderer = nullptr;
    ProjectTreeModel *m_projectTreeModel = nullptr;
    ProjectScanner *m_projectScanner = nullptr;
    MdDocument *m_currentDocument = nullptr;
    BlockStore *m_blockStore = nullptr;
    PromptStore *m_promptStore = nullptr;
    SyncEngine *m_syncEngine = nullptr;
    FileManager *m_fileManager = nullptr;
    ImageHandler *m_imageHandler = nullptr;
    JsonlStore *m_jsonlStore = nullptr;
    ExportManager *m_exportManager = nullptr;
    QStringList m_highlightedFiles;
    std::shared_ptr<std::atomic<bool>> m_searchCancel;
};
