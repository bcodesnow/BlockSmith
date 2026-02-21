#include "blockstore.h"

#include <QFile>
#include <QSaveFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDir>
#include <QRandomGenerator>

BlockStore::BlockStore(const QString &dbPath, QObject *parent)
    : QAbstractListModel(parent)
    , m_dbPath(dbPath)
{
    load();
}

int BlockStore::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_filteredIds.size();
}

QVariant BlockStore::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_filteredIds.size())
        return {};

    auto it = m_blocks.constFind(m_filteredIds[index.row()]);
    if (it == m_blocks.constEnd()) return {};
    const auto &block = *it;

    switch (role) {
    case Qt::DisplayRole:
    case NameRole:      return block.name;
    case IdRole:        return block.id;
    case ContentRole:   return block.content;
    case TagsRole:      return block.tags;
    case SourceFileRole: return block.sourceFile;
    case CreatedAtRole: return block.createdAt.toString(Qt::ISODate);
    case UpdatedAtRole: return block.updatedAt.toString(Qt::ISODate);
    default: return {};
    }
}

QHash<int, QByteArray> BlockStore::roleNames() const
{
    return {
        {IdRole, "blockId"},
        {NameRole, "name"},
        {ContentRole, "content"},
        {TagsRole, "tags"},
        {SourceFileRole, "sourceFile"},
        {CreatedAtRole, "createdAt"},
        {UpdatedAtRole, "updatedAt"},
        {Qt::DisplayRole, "display"}
    };
}

int BlockStore::count() const { return m_blocks.size(); }

QString BlockStore::createBlock(const QString &name, const QString &content,
                                 const QStringList &tags, const QString &sourceFile)
{
    QString id = generateId();
    BlockData block;
    block.id = id;
    block.name = name;
    block.content = content;
    block.tags = tags;
    block.sourceFile = sourceFile;
    block.createdAt = QDateTime::currentDateTimeUtc();
    block.updatedAt = block.createdAt;

    m_blocks.insert(id, block);
    rebuildFiltered();
    save();
    emit countChanged();
    emit allTagsChanged();
    return id;
}

void BlockStore::updateBlock(const QString &id, const QString &content)
{
    auto it = m_blocks.find(id);
    if (it == m_blocks.end()) return;

    it->content = content;
    it->updatedAt = QDateTime::currentDateTimeUtc();

    // Notify the view
    int row = m_filteredIds.indexOf(id);
    if (row >= 0) {
        QModelIndex idx = index(row);
        emit dataChanged(idx, idx, {ContentRole, UpdatedAtRole});
    }

    save();
    emit blockUpdated(id);
}

void BlockStore::renameBlock(const QString &id, const QString &newName)
{
    auto it = m_blocks.find(id);
    if (it == m_blocks.end()) return;

    it->name = newName;
    it->updatedAt = QDateTime::currentDateTimeUtc();

    int row = m_filteredIds.indexOf(id);
    if (row >= 0) {
        QModelIndex idx = index(row);
        emit dataChanged(idx, idx, {NameRole, UpdatedAtRole});
    }

    save();
}

void BlockStore::removeBlock(const QString &id)
{
    if (!m_blocks.contains(id)) return;

    m_blocks.remove(id);
    rebuildFiltered();
    save();
    emit countChanged();
    emit allTagsChanged();
}

void BlockStore::addTag(const QString &id, const QString &tag)
{
    auto it = m_blocks.find(id);
    if (it == m_blocks.end()) return;
    if (it->tags.contains(tag)) return;

    it->tags.append(tag);
    int row = m_filteredIds.indexOf(id);
    if (row >= 0) {
        QModelIndex idx = index(row);
        emit dataChanged(idx, idx, {TagsRole});
    }

    save();
    emit allTagsChanged();
}

void BlockStore::removeTag(const QString &id, const QString &tag)
{
    auto it = m_blocks.find(id);
    if (it == m_blocks.end()) return;

    it->tags.removeAll(tag);
    int row = m_filteredIds.indexOf(id);
    if (row >= 0) {
        QModelIndex idx = index(row);
        emit dataChanged(idx, idx, {TagsRole});
    }

    save();
    emit allTagsChanged();
}

QVariantMap BlockStore::getBlock(const QString &id) const
{
    auto it = m_blocks.find(id);
    if (it == m_blocks.end()) return {};

    QVariantMap m;
    m["id"] = it->id;
    m["name"] = it->name;
    m["content"] = it->content;
    m["tags"] = it->tags;
    m["sourceFile"] = it->sourceFile;
    m["createdAt"] = it->createdAt.toString(Qt::ISODate);
    m["updatedAt"] = it->updatedAt.toString(Qt::ISODate);
    return m;
}

std::optional<BlockData> BlockStore::blockById(const QString &id) const
{
    auto it = m_blocks.find(id);
    if (it == m_blocks.end()) return std::nullopt;
    return *it;
}

