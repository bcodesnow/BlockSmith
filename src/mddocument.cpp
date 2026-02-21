#include "mddocument.h"

#include <QFile>
#include <QDir>
#include <QTextStream>
#include <QRegularExpression>
#include <QStringConverter>
#include <QSaveFile>

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

    // Detect encoding from BOM and configure stream accordingly
    QByteArray bom = file.peek(4);
    QString detectedEncoding = QStringLiteral("UTF-8");
    auto streamEncoding = QStringConverter::Utf8;

    if (bom.size() >= 3
        && static_cast<unsigned char>(bom[0]) == 0xEF
        && static_cast<unsigned char>(bom[1]) == 0xBB
        && static_cast<unsigned char>(bom[2]) == 0xBF) {
        detectedEncoding = QStringLiteral("UTF-8 BOM");
        streamEncoding = QStringConverter::Utf8;
    } else if (bom.size() >= 2
               && static_cast<unsigned char>(bom[0]) == 0xFF
               && static_cast<unsigned char>(bom[1]) == 0xFE) {
        detectedEncoding = QStringLiteral("UTF-16 LE");
        streamEncoding = QStringConverter::Utf16LE;
    } else if (bom.size() >= 2
               && static_cast<unsigned char>(bom[0]) == 0xFE
               && static_cast<unsigned char>(bom[1]) == 0xFF) {
        detectedEncoding = QStringLiteral("UTF-16 BE");
        streamEncoding = QStringConverter::Utf16BE;
    }

    QTextStream in(&file);
    in.setEncoding(streamEncoding);
    QString content = in.readAll();
    file.close();

    // Strip BOM character (U+FEFF) if present — we re-add it on save via setGenerateByteOrderMark
    if (!content.isEmpty() && content.at(0) == QChar(0xFEFF))
        content.remove(0, 1);

    m_filePath = filePath;
    m_rawContent = content;
    m_savedContent = content;
    m_modified = false;
    bool encChanged = (m_encoding != detectedEncoding);
    m_encoding = detectedEncoding;
    m_streamEncoding = streamEncoding;
    m_hasBom = detectedEncoding.contains(QStringLiteral("BOM"))
               || detectedEncoding.contains(QStringLiteral("UTF-16"));

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

    // QSaveFile writes to a temp file, then atomically renames on commit()
    QSaveFile file(m_filePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        qWarning("MdDocument: could not write %s", qPrintable(m_filePath));
        emit saveFailed(tr("Cannot write file: %1").arg(m_filePath));
        return;
    }

    QTextStream out(&file);
    out.setEncoding(m_streamEncoding);
    out.setGenerateByteOrderMark(m_hasBom);
    out << m_rawContent;
    out.flush();

    if (!file.commit()) {
        qWarning("MdDocument: atomic save failed for %s", qPrintable(m_filePath));
        emit saveFailed(tr("Save failed: %1").arg(m_filePath));
        return;
    }

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
    m_streamEncoding = QStringConverter::Utf8;
    m_hasBom = false;
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
