#pragma once

#include <QAbstractListModel>
#include <QJsonObject>
#include <QThread>
#include <QtQml/qqmlregistration.h>
#include <atomic>
#include <memory>

struct JsonlEntry {
    int lineNumber;
    QJsonObject data;
    QString preview;
    QString role;
    bool hasToolUse = false;
};

// Worker that parses JSONL on a background thread
class JsonlWorker : public QObject
{
    Q_OBJECT
public:
    explicit JsonlWorker(const QString &filePath, quint64 generation,
                         const std::shared_ptr<std::atomic<bool>> &cancelFlag,
                         QObject *parent = nullptr);

    quint64 generation() const { return m_generation; }

public slots:
    void process();

signals:
    void chunkReady(const QVector<JsonlEntry> &entries, quint64 generation);
    void progressChanged(int current, quint64 generation);
    void finished(quint64 generation);
    void error(const QString &message, quint64 generation);

private:
    QString m_filePath;
    quint64 m_generation;
    std::shared_ptr<std::atomic<bool>> m_cancelFlag;
};

class JsonlStore : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Use via AppController.jsonlStore")

    Q_PROPERTY(QString filePath READ filePath NOTIFY filePathChanged)
    Q_PROPERTY(int totalCount READ totalCount NOTIFY totalCountChanged)
    Q_PROPERTY(int filteredCount READ filteredCount NOTIFY filteredCountChanged)
    Q_PROPERTY(QStringList availableRoles READ availableRoles NOTIFY availableRolesChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(int loadProgress READ loadProgress NOTIFY loadProgressChanged)
    Q_PROPERTY(QString textFilter READ textFilter WRITE setTextFilter NOTIFY textFilterChanged)
    Q_PROPERTY(QString roleFilter READ roleFilter WRITE setRoleFilter NOTIFY roleFilterChanged)
    Q_PROPERTY(bool toolUseOnly READ toolUseOnly WRITE setToolUseOnly NOTIFY toolUseOnlyChanged)

public:
    enum Roles {
        LineNumberRole = Qt::UserRole + 1,
        PreviewRole,
        RoleNameRole,
        HasToolUseRole,
        FullJsonRole,
        IsExpandedRole
    };
    Q_ENUM(Roles)

    explicit JsonlStore(QObject *parent = nullptr);
    ~JsonlStore() override;

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString filePath() const;
    int totalCount() const;
    int filteredCount() const;
    QStringList availableRoles() const;
    bool loading() const;
    int loadProgress() const;

    QString textFilter() const;
    void setTextFilter(const QString &text);
    QString roleFilter() const;
    void setRoleFilter(const QString &role);
    bool toolUseOnly() const;
    void setToolUseOnly(bool only);

    Q_INVOKABLE void load(const QString &filePath);
    Q_INVOKABLE void clear();
    Q_INVOKABLE void toggleExpanded(int index);
    Q_INVOKABLE QString entryJson(int index) const;
    Q_INVOKABLE void copyEntry(int index);

signals:
    void filePathChanged();
    void totalCountChanged();
    void filteredCountChanged();
    void availableRolesChanged();
    void loadingChanged();
    void loadProgressChanged();
    void textFilterChanged();
    void roleFilterChanged();
    void toolUseOnlyChanged();
    void loadFailed(const QString &error);
    void copied(const QString &preview);

private slots:
    void appendChunk(const QVector<JsonlEntry> &entries, quint64 generation);
    void onLoadFinished(quint64 generation);
    void onLoadError(const QString &message, quint64 generation);

private:
    void rebuildFiltered();
    void stopWorker();

    QString m_filePath;
    QVector<JsonlEntry> m_entries;
    QVector<int> m_filteredIndices;
    QSet<int> m_expandedRows;        // indices into m_filteredIndices
    QStringList m_availableRoles;
    bool m_loading = false;
    int m_loadProgress = 0;

    QString m_textFilter;
    QString m_roleFilter;
    bool m_toolUseOnly = false;

    QThread *m_workerThread = nullptr;
    std::shared_ptr<std::atomic<bool>> m_workerCancel;
    quint64 m_generation = 0;
};
