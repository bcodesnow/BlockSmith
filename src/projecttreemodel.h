#pragma once

#include <QAbstractItemModel>
#include <QDateTime>
#include <QString>
#include <QVector>
#include <QtQml/qqmlregistration.h>

class TreeNode
{
public:
    enum NodeType { ProjectRoot, Directory, MdFile };

    TreeNode(const QString &name, const QString &path, NodeType type,
             bool isTriggerFile = false, TreeNode *parent = nullptr);
    ~TreeNode();

    void appendChild(TreeNode *child);
    void insertChild(int row, TreeNode *child);
    TreeNode *takeChild(int row);
    TreeNode *child(int row) const;
    int childCount() const;
    int row() const;
    TreeNode *parentNode() const;
    const QVector<TreeNode *> &children() const { return m_children; }

    TreeNode *findChildByPath(const QString &path) const;

    QString name() const { return m_name; }
    QString path() const { return m_path; }
    NodeType nodeType() const { return m_type; }
    bool isTriggerFile() const { return m_isTriggerFile; }
    QDateTime createdDate() const { return m_createdDate; }

    void setName(const QString &name) { m_name = name; }
    void setIsTriggerFile(bool trigger) { m_isTriggerFile = trigger; }
    void setParent(TreeNode *parent) { m_parent = parent; }
    void setCreatedDate(const QDateTime &dt) { m_createdDate = dt; }

private:
    QString m_name;
    QString m_path;
    NodeType m_type;
    bool m_isTriggerFile;
    QDateTime m_createdDate;
    TreeNode *m_parent;
    QVector<TreeNode *> m_children;
};

class ProjectTreeModel : public QAbstractItemModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    enum Roles {
        NameRole = Qt::UserRole + 1,
        PathRole,
        NodeTypeRole,
        IsTriggerFileRole,
        CreatedDateRole
    };
    Q_ENUM(Roles)

    explicit ProjectTreeModel(QObject *parent = nullptr);
    ~ProjectTreeModel() override;

    // QAbstractItemModel interface
    QModelIndex index(int row, int column, const QModelIndex &parent = {}) const override;
    QModelIndex parent(const QModelIndex &child) const override;
    int rowCount(const QModelIndex &parent = {}) const override;
    int columnCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void clear();
    TreeNode *rootNode() const { return m_rootNode; }
    void addProjectRoot(TreeNode *projectRoot);

    // Incremental update methods
    QModelIndex indexForNode(TreeNode *node) const;
    void insertChildNode(TreeNode *parent, int row, TreeNode *child);
    void removeChildNode(TreeNode *parent, int row);
    void emitDataChanged(TreeNode *node);
    void syncChildren(TreeNode *liveParent, TreeNode *newParent);

private:
    TreeNode *nodeFromIndex(const QModelIndex &index) const;
    TreeNode *m_rootNode = nullptr;
};
