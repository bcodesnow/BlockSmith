#include "mddocument.h"

#include <QFile>
#include <QTextStream>
#include <QRegularExpression>

MdDocument::MdDocument(QObject *parent)
    : QObject(parent)
{
}

void MdDocument::load(const QString &filePath)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning("MdDocument: could not open %s", qPrintable(filePath));
        emit loadFailed(tr("Cannot open file: %1").arg(filePath));
        return;
    }

    // Detect encoding from BOM
    QByteArray bom = file.peek(4);
    QString detectedEncoding = QStringLiteral("UTF-8");
    if (bom.size() >= 3
        && static_cast<unsigned char>(bom[0]) == 0xEF
        && static_cast<unsigned char>(bom[1]) == 0xBB
        && static_cast<unsigned char>(bom[2]) == 0xBF) {
        detectedEncoding = QStringLiteral("UTF-8 BOM");
    } else if (bom.size() >= 2
               && static_cast<unsigned char>(bom[0]) == 0xFF
               && static_cast<unsigned char>(bom[1]) == 0xFE) {
        detectedEncoding = QStringLiteral("UTF-16 LE");
    } else if (bom.size() >= 2
               && static_cast<unsigned char>(bom[0]) == 0xFE
               && static_cast<unsigned char>(bom[1]) == 0xFF) {
        detectedEncoding = QStringLiteral("UTF-16 BE");
    }

    QTextStream in(&file);
    QString content = in.readAll();
    file.close();

    m_filePath = filePath;
    m_rawContent = content;
    m_savedContent = content;
    m_modified = false;
    bool encChanged = (m_encoding != detectedEncoding);
    m_encoding = detectedEncoding;

    parseBlocks();

    emit filePathChanged();
    emit rawContentChanged();
    emit modifiedChanged();
    if (encChanged)
        emit encodingChanged();
}

void MdDocument::save()
{
    if (m_filePath.isEmpty())
        return;

    QFile file(m_filePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        qWarning("MdDocument: could not write %s", qPrintable(m_filePath));
        emit saveFailed(tr("Cannot write file: %1").arg(m_filePath));
        return;
    }

    QTextStream out(&file);
    out << m_rawContent;
    file.close();

    m_savedContent = m_rawContent;
    m_modified = false;
    emit modifiedChanged();
    emit saved();
}

void MdDocument::clear()
{
    m_filePath.clear();
    m_rawContent.clear();
    m_savedContent.clear();
    m_modified = false;
    m_encoding = QStringLiteral("UTF-8");
    m_blocks.clear();

    emit filePathChanged();
    emit rawContentChanged();
    emit modifiedChanged();
    emit encodingChanged();
}

void MdDocument::reload()
{
    if (!m_filePath.isEmpty())
        load(m_filePath);
}

QString MdDocument::filePath() const { return m_filePath; }

QString MdDocument::rawContent() const { return m_rawContent; }

void MdDocument::setRawContent(const QString &content)
{
    if (m_rawContent == content)
        return;

    m_rawContent = content;
    m_modified = (m_rawContent != m_savedContent);

    parseBlocks();

    emit rawContentChanged();
    emit modifiedChanged();
}

bool MdDocument::modified() const { return m_modified; }

QString MdDocument::encoding() const { return m_encoding; }

QList<MdDocument::BlockSegment> MdDocument::blocks() const
{
    return m_blocks;
}

QVariantList MdDocument::blockList() const
{
    QVariantList list;
    for (const auto &b : m_blocks) {
        QVariantMap m;
        m["id"] = b.id;
        m["name"] = b.name;
        m["content"] = b.content;
        m["startPos"] = b.startPos;
        m["endPos"] = b.endPos;
        list.append(m);
    }
    return list;
}

void MdDocument::wrapSelectionAsBlock(int startPos, int endPos,
                                       const QString &blockId, const QString &blockName)
{
    if (startPos < 0 || endPos < startPos || endPos > m_rawContent.length())
        return;

    QString selected = m_rawContent.mid(startPos, endPos - startPos);
    QString openTag = QString("<!-- block: %1 [id:%2] -->\n").arg(blockName, blockId);
    QString closeTag = QString("\n<!-- /block:%1 -->").arg(blockId);

    // Ensure selection starts on its own line
    if (startPos > 0 && m_rawContent[startPos - 1] != '\n')
        openTag.prepend('\n');

    QString wrapped = openTag + selected + closeTag;
    m_rawContent.replace(startPos, endPos - startPos, wrapped);

    m_modified = true;
    parseBlocks();
    emit rawContentChanged();
    emit modifiedChanged();
}

void MdDocument::insertBlock(int position, const QString &blockId,
                              const QString &blockName, const QString &content)
{
    if (position < 0) position = m_rawContent.length();

    QString openTag = QString("<!-- block: %1 [id:%2] -->\n").arg(blockName, blockId);
    QString closeTag = QString("\n<!-- /block:%1 -->").arg(blockId);

    QString insertion = "\n" + openTag + content + closeTag + "\n";
    m_rawContent.insert(position, insertion);

    m_modified = true;
    parseBlocks();
    emit rawContentChanged();
    emit modifiedChanged();
}

void MdDocument::parseBlocks()
{
    m_blocks.clear();

    static const QRegularExpression blockRx(
        R"(<!-- block:\s*(.+?)\s*\[id:([a-f0-9]{6})\]\s*-->\n([\s\S]*?)<!-- \/block:\2 -->)");

    auto it = blockRx.globalMatch(m_rawContent);
    while (it.hasNext()) {
        auto match = it.next();
        BlockSegment seg;
        seg.name = match.captured(1);
        seg.id = match.captured(2);
        seg.content = match.captured(3);
        seg.startPos = static_cast<int>(match.capturedStart());
        seg.endPos = static_cast<int>(match.capturedEnd());
        m_blocks.append(seg);
    }
}
