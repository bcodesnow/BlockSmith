#include "searchmanager.h"

#include "projecttreemodel.h"
#include "configmanager.h"

#include <QFile>
#include <QTextStream>
#include <QPointer>
#include <QtConcurrent>
#include <functional>

SearchManager::SearchManager(ProjectTreeModel *tree, ConfigManager *config,
                             QObject *parent)
    : QObject(parent)
    , m_projectTreeModel(tree)
    , m_configManager(config)
{
}

QStringList SearchManager::getAllFiles() const
{
    QStringList files;
    std::function<void(TreeNode*)> collect = [&](TreeNode *node) {
        if (!node) return;
        if (node->nodeType() == TreeNode::FileNode) {
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

QVariantList SearchManager::fuzzyFilterFiles(const QString &query) const
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

void SearchManager::searchFiles(const QString &query)
{
    // Cancel any previous search
    if (m_searchCancel)
        m_searchCancel->store(true);

    if (query.length() < 2) {
        emit searchResultsReady({});
        return;
    }

    // Gather file list on main thread (fast — just tree walk)
    auto includeInSearch = [this](const QString &path) {
        if (path.endsWith(QStringLiteral(".jsonl"), Qt::CaseInsensitive))
            return m_configManager->searchIncludeJsonl();
        if (path.endsWith(QStringLiteral(".json"), Qt::CaseInsensitive))
            return m_configManager->searchIncludeJson();
        if (path.endsWith(QStringLiteral(".yaml"), Qt::CaseInsensitive)
            || path.endsWith(QStringLiteral(".yml"), Qt::CaseInsensitive))
            return m_configManager->searchIncludeYaml();
        if (path.endsWith(QStringLiteral(".md"), Qt::CaseInsensitive)
            || path.endsWith(QStringLiteral(".markdown"), Qt::CaseInsensitive))
            return m_configManager->searchIncludeMarkdown();
        if (path.endsWith(QStringLiteral(".txt"), Qt::CaseInsensitive))
            return m_configManager->searchIncludePlaintext();
        return false;
    };

    QStringList files;
    const QStringList allFiles = getAllFiles();
    for (const QString &path : allFiles) {
        if (includeInSearch(path))
            files.append(path);
    }

    if (files.isEmpty()) {
        emit searchResultsReady({});
        return;
    }

    // Shared cancel flag for this search run
    auto cancel = std::make_shared<std::atomic<bool>>(false);
    m_searchCancel = cancel;

    // Run file I/O + search on a worker thread
    QPointer<SearchManager> self(this);
    (void)QtConcurrent::run([self, query, files, cancel]() {
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
            }
        }

        if (cancel->load() || !self) return;

        QMetaObject::invokeMethod(self.data(), "searchResultsReady",
                                  Qt::QueuedConnection,
                                  Q_ARG(QVariantList, results));
    });
}
