#include "promptstore.h"
#include "utils.h"

#include <QFile>
#include <QSaveFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDir>
#include <QGuiApplication>
#include <QClipboard>

PromptStore::PromptStore(const QString &dbPath, QObject *parent)
    : QAbstractListModel(parent)
    , m_dbPath(dbPath)
{
    load();
}

int PromptStore::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_filteredIds.size();
}

QVariant PromptStore::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_filteredIds.size())
        return {};

    auto it = m_prompts.constFind(m_filteredIds[index.row()]);
    if (it == m_prompts.constEnd()) return {};
    const auto &prompt = *it;

    switch (role) {
    case Qt::DisplayRole:
    case NameRole:      return prompt.name;
    case IdRole:        return prompt.id;
    case ContentRole:   return prompt.content;
    case CategoryRole:  return prompt.category;
    case CreatedAtRole: return prompt.createdAt.toString(Qt::ISODate);
    case UpdatedAtRole: return prompt.updatedAt.toString(Qt::ISODate);
    default: return {};
    }
}

QHash<int, QByteArray> PromptStore::roleNames() const
{
    return {
        {IdRole, "promptId"},
        {NameRole, "name"},
        {ContentRole, "content"},
        {CategoryRole, "category"},
        {CreatedAtRole, "createdAt"},
        {UpdatedAtRole, "updatedAt"},
        {Qt::DisplayRole, "display"}
    };
}

int PromptStore::count() const { return m_prompts.size(); }

QString PromptStore::createPrompt(const QString &name, const QString &content, const QString &category)
{
    QString id = generateId();
    PromptData prompt;
    prompt.id = id;
    prompt.name = name;
    prompt.content = content;
    prompt.category = category;
    prompt.createdAt = QDateTime::currentDateTimeUtc();
    prompt.updatedAt = prompt.createdAt;

    m_prompts.insert(id, prompt);
    rebuildFiltered();
    save();
    emit countChanged();
    emit allCategoriesChanged();
    return id;
}

void PromptStore::updatePrompt(const QString &id, const QString &name,
                                const QString &content, const QString &category)
{
    auto it = m_prompts.find(id);
    if (it == m_prompts.end()) return;

    it->name = name;
    it->content = content;
    it->updatedAt = QDateTime::currentDateTimeUtc();

    bool categoryChanged = (it->category != category);
    it->category = category;

    int row = m_filteredIds.indexOf(id);
    if (row >= 0) {
        QModelIndex idx = index(row);
        emit dataChanged(idx, idx, {NameRole, ContentRole, CategoryRole, UpdatedAtRole});
    }

    save();
    if (categoryChanged)
        emit allCategoriesChanged();
}

void PromptStore::removePrompt(const QString &id)
{
    if (!m_prompts.contains(id)) return;

    m_prompts.remove(id);
    rebuildFiltered();
    save();
    emit countChanged();
    emit allCategoriesChanged();
}

QVariantMap PromptStore::getPrompt(const QString &id) const
{
    auto it = m_prompts.find(id);
    if (it == m_prompts.end()) return {};

    QVariantMap m;
    m["id"] = it->id;
    m["name"] = it->name;
    m["content"] = it->content;
    m["category"] = it->category;
    m["createdAt"] = it->createdAt.toString(Qt::ISODate);
    m["updatedAt"] = it->updatedAt.toString(Qt::ISODate);
    return m;
}

void PromptStore::copyToClipboard(const QString &id)
{
    auto it = m_prompts.find(id);
    if (it == m_prompts.end()) return;

    QGuiApplication::clipboard()->setText(it->content);
    emit copied(it->name);
}

QString PromptStore::searchFilter() const { return m_searchFilter; }

void PromptStore::setSearchFilter(const QString &filter)
{
    if (m_searchFilter == filter) return;
    m_searchFilter = filter;
    rebuildFiltered();
    emit searchFilterChanged();
}

QString PromptStore::categoryFilter() const { return m_categoryFilter; }

void PromptStore::setCategoryFilter(const QString &category)
{
    if (m_categoryFilter == category) return;
    m_categoryFilter = category;
    rebuildFiltered();
    emit categoryFilterChanged();
}

