#include "syntaxhighlighter.h"

SyntaxHighlighter::SyntaxHighlighter(QObject *parent)
    : QSyntaxHighlighter(parent)
{
    setupMdFormats();
    setupJsonFormats();
    setupYamlFormats();
}

QQuickTextDocument *SyntaxHighlighter::quickDocument() const
{
    return m_quickDocument;
}

void SyntaxHighlighter::setQuickDocument(QQuickTextDocument *doc)
{
    if (m_quickDocument == doc)
        return;

    m_quickDocument = doc;

    if (doc)
        setDocument(doc->textDocument());
    else
        setDocument(nullptr);

    emit quickDocumentChanged();
}

bool SyntaxHighlighter::enabled() const { return m_enabled; }

void SyntaxHighlighter::setEnabled(bool enabled)
{
    if (m_enabled == enabled)
        return;

    m_enabled = enabled;
    emit enabledChanged();

    if (document())
        rehighlight();
}

SyntaxHighlighter::Mode SyntaxHighlighter::mode() const { return m_mode; }

void SyntaxHighlighter::setMode(Mode mode)
{
    if (m_mode == mode)
        return;

    m_mode = mode;
    emit modeChanged();

    if (document())
        rehighlight();
}

bool SyntaxHighlighter::isDarkTheme() const { return m_isDarkTheme; }

void SyntaxHighlighter::setIsDarkTheme(bool dark)
{
    if (m_isDarkTheme == dark)
        return;

    m_isDarkTheme = dark;
    setupMdFormats();
    setupJsonFormats();
    setupYamlFormats();
    emit isDarkThemeChanged();

    if (document())
        rehighlight();
}

void SyntaxHighlighter::highlightBlock(const QString &text)
{
    if (!m_enabled)
        return;

    switch (m_mode) {
    case Markdown: highlightMarkdown(text); break;
    case Json:     highlightJson(text);     break;
    case Yaml:     highlightYaml(text);     break;
    case PlainText: break;
    }
}

// --- Markdown highlighting ---

void SyntaxHighlighter::setupMdFormats()
{
    const bool d = m_isDarkTheme;

    m_h1Format.setForeground(QColor(d ? "#6cb6ff" : "#0550ae"));
    m_h1Format.setFontWeight(QFont::Bold);

    m_h2Format.setForeground(QColor(d ? "#58a6ff" : "#0969da"));
    m_h2Format.setFontWeight(QFont::Bold);

    m_h3Format.setForeground(QColor(d ? "#56d4dd" : "#1a7f7f"));
    m_h3Format.setFontWeight(QFont::Bold);

    m_h456Format.setForeground(QColor(d ? "#4daa9e" : "#2b8a7e"));
    m_h456Format.setFontWeight(QFont::Bold);

    m_boldFormat.setForeground(QColor(d ? "#e0c060" : "#953800"));
    m_boldFormat.setFontWeight(QFont::Bold);

    m_italicFormat.setForeground(QColor(d ? "#a5d6a7" : "#2e7d32"));
    m_italicFormat.setFontItalic(true);

    m_codeInlineFormat.setForeground(QColor(d ? "#e06c75" : "#c9302c"));
    m_codeInlineFormat.setBackground(QColor(d ? "#2a2a2a" : "#eff1f3"));

    m_codeFenceFormat.setForeground(QColor(d ? "#888" : "#656d76"));
    m_codeFenceFormat.setBackground(QColor(d ? "#252525" : "#f6f8fa"));

    m_linkFormat.setForeground(QColor(d ? "#6c9bd2" : "#0969da"));
    m_linkFormat.setFontUnderline(true);

    m_blockquoteFormat.setForeground(QColor(d ? "#7a9a6a" : "#57606a"));

    m_listFormat.setForeground(QColor(d ? "#c0a050" : "#953800"));

    m_blockCommentFormat.setForeground(QColor(d ? "#5a6a5a" : "#8b949e"));

    m_hrFormat.setForeground(QColor(d ? "#666" : "#d0d7de"));

    // Build rule list (order matters — later rules can override earlier ones)
    m_mdRules = {
        // Headings (must be at start of line)
        { QRegularExpression(R"(^#{1}\s.+$)"),  m_h1Format },
        { QRegularExpression(R"(^#{2}\s.+$)"),   m_h2Format },
        { QRegularExpression(R"(^#{3}\s.+$)"),   m_h3Format },
        { QRegularExpression(R"(^#{4,6}\s.+$)"), m_h456Format },

        // Horizontal rule
        { QRegularExpression(R"(^(\*{3,}|-{3,}|_{3,})\s*$)"), m_hrFormat },

        // Blockquote
        { QRegularExpression(R"(^>\s?.*)"), m_blockquoteFormat },

        // List markers (-, *, +, or numbered)
        { QRegularExpression(R"(^\s*[-*+]\s)"), m_listFormat },
        { QRegularExpression(R"(^\s*\d+\.\s)"), m_listFormat },

        // Bold: **text** or __text__
        { QRegularExpression(R"(\*\*[^*]+\*\*)"), m_boldFormat },
        { QRegularExpression(R"(__[^_]+__)"), m_boldFormat },

        // Italic: *text* or _text_ (not preceded/followed by same char)
        { QRegularExpression(R"((?<!\*)\*(?!\*)([^*]+)(?<!\*)\*(?!\*))"), m_italicFormat },
        { QRegularExpression(R"((?<!_)_(?!_)([^_]+)(?<!_)_(?!_))"), m_italicFormat },

        // Inline code: `text`
        { QRegularExpression(R"(`[^`]+`)"), m_codeInlineFormat },

        // Links: [text](url) and ![alt](url)
        { QRegularExpression(R"(!?\[[^\]]*\]\([^)]*\))"), m_linkFormat },

        // Block comment tags: <!-- ... -->
        { QRegularExpression(R"(<!--.*?-->)"), m_blockCommentFormat },
    };
}

