#include "syncengine.h"
#include "blockstore.h"
#include "projecttreemodel.h"

#include <QFile>
#include <QSaveFile>
#include <QTextStream>
#include <QRegularExpression>

SyncEngine::SyncEngine(BlockStore *blockStore, ProjectTreeModel *treeModel,
                       QObject *parent)
    : QObject(parent)
    , m_blockStore(blockStore)
    , m_treeModel(treeModel)
{
}

void SyncEngine::rebuildIndex()
{
    m_index.clear();

    QStringList allFiles;
    collectAllMdFiles(m_treeModel->rootNode(), allFiles);

    // Single regex to find ALL block markers in a file
    static const QRegularExpression blockRx(
        QStringLiteral("<!-- block:\\s*.+?\\s*\\[id:([a-f0-9]+)\\]\\s*-->\\n"
                       "([\\s\\S]*?)\\n"
                       "<!-- \\/block:\\1 -->"));

    for (const QString &filePath : allFiles) {
        QFile file(filePath);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
            continue;

        const QString content = QTextStream(&file).readAll();
        file.close();

        // Find all block occurrences in this file
        auto it = blockRx.globalMatch(content);
        while (it.hasNext()) {
            auto match = it.next();
            const QString blockId = match.captured(1);
            const QString blockContent = match.captured(2);
            m_index[blockId].append({filePath, blockContent});
        }
    }

    emit indexReady();
}

int SyncEngine::pushBlock(const QString &blockId)
{
    auto block = m_blockStore->blockById(blockId);
    if (!block) return 0;

    const QStringList files = filesContainingBlock(blockId);
    int updated = 0;

    for (const QString &filePath : files) {
        if (replaceBlockInFile(filePath, blockId, block->content))
            updated++;
    }

    if (updated > 0) {
        rebuildIndex();
        emit blockPushed(blockId, updated);
    }

    return updated;
}

void SyncEngine::pullBlock(const QString &blockId, const QString &filePath)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return;

    const QString content = QTextStream(&file).readAll();
    file.close();

    const QString fileContent = extractBlockContent(content, blockId);
    if (fileContent.isNull())
        return;

    m_blockStore->updateBlock(blockId, fileContent);
    rebuildIndex();
    emit blockPulled(blockId, filePath);
}

QStringList SyncEngine::filesContainingBlock(const QString &blockId) const
{
    QStringList result;
    auto it = m_index.constFind(blockId);
    if (it != m_index.constEnd()) {
        for (const auto &occ : it.value())
            result.append(occ.filePath);
    }
    return result;
}

QVariantList SyncEngine::blockSyncStatus(const QString &blockId) const
{
    auto block = m_blockStore->blockById(blockId);
    if (!block) return {};

    QVariantList result;
    auto it = m_index.constFind(blockId);
    if (it == m_index.constEnd())
        return result;

    for (const auto &occ : it.value()) {
        QVariantMap entry;
        entry[QStringLiteral("filePath")] = occ.filePath;
        bool synced = (occ.fileContent == block->content);
        entry[QStringLiteral("status")] = synced
            ? QStringLiteral("synced") : QStringLiteral("diverged");
        if (!synced)
            entry[QStringLiteral("fileContent")] = occ.fileContent;
        result.append(entry);
    }

    return result;
}

bool SyncEngine::isBlockDiverged(const QString &blockId) const
{
    auto block = m_blockStore->blockById(blockId);
    if (!block) return false;

    auto it = m_index.constFind(blockId);
    if (it == m_index.constEnd())
        return false;

    for (const auto &occ : it.value()) {
        if (occ.fileContent != block->content)
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
                                     const QString &newContent)
{
    QFile readFile(filePath);
    if (!readFile.open(QIODevice::ReadOnly | QIODevice::Text))
        return false;

    QString content = QTextStream(&readFile).readAll();
    readFile.close();

    QString pattern = QString(
        "(<!-- block:\\s*.+?\\s*\\[id:%1\\]\\s*-->\\n)[\\s\\S]*?(<!-- \\/block:%1 -->)")
        .arg(QRegularExpression::escape(blockId));

    QRegularExpression rx(pattern);
    auto match = rx.match(content);
    if (!match.hasMatch())
        return false;

    QString replacement = match.captured(1) + newContent + "\n" + match.captured(2);
    content.replace(match.capturedStart(), match.capturedLength(), replacement);

    QSaveFile writeFile(filePath);
    if (!writeFile.open(QIODevice::WriteOnly | QIODevice::Text))
        return false;

    QTextStream out(&writeFile);
    out << content;
    out.flush();
    return writeFile.commit();
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
