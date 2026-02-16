#include "jsonlstore.h"

#include <QFile>
#include <QTextStream>
#include <QJsonDocument>
#include <QJsonArray>
#include <QGuiApplication>
#include <QClipboard>
#include <QFileInfo>

// ── JsonlWorker ──────────────────────────────────────────────

JsonlWorker::JsonlWorker(const QString &filePath, QObject *parent)
    : QObject(parent), m_filePath(filePath)
{
}

void JsonlWorker::process()
{
    QFile file(m_filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        emit error(QStringLiteral("Could not open file: ") + m_filePath);
        emit finished();
        return;
    }

    // Count lines for progress (fast scan)
    qint64 fileSize = file.size();
    int estimatedLines = qMax(1, static_cast<int>(fileSize / 200)); // rough estimate

    QTextStream in(&file);
    QVector<JsonlEntry> chunk;
    int lineNum = 0;
    constexpr int kChunkSize = 100;

    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();
        lineNum++;

        if (line.isEmpty())
            continue;

        JsonlEntry entry;
        entry.lineNumber = lineNum;

        QJsonParseError parseErr;
        QJsonDocument doc = QJsonDocument::fromJson(line.toUtf8(), &parseErr);

        if (parseErr.error != QJsonParseError::NoError || !doc.isObject()) {
            // Store invalid lines with an error preview
            entry.preview = QStringLiteral("[Parse error: ") + parseErr.errorString() + QStringLiteral("] ") + line.left(80);
            entry.role = QStringLiteral("error");
        } else {
            entry.data = doc.object();

            // Claude Code JSONL: data is nested inside "message" object
            QJsonObject msg = entry.data.value(QStringLiteral("message")).toObject();
            QString topType = entry.data.value(QStringLiteral("type")).toString();

            // Extract content value (from message.content or top-level content)
            QJsonValue contentVal = msg.isEmpty()
                ? entry.data.value(QStringLiteral("content"))
                : msg.value(QStringLiteral("content"));

            // Detect content block types for role/tool classification
            bool hasToolResult = false;
            bool hasToolUseBlock = false;
            if (contentVal.isArray()) {
                for (const QJsonValue &v : contentVal.toArray()) {
                    if (!v.isObject()) continue;
                    QString blockType = v.toObject().value(QStringLiteral("type")).toString();
                    if (blockType == QStringLiteral("tool_result"))
                        hasToolResult = true;
                    if (blockType == QStringLiteral("tool_use")
                        || blockType == QStringLiteral("server_tool_use"))
                        hasToolUseBlock = true;
                }
            }

            // Determine role
            if (topType == QStringLiteral("progress")) {
                entry.role = QStringLiteral("progress");
            } else if (hasToolResult) {
                entry.role = QStringLiteral("tool");
            } else if (!msg.isEmpty()) {
                entry.role = msg.value(QStringLiteral("role")).toString();
            } else if (entry.data.contains(QStringLiteral("role"))) {
                entry.role = entry.data.value(QStringLiteral("role")).toString();
            } else {
                entry.role = topType;
            }

            // Detect tool use
            entry.hasToolUse = hasToolUseBlock || hasToolResult
                            || entry.data.contains(QStringLiteral("tool_use"))
                            || entry.data.contains(QStringLiteral("tool_calls"));

            // Build preview from content — handles all Claude API block types
            if (contentVal.isString()) {
                entry.preview = contentVal.toString().left(300).simplified();
            } else if (contentVal.isArray()) {
                QStringList parts;
                for (const QJsonValue &v : contentVal.toArray()) {
                    if (!v.isObject()) continue;
                    QJsonObject block = v.toObject();
                    QString blockType = block.value(QStringLiteral("type")).toString();

                    if (blockType == QStringLiteral("text")) {
                        QString text = block.value(QStringLiteral("text")).toString();
                        if (!text.isEmpty())
                            parts.append(text.left(200));

                    } else if (blockType == QStringLiteral("tool_use")) {
                        QString name = block.value(QStringLiteral("name")).toString();
                        QJsonObject input = block.value(QStringLiteral("input")).toObject();
                        QString argPreview;
                        for (auto it = input.begin(); it != input.end(); ++it) {
                            if (it.value().isString()) {
                                argPreview = it.value().toString().left(100).simplified();
                                break;
                            }
                        }
                        parts.append(QStringLiteral("\xF0\x9F\x94\xA7 ") + name
                                     + (argPreview.isEmpty() ? QString() : QStringLiteral(" ") + argPreview));

                    } else if (blockType == QStringLiteral("tool_result")) {
                        bool isError = block.value(QStringLiteral("is_error")).toBool(false);
                        QJsonValue resultContent = block.value(QStringLiteral("content"));
                        QString preview;
                        if (resultContent.isString()) {
                            preview = resultContent.toString().left(200).simplified();
                        } else if (resultContent.isArray()) {
                            // tool_result content can be array of content blocks
                            for (const QJsonValue &rc : resultContent.toArray()) {
                                if (rc.isObject() && rc.toObject().value(QStringLiteral("type")).toString() == QStringLiteral("text")) {
                                    preview = rc.toObject().value(QStringLiteral("text")).toString().left(200).simplified();
                                    break;
                                }
                            }
                        }
                        if (!preview.isEmpty())
                            parts.append((isError ? QStringLiteral("\xE2\x9D\x8C ") : QStringLiteral("\xE2\x86\x90 ")) + preview);

                    } else if (blockType == QStringLiteral("thinking")) {
                        QString thinking = block.value(QStringLiteral("thinking")).toString();
                        if (!thinking.isEmpty())
                            parts.append(QStringLiteral("\xF0\x9F\x92\xAD ") + thinking.left(150).simplified());

                    } else if (blockType == QStringLiteral("redacted_thinking")) {
                        parts.append(QStringLiteral("\xF0\x9F\x94\x92 [redacted thinking]"));

                    } else if (blockType == QStringLiteral("image")) {
                        QString mediaType = block.value(QStringLiteral("source")).toObject()
                                            .value(QStringLiteral("media_type")).toString();
                        parts.append(QStringLiteral("\xF0\x9F\x96\xBC image") +
                                     (mediaType.isEmpty() ? QString() : QStringLiteral(" (") + mediaType + QStringLiteral(")")));

                    } else if (blockType == QStringLiteral("document")) {
                        QString title = block.value(QStringLiteral("title")).toString();
                        parts.append(QStringLiteral("\xF0\x9F\x93\x84 ") +
                                     (title.isEmpty() ? QStringLiteral("document") : title));

                    } else if (blockType == QStringLiteral("server_tool_use")) {
                        QString name = block.value(QStringLiteral("name")).toString();
                        parts.append(QStringLiteral("\xE2\x9A\x99 server:") + name);

                    } else if (blockType == QStringLiteral("web_search_tool_result")) {
                        QString query = block.value(QStringLiteral("search_query")).toString();
                        parts.append(QStringLiteral("\xF0\x9F\x94\x8D ") +
                                     (query.isEmpty() ? QStringLiteral("web search") : query.left(100)));
                    }
                }
                entry.preview = parts.join(QStringLiteral(" | ")).left(400).simplified();
            }

            // Progress entries: show hook/data info
            if (topType == QStringLiteral("progress") && entry.preview.isEmpty()) {
                QJsonObject data = entry.data.value(QStringLiteral("data")).toObject();
                QString progType = data.value(QStringLiteral("type")).toString();
                QString hookName = data.value(QStringLiteral("hookName")).toString();
                if (!hookName.isEmpty())
                    entry.preview = progType + QStringLiteral(": ") + hookName;
                else if (!progType.isEmpty())
                    entry.preview = progType;
            }

            if (entry.preview.isEmpty()) {
                // Fall back to first string value
                for (auto it = entry.data.begin(); it != entry.data.end(); ++it) {
                    if (it.value().isString() && it.key() != QStringLiteral("role")
                        && it.key() != QStringLiteral("type")
                        && it.key() != QStringLiteral("uuid")
                        && it.key() != QStringLiteral("parentUuid")
                        && it.key() != QStringLiteral("sessionId")) {
                        entry.preview = it.value().toString().left(200).simplified();
                        break;
                    }
                }
            }

            if (entry.preview.isEmpty())
                entry.preview = line.left(120);
        }

        chunk.append(entry);

        if (chunk.size() >= kChunkSize) {
            emit chunkReady(chunk);
            emit progressChanged(lineNum, estimatedLines);
            chunk.clear();
        }
    }

    // Emit remaining
    if (!chunk.isEmpty()) {
        emit chunkReady(chunk);
    }

    file.close();
    emit finished();
}

