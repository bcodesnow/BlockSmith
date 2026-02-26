#include "document.h"
#include "blockstore.h"
#include "utils.h"

#include <QFile>
#include <QDir>
#include <QTextStream>
#include <QRegularExpression>
#include <QSaveFile>
#include <QJsonDocument>
#include <yaml-cpp/yaml.h>
#include <yaml-cpp/emittermanip.h>
#include <vector>

Document::Document(QObject *parent)
    : QObject(parent)
{
    connect(&m_watcher, &QFileSystemWatcher::fileChanged,
            this, &Document::onFileChanged);
    connect(&m_autoSaveTimer, &QTimer::timeout,
            this, &Document::onAutoSaveTimer);
}

void Document::load(const QString &filePath)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning("Document: could not open %s", qPrintable(filePath));
        emit loadFailed(tr("Cannot open file: %1").arg(filePath));
        return;
    }

    // Detect encoding from BOM and configure stream accordingly
    bool hasBom = false;
    auto streamEncoding = Utils::detectBomEncoding(file, hasBom);

    QString detectedEncoding = QStringLiteral("UTF-8");
    if (hasBom) {
        switch (streamEncoding) {
        case QStringConverter::Utf8:    detectedEncoding = QStringLiteral("UTF-8 BOM"); break;
        case QStringConverter::Utf16LE: detectedEncoding = QStringLiteral("UTF-16 LE"); break;
        case QStringConverter::Utf16BE: detectedEncoding = QStringLiteral("UTF-16 BE"); break;
        default: break;
        }
    }

    QTextStream in(&file);
    in.setEncoding(streamEncoding);
    QString content = in.readAll();
    file.close();

    // Strip BOM character (U+FEFF) if present — we re-add it on save via setGenerateByteOrderMark
    if (!content.isEmpty() && content.at(0) == QChar(0xFEFF))
        content.remove(0, 1);

    unwatchFile();

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
    watchFile(m_filePath);

    emit rawContentChanged();
    emit filePathChanged();
    emit modifiedChanged();
    if (encChanged)
        emit encodingChanged();
}

void Document::save()
{
    if (m_filePath.isEmpty())
        return;

    m_ignoreNextChange = true;

    // QSaveFile writes to a temp file, then atomically renames on commit()
    QSaveFile file(m_filePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        m_ignoreNextChange = false;
        qWarning("Document: could not write %s", qPrintable(m_filePath));
        emit saveFailed(tr("Cannot write file: %1").arg(m_filePath));
        return;
    }

    QTextStream out(&file);
    out.setEncoding(m_streamEncoding);
    out.setGenerateByteOrderMark(m_hasBom);
    out << m_rawContent;
    out.flush();

    if (!file.commit()) {
        m_ignoreNextChange = false;
        qWarning("Document: atomic save failed for %s", qPrintable(m_filePath));
        emit saveFailed(tr("Save failed: %1").arg(m_filePath));
        return;
    }

    m_savedContent = m_rawContent;
    m_modified = false;

    // QSaveFile atomic rename may remove the old path from QFileSystemWatcher.
    // Re-watch to ensure we continue monitoring.
    watchFile(m_filePath);

    emit modifiedChanged();
    emit saved();
}

void Document::saveTo(const QString &newPath)
{
    unwatchFile();
    m_filePath = newPath;
    emit filePathChanged();
    save();
    watchFile(m_filePath);
}

