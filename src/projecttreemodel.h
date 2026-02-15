#pragma once

#include <QAbstractItemModel>
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
    TreeNode *child(int row) const;
    int childCount() const;
    int row() const;
    TreeNode *parentNode() const;

    QString name() const { return m_name; }
    QString path() const { return m_path; }
    NodeType nodeType() const { return m_type; }
    bool isTriggerFile() const { return m_isTriggerFile; }

private:
    QString m_name;
    QString m_path;
    NodeType m_type;
    bool m_isTriggerFile;
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
        IsTriggerFileRole
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

private:
    TreeNode *nodeFromIndex(const QModelIndex &index) const;
    TreeNode *m_rootNode = nullptr;
};