// ── JsonlStore ───────────────────────────────────────────────

JsonlStore::JsonlStore(QObject *parent)
    : QAbstractListModel(parent)
{
    qRegisterMetaType<QVector<JsonlEntry>>("QVector<JsonlEntry>");
}

JsonlStore::~JsonlStore()
{
    stopWorker();
}

int JsonlStore::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return m_filteredIndices.size();
}

QVariant JsonlStore::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_filteredIndices.size())
        return {};

    const JsonlEntry &entry = m_entries[m_filteredIndices[index.row()]];

    switch (role) {
    case LineNumberRole: return entry.lineNumber;
    case PreviewRole:    return entry.preview;
    case RoleNameRole:   return entry.role;
    case HasToolUseRole: return entry.hasToolUse;
    case FullJsonRole:   return QString::fromUtf8(
        QJsonDocument(entry.data).toJson(QJsonDocument::Indented));
    case IsExpandedRole: return m_expandedRows.contains(index.row());
    }
    return {};
}

QHash<int, QByteArray> JsonlStore::roleNames() const
{
    return {
        { LineNumberRole, "lineNumber" },
        { PreviewRole,    "preview" },
        { RoleNameRole,   "roleName" },
        { HasToolUseRole, "hasToolUse" },
        { FullJsonRole,   "fullJson" },
        { IsExpandedRole, "isExpanded" }
    };
}