QString BlockStore::searchFilter() const { return m_searchFilter; }

void BlockStore::setSearchFilter(const QString &filter)
{
    if (m_searchFilter == filter) return;
    m_searchFilter = filter;
    rebuildFiltered();
    emit searchFilterChanged();
}

QString BlockStore::tagFilter() const { return m_tagFilter; }

void BlockStore::setTagFilter(const QString &tag)
{
    if (m_tagFilter == tag) return;
    m_tagFilter = tag;
    rebuildFiltered();
    emit tagFilterChanged();
}

QStringList BlockStore::allTags() const
{
    QSet<QString> tags;
    for (const auto &b : m_blocks)
        for (const auto &t : b.tags)
            tags.insert(t);

    QStringList sorted(tags.begin(), tags.end());
    sorted.sort();
    return sorted;
}

void BlockStore::load()
{
    QFile file(m_dbPath);
    if (!file.open(QIODevice::ReadOnly)) return;

    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &err);
    file.close();

    if (err.error != QJsonParseError::NoError || !doc.isObject()) return;

    QJsonObject root = doc.object();
    QJsonObject blocksObj = root["blocks"].toObject();

    m_blocks.clear();

    for (auto it = blocksObj.begin(); it != blocksObj.end(); ++it) {
        QJsonObject obj = it.value().toObject();
        BlockData b;
        b.id = obj["id"].toString();
        b.name = obj["name"].toString();
        b.content = obj["content"].toString();
        b.sourceFile = obj["sourceFile"].toString();
        b.createdAt = QDateTime::fromString(obj["createdAt"].toString(), Qt::ISODate);
        b.updatedAt = QDateTime::fromString(obj["updatedAt"].toString(), Qt::ISODate);

        for (const auto &t : obj["tags"].toArray())
            b.tags.append(t.toString());

        m_blocks.insert(b.id, b);
    }

    rebuildFiltered();
    emit countChanged();
    emit allTagsChanged();
}

void BlockStore::save()
{
    QDir dir(QFileInfo(m_dbPath).absolutePath());
    if (!dir.exists()) dir.mkpath(".");

    QJsonObject blocksObj;
    for (const auto &b : m_blocks) {
        QJsonObject obj;
        obj["id"] = b.id;
        obj["name"] = b.name;
        obj["content"] = b.content;
        obj["sourceFile"] = b.sourceFile;
        obj["createdAt"] = b.createdAt.toString(Qt::ISODate);
        obj["updatedAt"] = b.updatedAt.toString(Qt::ISODate);

        QJsonArray tagsArr;
        for (const auto &t : b.tags)
            tagsArr.append(t);
        obj["tags"] = tagsArr;

        blocksObj[b.id] = obj;
    }

    QJsonObject root;
    root["blocks"] = blocksObj;

    QJsonObject meta;
    meta["version"] = 1;
    meta["updatedAt"] = QDateTime::currentDateTimeUtc().toString(Qt::ISODate);
    root["meta"] = meta;

    QSaveFile file(m_dbPath);
    if (!file.open(QIODevice::WriteOnly)) {
        qWarning("BlockStore: could not write %s", qPrintable(m_dbPath));
        emit saveFailed(tr("Could not save blocks database"));
        return;
    }

    const QByteArray json = QJsonDocument(root).toJson(QJsonDocument::Indented);
    if (file.write(json) != json.size() || !file.commit()) {
        qWarning("BlockStore: write/commit failed for %s", qPrintable(m_dbPath));
        emit saveFailed(tr("Could not save blocks database"));
    }
}

void BlockStore::rebuildFiltered()
{
    beginResetModel();
    m_filteredIds.clear();

    for (auto it = m_blocks.begin(); it != m_blocks.end(); ++it) {
        const auto &b = it.value();

        // Tag filter
        if (!m_tagFilter.isEmpty() && !b.tags.contains(m_tagFilter))
            continue;

        // Search filter
        if (!m_searchFilter.isEmpty()) {
            bool match = b.name.contains(m_searchFilter, Qt::CaseInsensitive)
                      || b.content.contains(m_searchFilter, Qt::CaseInsensitive)
                      || b.tags.join(' ').contains(m_searchFilter, Qt::CaseInsensitive);
            if (!match) continue;
        }

        m_filteredIds.append(it.key());
    }

    // Sort by name
    std::sort(m_filteredIds.begin(), m_filteredIds.end(), [this](const QString &a, const QString &b) {
        return m_blocks.value(a).name.toLower() < m_blocks.value(b).name.toLower();
    });

    endResetModel();
}

QString BlockStore::generateId() const
{
    auto *rng = QRandomGenerator::global();
    QString id;
    do {
        quint32 val = rng->bounded(0x1000000u); // 24 bits = 6 hex chars
        id = QString::number(val, 16).rightJustified(6, '0');
    } while (m_blocks.contains(id));
    return id;
}