void SyntaxHighlighter::highlightMarkdown(const QString &text)
{
    // Check if we're inside a code fence
    // State: 0 = normal, 1 = inside code fence
    int prevState = previousBlockState();
    if (prevState < 0) prevState = 0;

    bool inCodeFence = (prevState == 1);

    // Check if this line starts/ends a code fence
    static const QRegularExpression fenceRx(R"(^```\s*\w*\s*$)");
    bool isFenceLine = fenceRx.match(text).hasMatch();

    if (isFenceLine) {
        setFormat(0, text.length(), m_codeFenceFormat);
        setCurrentBlockState(inCodeFence ? 0 : 1);
        return;
    }

    if (inCodeFence) {
        setFormat(0, text.length(), m_codeFenceFormat);
        setCurrentBlockState(1);
        return;
    }

    setCurrentBlockState(0);

    // Apply rules
    for (const auto &rule : m_mdRules) {
        auto it = rule.pattern.globalMatch(text);
        while (it.hasNext()) {
            auto match = it.next();
            setFormat(match.capturedStart(), match.capturedLength(), rule.format);
        }
    }
}

// --- JSON highlighting ---

void SyntaxHighlighter::setupJsonFormats()
{
    const bool d = m_isDarkTheme;

    m_keyFormat.setForeground(QColor(d ? "#6cb6ff" : "#0550ae"));
    m_stringFormat.setForeground(QColor(d ? "#a5d6a7" : "#0a3069"));
    m_numberFormat.setForeground(QColor(d ? "#e0c060" : "#953800"));

    m_boolNullFormat.setForeground(QColor(d ? "#c594c5" : "#8250df"));
    m_boolNullFormat.setFontWeight(QFont::Bold);

    m_bracketFormat.setForeground(QColor(d ? "#888" : "#656d76"));
}

