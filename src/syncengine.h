#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QtQml/qqmlregistration.h>

class BlockStore;
class ProjectTreeModel;
class TreeNode;

class SyncEngine : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Use via AppController.syncEngine")

public:
    explicit SyncEngine(BlockStore *blockStore, ProjectTreeModel *treeModel,
                        QObject *parent = nullptr);

    // Push a block's content from registry to all files that contain it
    Q_INVOKABLE int pushBlock(const QString &blockId);

    // Pull a block's content from a specific file into the registry
    Q_INVOKABLE void pullBlock(const QString &blockId, const QString &filePath);

    // Find all .md files across projects that contain a given block ID
    Q_INVOKABLE QStringList filesContainingBlock(const QString &blockId) const;

    // Get per-file sync status for a block
    // Returns list of {filePath, status, fileContent} where status is "synced" or "diverged"
    Q_INVOKABLE QVariantList blockSyncStatus(const QString &blockId) const;

    // Get all .md file paths from the project tree
    QStringList allMdFiles() const;

signals:
    void blockPushed(const QString &blockId, int fileCount);
    void blockPulled(const QString &blockId, const QString &filePath);

private:
    QString extractBlockContent(const QString &fileContent, const QString &blockId) const;
    bool replaceBlockInFile(const QString &filePath, const QString &blockId,
                            const QString &newContent) const;
    void collectAllMdFiles(TreeNode *node, QStringList &files) const;

    BlockStore *m_blockStore;
    ProjectTreeModel *m_treeModel;
};
