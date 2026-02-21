#pragma once

#include <QAbstractListModel>
#include <QString>
#include <QStringList>
#include <QDateTime>
#include <QHash>
#include <QVector>
#include <QtQml/qqmlregistration.h>
#include <optional>

struct BlockData {
    QString id;
    QString name;
    QString content;
    QStringList tags;
    QString sourceFile;
    QDateTime createdAt;
    QDateTime updatedAt;
};

class BlockStore : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Use via AppController.blockStore")

    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(QString searchFilter READ searchFilter WRITE setSearchFilter NOTIFY searchFilterChanged)
    Q_PROPERTY(QString tagFilter READ tagFilter WRITE setTagFilter NOTIFY tagFilterChanged)
    Q_PROPERTY(QStringList allTags READ allTags NOTIFY allTagsChanged)

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        ContentRole,
        TagsRole,
        SourceFileRole,
        CreatedAtRole,
        UpdatedAtRole
    };
    Q_ENUM(Roles)

    explicit BlockStore(const QString &dbPath, QObject *parent = nullptr);

    // QAbstractListModel interface
    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const;

    // CRUD
    Q_INVOKABLE QString createBlock(const QString &name, const QString &content,
                                     const QStringList &tags, const QString &sourceFile);
    Q_INVOKABLE void updateBlock(const QString &id, const QString &content);
    Q_INVOKABLE void renameBlock(const QString &id, const QString &newName);
    Q_INVOKABLE void removeBlock(const QString &id);
    Q_INVOKABLE void addTag(const QString &id, const QString &tag);
    Q_INVOKABLE void removeTag(const QString &id, const QString &tag);

    // Lookup
    Q_INVOKABLE QVariantMap getBlock(const QString &id) const;
    std::optional<BlockData> blockById(const QString &id) const;

    // Filtering
    QString searchFilter() const;
    void setSearchFilter(const QString &filter);
    QString tagFilter() const;
    void setTagFilter(const QString &tag);
    QStringList allTags() const;

    // Persistence
    void load();
    void save();

signals:
    void countChanged();
    void searchFilterChanged();
    void tagFilterChanged();
    void allTagsChanged();
    void blockUpdated(const QString &id);
    void saveFailed(const QString &message);

private:
    void rebuildFiltered();
    QString generateId() const;

    QString m_dbPath;
    QHash<QString, BlockData> m_blocks;       // all blocks by id
    QVector<QString> m_filteredIds;            // visible ids after filtering
    QString m_searchFilter;
    QString m_tagFilter;
};