void SyntaxHighlighter::highlightJson(const QString &text)
{
    int i = 0;
    const int len = text.length();
    bool expectingValue = false;

    while (i < len) {
        QChar ch = text[i];

        // Skip whitespace
        if (ch.isSpace()) { ++i; continue; }

        // Structural characters
        if (ch == '{' || ch == '}' || ch == '[' || ch == ']' || ch == ',') {
            setFormat(i, 1, m_bracketFormat);
            if (ch == '{') expectingValue = false; // next string is a key
            ++i;
            continue;
        }

        // Colon separator
        if (ch == ':') {
            setFormat(i, 1, m_bracketFormat);
            expectingValue = true;
            ++i;
            continue;
        }

        // Strings (keys or values)
        if (ch == '"') {
            int start = i;
            ++i;
            while (i < len) {
                if (text[i] == '\\') { i += 2; continue; }
                if (text[i] == '"') { ++i; break; }
                ++i;
            }
            setFormat(start, i - start, expectingValue ? m_stringFormat : m_keyFormat);
            continue;
        }

        // Numbers
        if (ch == '-' || ch.isDigit()) {
            int start = i;
            ++i;
            while (i < len && (text[i].isDigit() || text[i] == '.' || text[i] == 'e'
                               || text[i] == 'E' || text[i] == '+' || text[i] == '-'))
                ++i;
            setFormat(start, i - start, m_numberFormat);
            expectingValue = false;
            continue;
        }

        // Booleans and null
        if (text.mid(i, 4) == QLatin1String("true")) {
            setFormat(i, 4, m_boolNullFormat); i += 4; expectingValue = false; continue;
        }
        if (text.mid(i, 5) == QLatin1String("false")) {
            setFormat(i, 5, m_boolNullFormat); i += 5; expectingValue = false; continue;
        }
        if (text.mid(i, 4) == QLatin1String("null")) {
            setFormat(i, 4, m_boolNullFormat); i += 4; expectingValue = false; continue;
        }

        ++i;
    }
}

// --- YAML highlighting ---

void SyntaxHighlighter::setupYamlFormats()
{
    const bool d = m_isDarkTheme;

    m_yamlKeyFormat.setForeground(QColor(d ? "#6cb6ff" : "#0550ae"));
    m_yamlValueFormat.setForeground(QColor(d ? "#a5d6a7" : "#0a3069"));

    m_yamlCommentFormat.setForeground(QColor(d ? "#6a737d" : "#6e7781"));
    m_yamlCommentFormat.setFontItalic(true);

    m_yamlAnchorFormat.setForeground(QColor(d ? "#56d4dd" : "#1a7f7f"));
    m_yamlTagFormat.setForeground(QColor(d ? "#c594c5" : "#8250df"));
}