QStringList PromptStore::allCategories() const
{
    QSet<QString> cats;
    for (const auto &p : m_prompts)
        if (!p.category.isEmpty())
            cats.insert(p.category);

    QStringList sorted(cats.begin(), cats.end());
    sorted.sort();
    return sorted;
}

void PromptStore::load()
{
    QFile file(m_dbPath);
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning("PromptStore: failed to open %s", qPrintable(m_dbPath));
        return;
    }

    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &err);
    file.close();

    if (err.error != QJsonParseError::NoError || !doc.isObject()) {
        qWarning("PromptStore: JSON parse error in %s: %s", qPrintable(m_dbPath), qPrintable(err.errorString()));
        return;
    }

    QJsonObject root = doc.object();
    QJsonArray promptsArr = root["prompts"].toArray();

    m_prompts.clear();

    for (const auto &val : promptsArr) {
        QJsonObject obj = val.toObject();
        PromptData p;
        p.id = obj["id"].toString();
        p.name = obj["name"].toString();
        p.content = obj["content"].toString();
        p.category = obj["category"].toString();
        p.createdAt = QDateTime::fromString(obj["createdAt"].toString(), Qt::ISODate);
        p.updatedAt = QDateTime::fromString(obj["updatedAt"].toString(), Qt::ISODate);

        m_prompts.insert(p.id, p);
    }

    rebuildFiltered();
    emit countChanged();
    emit allCategoriesChanged();
}

void PromptStore::save()
{
    QDir dir(QFileInfo(m_dbPath).absolutePath());
    if (!dir.exists()) dir.mkpath(".");

    QJsonArray promptsArr;
    for (const auto &p : m_prompts) {
        QJsonObject obj;
        obj["id"] = p.id;
        obj["name"] = p.name;
        obj["content"] = p.content;
        obj["category"] = p.category;
        obj["createdAt"] = p.createdAt.toString(Qt::ISODate);
        obj["updatedAt"] = p.updatedAt.toString(Qt::ISODate);
        promptsArr.append(obj);
    }

    QJsonObject root;
    root["prompts"] = promptsArr;

    QJsonArray catsArr;
    for (const auto &c : allCategories())
        catsArr.append(c);
    root["categories"] = catsArr;

    QSaveFile file(m_dbPath);
    if (!file.open(QIODevice::WriteOnly)) {
        qWarning("PromptStore: could not write %s", qPrintable(m_dbPath));
        emit saveFailed(tr("Could not save prompts database"));
        return;
    }

    const QByteArray json = QJsonDocument(root).toJson(QJsonDocument::Indented);
    if (file.write(json) != json.size() || !file.commit()) {
        qWarning("PromptStore: write/commit failed for %s", qPrintable(m_dbPath));
        emit saveFailed(tr("Could not save prompts database"));
    }
}

void PromptStore::rebuildFiltered()
{
    beginResetModel();
    m_filteredIds.clear();

    for (auto it = m_prompts.begin(); it != m_prompts.end(); ++it) {
        const auto &p = it.value();

        // Category filter
        if (!m_categoryFilter.isEmpty() && p.category != m_categoryFilter)
            continue;

        // Search filter
        if (!m_searchFilter.isEmpty()) {
            bool match = p.name.contains(m_searchFilter, Qt::CaseInsensitive)
                      || p.content.contains(m_searchFilter, Qt::CaseInsensitive)
                      || p.category.contains(m_searchFilter, Qt::CaseInsensitive);
            if (!match) continue;
        }

        m_filteredIds.append(it.key());
    }

    // Sort by name
    std::sort(m_filteredIds.begin(), m_filteredIds.end(), [this](const QString &a, const QString &b) {
        return m_prompts[a].name.toLower() < m_prompts[b].name.toLower();
    });

    endResetModel();
}

QString PromptStore::generateId() const
{
    return Utils::generateHexId(24, QStringLiteral("p"), [this](const QString &id) {
        return m_prompts.contains(id);
    });
}
