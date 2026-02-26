#include "syncengine.h"
#include "blockstore.h"
#include "projecttreemodel.h"
#include "utils.h"

#include <QFile>
#include <QSaveFile>
#include <QTextStream>
#include <QRegularExpression>
#include <QtConcurrent>
#include <QPointer>

// Read file with BOM-aware encoding, stripping the BOM character
static QString readFileContent(const QString &filePath)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly))
        return {};

    bool hasBom = false;
    auto encoding = Utils::detectBomEncoding(file, hasBom);

    QTextStream in(&file);
    in.setEncoding(encoding);
    QString content = in.readAll();

    // Strip BOM character (U+FEFF) if present
    if (!content.isEmpty() && content.at(0) == QChar(0xFEFF))
        content.remove(0, 1);

    return content;
}

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

    static const QRegularExpression blockRx(
        QStringLiteral("<!-- block:\\s*.+?\\s*\\[id:([a-f0-9]+)\\]\\s*-->\\r?\\n"
                       "([\\s\\S]*?)\\r?\\n"
                       "<!-- \\/block:\\1 -->"));

    QStringList allFiles;
    collectAllMdFiles(m_treeModel->rootNode(), allFiles);

    for (const QString &filePath : allFiles) {
        const QString content = readFileContent(filePath);
        if (content.isNull()) continue;

        auto it = blockRx.globalMatch(content);
        while (it.hasNext()) {
            auto match = it.next();
            const QString blockId = match.captured(1);
            // Normalize to LF at ingestion — registry uses LF, files may use CRLF
            QString blockContent = match.captured(2);
            blockContent.remove(QLatin1Char('\r'));
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
    const QString content = readFileContent(filePath);
    if (content.isNull()) return;

    QString fileContent = extractBlockContent(content, blockId);
    if (fileContent.isNull())
        return;

    // Normalize to LF before storing in registry
    fileContent.remove(QLatin1Char('\r'));
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

// --- Myers diff algorithm (operates on lines) ---

// Compute LCS-based edit script between two line arrays.
// Returns a flat list of diff entries for the QML side.
static QVariantList myersDiff(const QStringList &a, const QStringList &b)
{
    const int n = a.size();
    const int m = b.size();
    const int max = n + m;

    if (max == 0)
        return {};

    // V array indexed by k ∈ [-max, max], offset by max
    QVector<int> v(2 * max + 1, 0);

    // Trace: for each d, store the V snapshot to reconstruct the path
    QVector<QVector<int>> trace;

    bool found = false;
    for (int d = 0; d <= max && !found; d++) {
        trace.append(v);
        for (int k = -d; k <= d; k += 2) {
            int x;
            if (k == -d || (k != d && v[k - 1 + max] < v[k + 1 + max]))
                x = v[k + 1 + max];        // move down (insert)
            else
                x = v[k - 1 + max] + 1;    // move right (delete)

            int y = x - k;

            // Follow diagonal (equal lines)
            while (x < n && y < m && a[x] == b[y]) {
                x++;
                y++;
            }

            v[k + max] = x;

            if (x >= n && y >= m) {
                found = true;
                break;
            }
        }
    }

    // Backtrack to build the edit sequence
    struct Edit { char type; int idxA; int idxB; };  // 'E'qual, 'D'elete, 'I'nsert
    QVector<Edit> editsRev;

    int x = n, y = m;
    for (int d = trace.size() - 1; d >= 0 && (x > 0 || y > 0); d--) {
        const auto &vd = trace[d];
        int k = x - y;

        int prevK;
        if (k == -d || (k != d && vd[k - 1 + max] < vd[k + 1 + max]))
            prevK = k + 1;  // came from insert
        else
            prevK = k - 1;  // came from delete

        int prevX = vd[prevK + max];
        int prevY = prevX - prevK;

        // Diagonal moves (equal lines)
        while (x > prevX && y > prevY) {
            x--; y--;
            editsRev.append({'E', x, y});
        }

        if (d > 0) {
            if (x == prevX) {
                // Insert
                y--;
                editsRev.append({'I', -1, y});
            } else {
                // Delete
                x--;
                editsRev.append({'D', x, -1});
            }
        }
    }

    // Convert edit script to QVariantList for QML
    QVariantList result;
    result.reserve(editsRev.size());
    int lineA = 1, lineB = 1;

    for (int i = editsRev.size() - 1; i >= 0; i--) {
        const auto &e = editsRev[i];
        QVariantMap entry;
        switch (e.type) {
        case 'E':
            entry[QStringLiteral("type")] = QStringLiteral("context");
            entry[QStringLiteral("text")] = a[e.idxA];
            entry[QStringLiteral("lineA")] = lineA++;
            entry[QStringLiteral("lineB")] = lineB++;
            break;
        case 'D':
            entry[QStringLiteral("type")] = QStringLiteral("removed");
            entry[QStringLiteral("text")] = a[e.idxA];
            entry[QStringLiteral("lineA")] = lineA++;
            entry[QStringLiteral("lineB")] = -1;
            break;
        case 'I':
            entry[QStringLiteral("type")] = QStringLiteral("added");
            entry[QStringLiteral("text")] = b[e.idxB];
            entry[QStringLiteral("lineA")] = -1;
            entry[QStringLiteral("lineB")] = lineB++;
            break;
        }
        result.append(entry);
    }

    return result;
}

QVariantList SyncEngine::computeLineDiff(const QString &textA, const QString &textB) const
{
    // Normalize to LF before splitting into lines
    QString a = textA, b = textB;
    a.remove(QLatin1Char('\r'));
    b.remove(QLatin1Char('\r'));
    return myersDiff(a.split(QLatin1Char('\n')), b.split(QLatin1Char('\n')));
}

void SyncEngine::computeLineDiffAsync(const QString &requestId,
                                      const QString &textA,
                                      const QString &textB)
{
    QPointer<SyncEngine> self(this);
    (void)QtConcurrent::run([self, requestId, textA, textB]() {
        if (!self)
            return;

        const QVariantList diff = self->computeLineDiff(textA, textB);
        if (!self)
            return;

        QMetaObject::invokeMethod(self, [self, requestId, diff]() {
            if (!self)
                return;
            emit self->lineDiffReady(requestId, diff);
        }, Qt::QueuedConnection);
    });
}

QString SyncEngine::extractBlockContent(const QString &fileContent, const QString &blockId) const
{
    QString pattern = QString(
        "<!-- block:\\s*.+?\\s*\\[id:%1\\]\\s*-->\\r?\\n([\\s\\S]*?)\\r?\\n<!-- \\/block:%1 -->")
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
    // Read with encoding detection
    QFile readFile(filePath);
    if (!readFile.open(QIODevice::ReadOnly))
        return false;

    bool hasBom = false;
    auto encoding = Utils::detectBomEncoding(readFile, hasBom);

    QTextStream in(&readFile);
    in.setEncoding(encoding);
    QString content = in.readAll();
    readFile.close();

    // Strip BOM character
    if (!content.isEmpty() && content.at(0) == QChar(0xFEFF))
        content.remove(0, 1);

    QString pattern = QString(
        "(<!-- block:\\s*.+?\\s*\\[id:%1\\]\\s*-->\\r?\\n)[\\s\\S]*?(\\r?\\n<!-- \\/block:%1 -->)")
        .arg(QRegularExpression::escape(blockId));

    QRegularExpression rx(pattern);
    auto match = rx.match(content);
    if (!match.hasMatch())
        return false;

    // Adapt newContent line endings to match the file (CRLF vs LF).
    // captured(1) ends with \r?\n, captured(2) starts with \r?\n — no extra separator needed.
    QString adapted = newContent;
    adapted.remove(QLatin1Char('\r'));        // normalize to LF first
    if (content.contains(QStringLiteral("\r\n")))
        adapted.replace(QLatin1Char('\n'), QStringLiteral("\r\n"));
    QString replacement = match.captured(1) + adapted + match.captured(2);
    content.replace(match.capturedStart(), match.capturedLength(), replacement);

    // Write back with original encoding preserved
    QSaveFile writeFile(filePath);
    if (!writeFile.open(QIODevice::WriteOnly))
        return false;

    QTextStream out(&writeFile);
    out.setEncoding(encoding);
    out.setGenerateByteOrderMark(hasBom);
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
        const QString path = node->path();
        // Tree nodes may include .json/.jsonl entries (e.g. ~/.claude integration).
        // Block indexing and markdown search should only touch real markdown files.
        if (path.endsWith(QStringLiteral(".md"), Qt::CaseInsensitive)
            || path.endsWith(QStringLiteral(".markdown"), Qt::CaseInsensitive))
            files.append(path);
        return;
    }

    for (int i = 0; i < node->childCount(); i++)
        collectAllMdFiles(node->child(i), files);
}
