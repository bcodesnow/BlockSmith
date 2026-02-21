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

void TreeNode::insertChild(int row, TreeNode *child)
{
    m_children.insert(row, child);
    child->m_parent = this;
}

TreeNode *TreeNode::takeChild(int row)
{
    if (row < 0 || row >= m_children.size())
        return nullptr;
    TreeNode *child = m_children.at(row);
    m_children.removeAt(row);
    child->m_parent = nullptr;
    return child;
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

TreeNode *TreeNode::findChildByPath(const QString &path) const
{
    for (TreeNode *child : m_children) {
        if (child->m_path == path)
            return child;
    }
    return nullptr;
}

// --- Static helper: deep-clone a shadow TreeNode subtree ---

static TreeNode *cloneSubtree(TreeNode *source, TreeNode *newParent)
{
    auto *clone = new TreeNode(
        source->name(), source->path(), source->nodeType(),
        source->isTriggerFile(), newParent);
    clone->setCreatedDate(source->createdDate());

    for (TreeNode *srcChild : source->children()) {
        TreeNode *childClone = cloneSubtree(srcChild, clone);
        clone->appendChild(childClone);
    }
    return clone;
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
    case CreatedDateRole: {
        QDateTime dt = node->createdDate();
        if (!dt.isValid()) return QString();
        return dt.toString(QStringLiteral("yyyy-MM-dd"));
    }
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
        {CreatedDateRole, "createdDate"},
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

QModelIndex ProjectTreeModel::indexForNode(TreeNode *node) const
{
    if (!node || node == m_rootNode)
        return {};
    return createIndex(node->row(), 0, node);
}

void ProjectTreeModel::insertChildNode(TreeNode *parent, int row, TreeNode *child)
{
    QModelIndex parentIndex = indexForNode(parent);
    beginInsertRows(parentIndex, row, row);
    parent->insertChild(row, child);
    endInsertRows();
}

void ProjectTreeModel::removeChildNode(TreeNode *parent, int row)
{
    QModelIndex parentIndex = indexForNode(parent);
    beginRemoveRows(parentIndex, row, row);
    TreeNode *removed = parent->takeChild(row);
    endRemoveRows();
    delete removed;
}

void ProjectTreeModel::emitDataChanged(TreeNode *node)
{
    QModelIndex idx = indexForNode(node);
    if (idx.isValid())
        emit dataChanged(idx, idx);
}

void ProjectTreeModel::syncChildren(TreeNode *liveParent, TreeNode *newParent)
{
    // Pass 1: Remove children from live that don't exist in new (iterate backwards)
    for (int i = liveParent->childCount() - 1; i >= 0; --i) {
        TreeNode *liveChild = liveParent->child(i);
        bool found = false;
        for (TreeNode *nc : newParent->children()) {
            if (nc->path() == liveChild->path()) {
                found = true;
                break;
            }
        }
        if (!found)
            removeChildNode(liveParent, i);
    }

    // Pass 2: Insert new children and update existing ones, maintaining order
    for (int newIdx = 0; newIdx < newParent->childCount(); ++newIdx) {
        TreeNode *newChild = newParent->child(newIdx);
        TreeNode *liveChild = liveParent->findChildByPath(newChild->path());

        if (!liveChild) {
            // Build complete clone of the new subtree, then insert
            TreeNode *clone = cloneSubtree(newChild, liveParent);
            insertChildNode(liveParent, newIdx, clone);
        } else {
            // Update data if changed
            bool changed = false;
            if (liveChild->name() != newChild->name()) {
                liveChild->setName(newChild->name());
                changed = true;
            }
            if (liveChild->isTriggerFile() != newChild->isTriggerFile()) {
                liveChild->setIsTriggerFile(newChild->isTriggerFile());
                changed = true;
            }
            if (changed)
                emitDataChanged(liveChild);

            // Ensure correct position
            int liveIdx = liveChild->row();
            if (liveIdx != newIdx) {
                QModelIndex parentIndex = indexForNode(liveParent);
                int destIdx = newIdx > liveIdx ? newIdx + 1 : newIdx;
                beginMoveRows(parentIndex, liveIdx, liveIdx,
                              parentIndex, destIdx);
                TreeNode *taken = liveParent->takeChild(liveIdx);
                liveParent->insertChild(newIdx, taken);
                endMoveRows();
            }

            // Recurse into children for directories/project roots
            if (liveChild->nodeType() != TreeNode::MdFile) {
                syncChildren(liveChild, newChild);
            }
        }
    }
}

TreeNode *ProjectTreeModel::nodeFromIndex(const QModelIndex &index) const
{
    if (index.isValid())
        return static_cast<TreeNode *>(index.internalPointer());
    return m_rootNode;
}
