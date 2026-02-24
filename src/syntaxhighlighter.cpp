#include "syntaxhighlighter.h"

SyntaxHighlighter::SyntaxHighlighter(QObject *parent)
    : QSyntaxHighlighter(parent)
{
    setupMdFormats();
    setupJsonFormats();
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

void SyntaxHighlighter::highlightBlock(const QString &text)
{
    if (!m_enabled)
        return;

    switch (m_mode) {
    case Markdown: highlightMarkdown(text); break;
    case Json:     highlightJson(text);     break;
    case PlainText: break;
    }
}

// --- Markdown highlighting ---

void SyntaxHighlighter::setupMdFormats()
{
    // H1: bright blue, bold
    m_h1Format.setForeground(QColor("#6cb6ff"));
    m_h1Format.setFontWeight(QFont::Bold);

    // H2: soft blue
    m_h2Format.setForeground(QColor("#58a6ff"));
    m_h2Format.setFontWeight(QFont::Bold);

    // H3: teal
    m_h3Format.setForeground(QColor("#56d4dd"));
    m_h3Format.setFontWeight(QFont::Bold);

    // H4-6: muted teal
    m_h456Format.setForeground(QColor("#4daa9e"));
    m_h456Format.setFontWeight(QFont::Bold);

    // Bold: orange-yellow
    m_boldFormat.setForeground(QColor("#e0c060"));
    m_boldFormat.setFontWeight(QFont::Bold);

    // Italic: soft green
    m_italicFormat.setForeground(QColor("#a5d6a7"));
    m_italicFormat.setFontItalic(true);

    // Inline code: pink on dark bg
    m_codeInlineFormat.setForeground(QColor("#e06c75"));
    m_codeInlineFormat.setBackground(QColor("#2a2a2a"));

    // Code fence markers
    m_codeFenceFormat.setForeground(QColor("#888"));
    m_codeFenceFormat.setBackground(QColor("#252525"));

    // Links: blue underline
    m_linkFormat.setForeground(QColor("#6c9bd2"));
    m_linkFormat.setFontUnderline(true);

    // Blockquote: muted green
    m_blockquoteFormat.setForeground(QColor("#7a9a6a"));

    // List markers: muted yellow
    m_listFormat.setForeground(QColor("#c0a050"));

    // Block comments (<!-- block: ... -->): dimmed
    m_blockCommentFormat.setForeground(QColor("#5a6a5a"));

    // Horizontal rule
    m_hrFormat.setForeground(QColor("#666"));

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
    // Keys: blue
    m_keyFormat.setForeground(QColor("#6cb6ff"));

    // String values: green
    m_stringFormat.setForeground(QColor("#a5d6a7"));

    // Numbers: orange
    m_numberFormat.setForeground(QColor("#e0c060"));

    // Booleans and null: purple
    m_boolNullFormat.setForeground(QColor("#c594c5"));
    m_boolNullFormat.setFontWeight(QFont::Bold);

    // Braces, brackets, colons: muted
    m_bracketFormat.setForeground(QColor("#888"));
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
