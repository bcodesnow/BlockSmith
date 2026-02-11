#pragma once

#include <QAbstractListModel>
#include <QString>
#include <QStringList>
#include <QDateTime>
#include <QHash>
#include <QVector>
#include <QtQml/qqmlregistration.h>

struct PromptData {
    QString id;
    QString name;
    QString content;
    QString category;
    QDateTime createdAt;
    QDateTime updatedAt;
};

class PromptStore : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Use via AppController.promptStore")

    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(QString searchFilter READ searchFilter WRITE setSearchFilter NOTIFY searchFilterChanged)
    Q_PROPERTY(QString categoryFilter READ categoryFilter WRITE setCategoryFilter NOTIFY categoryFilterChanged)
    Q_PROPERTY(QStringList allCategories READ allCategories NOTIFY allCategoriesChanged)

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        ContentRole,
        CategoryRole,
        CreatedAtRole,
        UpdatedAtRole
    };
    Q_ENUM(Roles)

    explicit PromptStore(const QString &dbPath, QObject *parent = nullptr);

    // QAbstractListModel interface
    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const;

    // CRUD
    Q_INVOKABLE QString createPrompt(const QString &name, const QString &content, const QString &category);
    Q_INVOKABLE void updatePrompt(const QString &id, const QString &name, const QString &content, const QString &category);
    Q_INVOKABLE void removePrompt(const QString &id);

    // Lookup
    Q_INVOKABLE QVariantMap getPrompt(const QString &id) const;

    // Clipboard
    Q_INVOKABLE void copyToClipboard(const QString &id);

    // Filtering
    QString searchFilter() const;
    void setSearchFilter(const QString &filter);
    QString categoryFilter() const;
    void setCategoryFilter(const QString &category);
    QStringList allCategories() const;

    // Persistence
    void load();
    void save();

signals:
    void countChanged();
    void searchFilterChanged();
    void categoryFilterChanged();
    void allCategoriesChanged();
    void copied(const QString &name);

private:
    void rebuildFiltered();
    QString generateId() const;

    QString m_dbPath;
    QHash<QString, PromptData> m_prompts;
    QVector<QString> m_filteredIds;
    QString m_searchFilter;
    QString m_categoryFilter;
};