void Document::clear()
{
    unwatchFile();
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

void Document::reload()
{
    if (!m_filePath.isEmpty())
        load(m_filePath);
}

QString Document::filePath() const { return m_filePath; }

Document::FileType Document::fileType() const
{
    if (m_filePath.endsWith(QLatin1String(".json"), Qt::CaseInsensitive))
        return Json;
    if (m_filePath.endsWith(QLatin1String(".yaml"), Qt::CaseInsensitive)
        || m_filePath.endsWith(QLatin1String(".yml"), Qt::CaseInsensitive))
        return Yaml;
    if (m_filePath.endsWith(QLatin1String(".md"), Qt::CaseInsensitive)
        || m_filePath.endsWith(QLatin1String(".markdown"), Qt::CaseInsensitive))
        return Markdown;
    return PlainText;
}

QString Document::formatId() const
{
    switch (fileType()) {
    case Markdown: return QStringLiteral("markdown");
    case Json:     return QStringLiteral("json");
    case Yaml:     return QStringLiteral("yaml");
    default:       return QStringLiteral("plaintext");
    }
}

Document::SyntaxMode Document::syntaxMode() const
{
    switch (fileType()) {
    case Markdown: return SyntaxMarkdown;
    case Json:     return SyntaxJson;
    case Yaml:     return SyntaxYaml;
    default:       return SyntaxPlainText;
    }
}

Document::ToolbarKind Document::toolbarKind() const
{
    switch (fileType()) {
    case Markdown: return ToolbarMarkdown;
    case Json:     return ToolbarJson;
    case Yaml:     return ToolbarYaml;
    default:       return ToolbarNone;
    }
}

Document::PreviewKind Document::previewKind() const
{
    return fileType() == Markdown ? PreviewMarkdown : PreviewNone;
}

bool Document::isJson() const { return fileType() == Json; }

bool Document::supportsPreview() const { return previewKind() != PreviewNone; }

QString Document::rawContent() const { return m_rawContent; }

void Document::setRawContent(const QString &content)
{
    if (m_rawContent == content)
        return;

    m_rawContent = content;
    m_modified = (m_rawContent != m_savedContent);

    parseBlocks();

    emit rawContentChanged();
    emit modifiedChanged();
}

bool Document::modified() const { return m_modified; }

QString Document::encoding() const { return m_encoding; }

QList<Document::BlockSegment> Document::blocks() const
{
    return m_blocks;
}

QVariantList Document::blockList() const
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

void Document::wrapSelectionAsBlock(int startPos, int endPos,
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

void Document::insertBlock(int position, const QString &blockId,
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

void Document::setAutoSave(bool enabled, int intervalSecs)
{
    if (enabled) {
        m_autoSaveTimer.setInterval(intervalSecs * 1000);
        if (!m_autoSaveTimer.isActive())
            m_autoSaveTimer.start();
    } else {
        m_autoSaveTimer.stop();
    }
}

void Document::onAutoSaveTimer()
{
    if (m_modified && !m_filePath.isEmpty()) {
        save();
        // Only signal auto-saved if save() actually succeeded (m_modified cleared)
        if (!m_modified)
            emit autoSaved();
    }
}

void Document::watchFile(const QString &path)
{
    if (path.isEmpty())
        return;
    if (!m_watcher.files().contains(path))
        m_watcher.addPath(path);
}

void Document::unwatchFile()
{
    if (!m_watcher.files().isEmpty())
        m_watcher.removePaths(m_watcher.files());
}

void Document::onFileChanged(const QString &path)
{
    Q_UNUSED(path)

    if (m_ignoreNextChange) {
        m_ignoreNextChange = false;
        return;
    }

    // Check if file still exists
    if (!QFile::exists(m_filePath)) {
        emit fileDeletedExternally();
        return;
    }

    // If document has no unsaved changes, auto-reload silently
    if (!m_modified) {
        load(m_filePath);
        return;
    }

    // Document has unsaved changes — let QML decide (show banner)
    emit fileChangedExternally();

    // Re-watch: some systems remove the watch after a change notification
    watchFile(m_filePath);
}

void Document::parseBlocks()
{
    m_blocks.clear();

    static const QRegularExpression blockRx(
        R"(<!-- block:\s*(.+?)\s*\[id:([a-f0-9]{6})\]\s*-->\r?\n([\s\S]*?)<!-- \/block:\2 -->)");

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

void Document::setBlockStore(BlockStore *store)
{
    m_blockStore = store;
}

QVariantList Document::findMatches(const QString &text, bool caseSensitive) const
{
    QVariantList results;
    if (text.isEmpty() || m_rawContent.isEmpty())
        return results;

    // Escape for literal matching
    QString escaped = QRegularExpression::escape(text);
    QRegularExpression::PatternOptions opts = QRegularExpression::NoPatternOption;
    if (!caseSensitive)
        opts |= QRegularExpression::CaseInsensitiveOption;

    QRegularExpression rx(escaped, opts);
    auto it = rx.globalMatch(m_rawContent);
    while (it.hasNext()) {
        auto m = it.next();
        QVariantMap hit;
        hit[QStringLiteral("start")] = static_cast<int>(m.capturedStart());
        hit[QStringLiteral("end")] = static_cast<int>(m.capturedEnd());
        results.append(hit);
    }
    return results;
}

QVariantList Document::computeBlockRanges() const
{
    QVariantList ranges;
    if (m_rawContent.isEmpty())
        return ranges;

    static const QRegularExpression openRx(
        QStringLiteral(R"(<!--\s*block:\s*(.+?)\s*\[id:([a-f0-9]{6})\]\s*-->)"));

    const QStringList lines = m_rawContent.split('\n');
    QString curId, curName;
    int curStartLine = 0;
    QStringList contentLines;
    bool inBlock = false;

    for (int i = 0; i < lines.size(); i++) {
        const QString &line = lines[i];

        if (!inBlock) {
            auto m = openRx.match(line);
            if (m.hasMatch()) {
                curName = m.captured(1);
                curId = m.captured(2);
                curStartLine = i + 1;  // 1-based
                contentLines.clear();
                inBlock = true;
            }
        } else {
            QRegularExpression closeRx(QStringLiteral("<!--\\s*/block:") + curId + QStringLiteral("\\s*-->"));
            if (closeRx.match(line).hasMatch()) {
                // Join and strip \r remnants from CRLF split-by-\n
                QString content = contentLines.join('\n');
                content.remove(QLatin1Char('\r'));
                QString status = QStringLiteral("local");
                if (m_blockStore) {
                    auto storeBlock = m_blockStore->blockById(curId);
                    if (storeBlock) {
                        status = (storeBlock->content == content)
                                     ? QStringLiteral("synced")
                                     : QStringLiteral("diverged");
                    }
                }
                QVariantMap entry;
                entry[QStringLiteral("startLine")] = curStartLine;
                entry[QStringLiteral("endLine")] = i + 1;
                entry[QStringLiteral("id")] = curId;
                entry[QStringLiteral("name")] = curName;
                entry[QStringLiteral("status")] = status;
                ranges.append(entry);
                inBlock = false;
            } else {
                contentLines.append(line);
            }
        }
    }
    return ranges;
}

QString Document::prettifyJson() const
{
    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(m_rawContent.toUtf8(), &err);
    if (err.error != QJsonParseError::NoError)
        return QString(); // invalid JSON — return empty to signal failure
    return QString::fromUtf8(doc.toJson(QJsonDocument::Indented));
}

QString Document::prettifyYaml() const
{
    try {
        std::vector<YAML::Node> docs = YAML::LoadAll(m_rawContent.toStdString());
        if (docs.empty())
            return QString();

        YAML::Emitter emitter;
        emitter.SetIndent(2);
        if (docs.size() == 1) {
            emitter << docs.front();
        } else {
            for (size_t i = 0; i < docs.size(); i++) {
                emitter << YAML::BeginDoc << docs[i];
                if (i + 1 < docs.size())
                    emitter << YAML::Newline;
            }
        }

        if (!emitter.good())
            return QString();
        return QString::fromStdString(emitter.c_str());
    } catch (const YAML::Exception &) {
        return QString(); // invalid YAML — return empty to signal failure
    }
}
