#include "projecttreemodel.h"

// --- TreeNode ---

TreeNode::TreeNode(const QString &name, const QString &path, NodeType type,
                   bool isTriggerFile, TreeNode *parent)
    : m_name(name), m_path(path), m_type(type),
      m_isTriggerFile(isTriggerFile), m_parent(parent)
{
}

TreeNode::~TreeNode()
{
    qDeleteAll(m_children);
}

void TreeNode::appendChild(TreeNode *child)
{
    m_children.append(child);
}

TreeNode *TreeNode::child(int row) const
{
    if (row < 0 || row >= m_children.size())
        return nullptr;
    return m_children.at(row);
}

int TreeNode::childCount() const
{
    return m_children.size();
}

int TreeNode::row() const
{
    if (!m_parent)
        return 0;
    return m_parent->m_children.indexOf(const_cast<TreeNode *>(this));
}

TreeNode *TreeNode::parentNode() const
{
    return m_parent;
}

// --- ProjectTreeModel ---

ProjectTreeModel::ProjectTreeModel(QObject *parent)
    : QAbstractItemModel(parent)
    , m_rootNode(new TreeNode("root", "", TreeNode::Directory))
{
}

ProjectTreeModel::~ProjectTreeModel()
{
    delete m_rootNode;
}

QModelIndex ProjectTreeModel::index(int row, int column, const QModelIndex &parent) const
{
    if (!hasIndex(row, column, parent))
        return {};

    TreeNode *parentNode = nodeFromIndex(parent);
    TreeNode *child = parentNode->child(row);
    if (child)
        return createIndex(row, column, child);
    return {};
}

QModelIndex ProjectTreeModel::parent(const QModelIndex &child) const
{
    if (!child.isValid())
        return {};

    auto *childNode = nodeFromIndex(child);
    TreeNode *parentNode = childNode->parentNode();

    if (!parentNode || parentNode == m_rootNode)
        return {};

    return createIndex(parentNode->row(), 0, parentNode);
}

int ProjectTreeModel::rowCount(const QModelIndex &parent) const
{
    TreeNode *node = nodeFromIndex(parent);
    return node->childCount();
}

int ProjectTreeModel::columnCount(const QModelIndex &) const
{
    return 1;
}

QVariant ProjectTreeModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid())
        return {};

    auto *node = nodeFromIndex(index);

    switch (role) {
    case Qt::DisplayRole:
    case NameRole:
        return node->name();
    case PathRole:
        return node->path();
    case NodeTypeRole:
        return static_cast<int>(node->nodeType());
    case IsTriggerFileRole:
        return node->isTriggerFile();
    case HasBlocksRole:
        return false; // Phase 4
    default:
        return {};
    }
}

QHash<int, QByteArray> ProjectTreeModel::roleNames() const
{
    return {
        {NameRole, "name"},
        {PathRole, "filePath"},
        {NodeTypeRole, "nodeType"},
        {IsTriggerFileRole, "isTriggerFile"},
        {HasBlocksRole, "hasBlocks"},
        {Qt::DisplayRole, "display"}
    };
}

void ProjectTreeModel::clear()
{
    beginResetModel();
    delete m_rootNode;
    m_rootNode = new TreeNode("root", "", TreeNode::Directory);
    endResetModel();
}

void ProjectTreeModel::addProjectRoot(TreeNode *projectRoot)
{
    int row = m_rootNode->childCount();
    beginInsertRows(QModelIndex(), row, row);
    m_rootNode->appendChild(projectRoot);
    endInsertRows();
}

TreeNode *ProjectTreeModel::nodeFromIndex(const QModelIndex &index) const
{
    if (index.isValid())
        return static_cast<TreeNode *>(index.internalPointer());
    return m_rootNode;
}