void SyntaxHighlighter::highlightYaml(const QString &text)
{
    const int len = text.length();
    if (len == 0) return;

    int i = 0;

    // Skip leading whitespace
    while (i < len && text[i].isSpace()) ++i;
    if (i >= len) return;

    // Full-line comment
    if (text[i] == '#') {
        setFormat(i, len - i, m_yamlCommentFormat);
        return;
    }

    // Document markers (--- and ...)
    if (i == 0 && len >= 3) {
        QStringView sv(text);
        if (sv == QLatin1String("---") || sv == QLatin1String("...")) {
            setFormat(0, len, m_bracketFormat);
            return;
        }
    }

    // Scan for key: value pattern
    // A key is text before the first unquoted `: ` or `:\n`/`:\r` (or `:` at end of line)
    bool foundKey = false;
    int keyStart = i;
    int scanPos = i;

    // Handle list item prefix (- )
    if (text[scanPos] == '-' && scanPos + 1 < len && text[scanPos + 1] == ' ') {
        setFormat(scanPos, 1, m_bracketFormat);
        scanPos += 2;
        while (scanPos < len && text[scanPos].isSpace()) ++scanPos;
        keyStart = scanPos;
    }

    // Scan for colon separator — skip quoted strings
    int colonPos = -1;
    int si = scanPos;
    while (si < len) {
        QChar ch = text[si];
        // Skip quoted strings
        if (ch == '"' || ch == '\'') {
            QChar quote = ch;
            ++si;
            while (si < len && text[si] != quote) {
                if (text[si] == '\\') ++si;
                ++si;
            }
            if (si < len) ++si;
            continue;
        }
        // Comment outside quotes
        if (ch == '#') break;
        // Colon followed by space, end-of-line, or at end
        if (ch == ':' && (si + 1 >= len || text[si + 1].isSpace())) {
            colonPos = si;
            break;
        }
        ++si;
    }

    if (colonPos > keyStart) {
        foundKey = true;
        setFormat(keyStart, colonPos - keyStart, m_yamlKeyFormat);
        setFormat(colonPos, 1, m_bracketFormat);  // the colon
        i = colonPos + 1;
    }

    // Highlight value portion (after colon, or entire line if no key)
    if (!foundKey) i = scanPos;

    // Skip whitespace after colon
    while (i < len && text[i].isSpace()) ++i;

    if (i < len) {
        QChar ch = text[i];

        // Inline comment
        if (ch == '#') {
            setFormat(i, len - i, m_yamlCommentFormat);
            return;
        }

        // Anchor (&name) or alias (*name)
        if (ch == '&' || ch == '*') {
            int start = i;
            ++i;
            while (i < len && !text[i].isSpace()) ++i;
            setFormat(start, i - start, m_yamlAnchorFormat);
            // Continue to highlight rest of line
            while (i < len && text[i].isSpace()) ++i;
        }

        // Tag (!!type or !tag)
        if (i < len && text[i] == '!') {
            int start = i;
            ++i;
            while (i < len && !text[i].isSpace()) ++i;
            setFormat(start, i - start, m_yamlTagFormat);
            while (i < len && text[i].isSpace()) ++i;
        }

        if (i < len && foundKey) {
            ch = text[i];

            // Quoted string value
            if (ch == '"' || ch == '\'') {
                int start = i;
                QChar quote = ch;
                ++i;
                while (i < len && text[i] != quote) {
                    if (text[i] == '\\') ++i;
                    ++i;
                }
                if (i < len) ++i;
                setFormat(start, i - start, m_yamlValueFormat);
            }
            // Boolean / null keywords
            else {
                QStringView rest = QStringView(text).mid(i).trimmed();
                // Strip trailing comment
                int commentIdx = -1;
                for (int ci = 0; ci < rest.length(); ++ci) {
                    if (rest[ci] == '#' && ci > 0 && rest[ci - 1].isSpace()) {
                        commentIdx = ci;
                        break;
                    }
                }
                QStringView val = commentIdx >= 0 ? rest.left(commentIdx).trimmed() : rest;

                if (val == QLatin1String("true") || val == QLatin1String("false")
                    || val == QLatin1String("yes") || val == QLatin1String("no")
                    || val == QLatin1String("on") || val == QLatin1String("off")
                    || val == QLatin1String("null") || val == QLatin1String("~")
                    || val == QLatin1String("True") || val == QLatin1String("False")
                    || val == QLatin1String("Yes") || val == QLatin1String("No")
                    || val == QLatin1String("NULL") || val == QLatin1String("Null")) {
                    setFormat(i, val.length(), m_boolNullFormat);
                }
                // Numeric value
                else {
                    static const QRegularExpression numRx(
                        R"(^[+-]?(\d+\.?\d*([eE][+-]?\d+)?|0x[0-9a-fA-F]+|0o[0-7]+|\.inf|\.nan)$)",
                        QRegularExpression::CaseInsensitiveOption);
                    if (numRx.match(val).hasMatch()) {
                        setFormat(i, val.length(), m_numberFormat);
                    } else if (!val.isEmpty()) {
                        setFormat(i, val.length(), m_yamlValueFormat);
                    }
                }
            }
        }
    }

    // Highlight trailing comment (# after value)
    int commentStart = -1;
    bool inQuote = false;
    QChar quoteChar;
    for (int ci = (foundKey ? colonPos + 1 : scanPos); ci < len; ++ci) {
        QChar ch = text[ci];
        if (!inQuote && (ch == '"' || ch == '\'')) {
            inQuote = true;
            quoteChar = ch;
        } else if (inQuote && ch == quoteChar) {
            inQuote = false;
        } else if (!inQuote && ch == '#' && ci > 0 && text[ci - 1].isSpace()) {
            commentStart = ci;
            break;
        }
    }
    if (commentStart >= 0)
        setFormat(commentStart, len - commentStart, m_yamlCommentFormat);
}