QString JsonlStore::filePath() const { return m_filePath; }
int JsonlStore::totalCount() const { return m_entries.size(); }
int JsonlStore::filteredCount() const { return m_filteredIndices.size(); }
QStringList JsonlStore::availableRoles() const { return m_availableRoles; }
bool JsonlStore::loading() const { return m_loading; }
int JsonlStore::loadProgress() const { return m_loadProgress; }

QString JsonlStore::textFilter() const { return m_textFilter; }
void JsonlStore::setTextFilter(const QString &text)
{
    if (m_textFilter == text) return;
    m_textFilter = text;
    emit textFilterChanged();
    rebuildFiltered();
}

QString JsonlStore::roleFilter() const { return m_roleFilter; }
void JsonlStore::setRoleFilter(const QString &role)
{
    if (m_roleFilter == role) return;
    m_roleFilter = role;
    emit roleFilterChanged();
    rebuildFiltered();
}

bool JsonlStore::toolUseOnly() const { return m_toolUseOnly; }
void JsonlStore::setToolUseOnly(bool only)
{
    if (m_toolUseOnly == only) return;
    m_toolUseOnly = only;
    emit toolUseOnlyChanged();
    rebuildFiltered();
}

void JsonlStore::load(const QString &filePath)
{
    stopWorker();
    clear();

    m_filePath = filePath;
    emit filePathChanged();

    m_loading = true;
    emit loadingChanged();

    auto *worker = new JsonlWorker(filePath);
    m_workerThread = new QThread();
    worker->moveToThread(m_workerThread);

    connect(m_workerThread, &QThread::started, worker, &JsonlWorker::process);
    connect(worker, &JsonlWorker::chunkReady, this, &JsonlStore::appendChunk);
    connect(worker, &JsonlWorker::progressChanged, this, [this](int current, int) {
        m_loadProgress = current;
        emit loadProgressChanged();
    });
    connect(worker, &JsonlWorker::error, this, &JsonlStore::onLoadError);
    connect(worker, &JsonlWorker::finished, this, &JsonlStore::onLoadFinished);
    connect(worker, &JsonlWorker::finished, m_workerThread, &QThread::quit);
    connect(m_workerThread, &QThread::finished, worker, &QObject::deleteLater);
    connect(m_workerThread, &QThread::finished, m_workerThread, &QObject::deleteLater);

    m_workerThread->start();
}

