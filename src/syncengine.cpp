#include "syncengine.h"
#include "blockstore.h"
#include "projecttreemodel.h"

#include <QFile>
#include <QTextStream>
#include <QRegularExpression>

SyncEngine::SyncEngine(BlockStore *blockStore, ProjectTreeModel *treeModel,
                       QObject *parent)
    : QObject(parent)
    , m_blockStore(blockStore)
    , m_treeModel(treeModel)
{
}

int SyncEngine::pushBlock(const QString &blockId)
{
    const BlockData *block = m_blockStore->blockById(blockId);
    if (!block) return 0;

    QStringList files = filesContainingBlock(blockId);
    int updated = 0;

    for (const QString &filePath : files) {
        if (replaceBlockInFile(filePath, blockId, block->content))
            updated++;
    }

    if (updated > 0)
        emit blockPushed(blockId, updated);

    return updated;
}

QStringList SyncEngine::filesContainingBlock(const QString &blockId) const
{
    QStringList allFiles;
    collectAllMdFiles(m_treeModel->rootNode(), allFiles);

    // Pattern to find this block ID in files
    QString pattern = QString("<!-- block:\\s*.+?\\s*\\[id:%1\\]\\s*-->").arg(blockId);
    QRegularExpression rx(pattern);

    QStringList result;
    for (const QString &filePath : allFiles) {
        QFile file(filePath);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
            continue;

        QString content = QTextStream(&file).readAll();
        file.close();

        if (rx.match(content).hasMatch())
            result.append(filePath);
    }

    return result;
}

void SyncEngine::pullBlock(const QString &blockId, const QString &filePath)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return;

    QString content = QTextStream(&file).readAll();
    file.close();

    QString fileContent = extractBlockContent(content, blockId);
    if (fileContent.isNull())
        return;

    m_blockStore->updateBlock(blockId, fileContent);
    emit blockPulled(blockId, filePath);
}

QVariantList SyncEngine::blockSyncStatus(const QString &blockId) const
{
    const BlockData *block = m_blockStore->blockById(blockId);
    if (!block) return {};

    QStringList files = filesContainingBlock(blockId);
    QVariantList result;

    for (const QString &filePath : files) {
        QFile file(filePath);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
            continue;

        QString content = QTextStream(&file).readAll();
        file.close();

        QString fileContent = extractBlockContent(content, blockId);

        QVariantMap entry;
        entry["filePath"] = filePath;
        bool synced = (fileContent == block->content);
        entry["status"] = synced ? "synced" : "diverged";
        if (!synced)
            entry["fileContent"] = fileContent;
        result.append(entry);
    }

    return result;
}

bool SyncEngine::isBlockDiverged(const QString &blockId) const
{
    const auto status = blockSyncStatus(blockId);
    for (const auto &entry : status) {
        if (entry.toMap().value("status").toString() == "diverged")
            return true;
    }
    return false;
}

QString SyncEngine::extractBlockContent(const QString &fileContent, const QString &blockId) const
{
    QString pattern = QString(
        "<!-- block:\\s*.+?\\s*\\[id:%1\\]\\s*-->\\n([\\s\\S]*?)\\n<!-- \\/block:%1 -->")
        .arg(QRegularExpression::escape(blockId));

    QRegularExpression rx(pattern);
    auto match = rx.match(fileContent);
    if (!match.hasMatch())
        return {};

    return match.captured(1);
}

bool SyncEngine::replaceBlockInFile(const QString &filePath, const QString &blockId,
                                     const QString &newContent) const
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return false;

    QString content = QTextStream(&file).readAll();
    file.close();

    // Match the full block: opening tag, content, closing tag
    QString pattern = QString(
        "(<!-- block:\\s*.+?\\s*\\[id:%1\\]\\s*-->\\n)[\\s\\S]*?(<!-- \\/block:%1 -->)")
        .arg(QRegularExpression::escape(blockId));

    QRegularExpression rx(pattern);
    auto match = rx.match(content);
    if (!match.hasMatch())
        return false;

    // Replace content between markers
    QString replacement = match.captured(1) + newContent + "\n" + match.captured(2);
    content.replace(match.capturedStart(), match.capturedLength(), replacement);

    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        return false;

    QTextStream out(&file);
    out << content;
    return true;
}

QStringList SyncEngine::allMdFiles() const
{
    QStringList files;
    collectAllMdFiles(m_treeModel->rootNode(), files);
    return files;
}

void SyncEngine::collectAllMdFiles(TreeNode *node, QStringList &files) const
{
    if (!node) return;

    if (node->nodeType() == TreeNode::MdFile) {
        files.append(node->path());
        return;
    }

    for (int i = 0; i < node->childCount(); i++)
        collectAllMdFiles(node->child(i), files);
}