void JsonlStore::clear()
{
    beginResetModel();
    m_entries.clear();
    m_filteredIndices.clear();
    m_expandedRows.clear();
    m_availableRoles.clear();
    m_filePath.clear();
    m_loadProgress = 0;
    endResetModel();

    emit filePathChanged();
    emit totalCountChanged();
    emit filteredCountChanged();
    emit availableRolesChanged();
    emit loadProgressChanged();
}

void JsonlStore::toggleExpanded(int index)
{
    if (index < 0 || index >= m_filteredIndices.size()) return;

    if (m_expandedRows.contains(index))
        m_expandedRows.remove(index);
    else
        m_expandedRows.insert(index);

    QModelIndex mi = createIndex(index, 0);
    emit dataChanged(mi, mi, { IsExpandedRole });
}

QString JsonlStore::entryJson(int index) const
{
    if (index < 0 || index >= m_filteredIndices.size()) return {};
    const JsonlEntry &entry = m_entries[m_filteredIndices[index]];
    return QString::fromUtf8(QJsonDocument(entry.data).toJson(QJsonDocument::Indented));
}

void JsonlStore::copyEntry(int index)
{
    QString json = entryJson(index);
    if (json.isEmpty()) return;
    QGuiApplication::clipboard()->setText(json);

    // Get a short preview for the toast
    if (index >= 0 && index < m_filteredIndices.size()) {
        const JsonlEntry &entry = m_entries[m_filteredIndices[index]];
        emit copied(entry.role.isEmpty()
                    ? QStringLiteral("Line ") + QString::number(entry.lineNumber)
                    : entry.role + QStringLiteral(" (line ") + QString::number(entry.lineNumber) + QStringLiteral(")"));
    }
}

void JsonlStore::appendChunk(const QVector<JsonlEntry> &entries)
{
    QSet<QString> rolesBefore(m_availableRoles.begin(), m_availableRoles.end());
    int oldSize = m_entries.size();
    m_entries.append(entries);

    // Track new roles
    for (const auto &e : entries) {
        if (!e.role.isEmpty() && e.role != QStringLiteral("error"))
            rolesBefore.insert(e.role);
    }

    QStringList sortedRoles = rolesBefore.values();
    sortedRoles.sort();
    if (sortedRoles != m_availableRoles) {
        m_availableRoles = sortedRoles;
        emit availableRolesChanged();
    }

    // Add to filtered if they match
    int addedCount = 0;
    for (int i = oldSize; i < m_entries.size(); ++i) {
        const auto &e = m_entries[i];
        if (!m_roleFilter.isEmpty() && e.role != m_roleFilter) continue;
        if (m_toolUseOnly && !e.hasToolUse) continue;
        if (!m_textFilter.isEmpty() && !e.preview.contains(m_textFilter, Qt::CaseInsensitive)) continue;

        beginInsertRows({}, m_filteredIndices.size(), m_filteredIndices.size());
        m_filteredIndices.append(i);
        endInsertRows();
        addedCount++;
    }

    emit totalCountChanged();
    if (addedCount > 0)
        emit filteredCountChanged();
}

void JsonlStore::onLoadFinished()
{
    m_loading = false;
    m_workerThread = nullptr; // already scheduled for deleteLater
    emit loadingChanged();
}

void JsonlStore::onLoadError(const QString &message)
{
    emit loadFailed(message);
}

void JsonlStore::rebuildFiltered()
{
    beginResetModel();
    m_filteredIndices.clear();
    m_expandedRows.clear();

    for (int i = 0; i < m_entries.size(); ++i) {
        const auto &e = m_entries[i];
        if (!m_roleFilter.isEmpty() && e.role != m_roleFilter) continue;
        if (m_toolUseOnly && !e.hasToolUse) continue;
        if (!m_textFilter.isEmpty() && !e.preview.contains(m_textFilter, Qt::CaseInsensitive)) continue;
        m_filteredIndices.append(i);
    }

    endResetModel();
    emit filteredCountChanged();
}

void JsonlStore::stopWorker()
{
    if (m_workerThread && m_workerThread->isRunning()) {
        m_workerThread->quit();
        m_workerThread->wait(2000);
    }
}
