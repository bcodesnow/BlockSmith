#pragma once

#include <QSyntaxHighlighter>
#include <QTextCharFormat>
#include <QRegularExpression>
#include <QQuickTextDocument>
#include <QtQml/qqmlregistration.h>

class SyntaxHighlighter : public QSyntaxHighlighter
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QQuickTextDocument* document READ quickDocument WRITE setQuickDocument NOTIFY quickDocumentChanged)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(Mode mode READ mode WRITE setMode NOTIFY modeChanged)
    Q_PROPERTY(bool isDarkTheme READ isDarkTheme WRITE setIsDarkTheme NOTIFY isDarkThemeChanged)

public:
    enum Mode { Markdown, Json, Yaml, PlainText };
    Q_ENUM(Mode)

    explicit SyntaxHighlighter(QObject *parent = nullptr);

    QQuickTextDocument *quickDocument() const;
    void setQuickDocument(QQuickTextDocument *doc);

    bool enabled() const;
    void setEnabled(bool enabled);

    Mode mode() const;
    void setMode(Mode mode);

    bool isDarkTheme() const;
    void setIsDarkTheme(bool dark);

protected:
    void highlightBlock(const QString &text) override;

signals:
    void quickDocumentChanged();
    void enabledChanged();
    void modeChanged();
    void isDarkThemeChanged();

private:
    void setupMdFormats();
    void setupJsonFormats();
    void setupYamlFormats();
    void highlightMarkdown(const QString &text);
    void highlightJson(const QString &text);
    void highlightYaml(const QString &text);

    QQuickTextDocument *m_quickDocument = nullptr;
    bool m_enabled = true;
    Mode m_mode = Markdown;
    bool m_isDarkTheme = true;

    // Markdown formats
    struct HighlightRule {
        QRegularExpression pattern;
        QTextCharFormat format;
    };

    QVector<HighlightRule> m_mdRules;
    QTextCharFormat m_h1Format;
    QTextCharFormat m_h2Format;
    QTextCharFormat m_h3Format;
    QTextCharFormat m_h456Format;
    QTextCharFormat m_boldFormat;
    QTextCharFormat m_italicFormat;
    QTextCharFormat m_codeInlineFormat;
    QTextCharFormat m_codeFenceFormat;
    QTextCharFormat m_linkFormat;
    QTextCharFormat m_blockquoteFormat;
    QTextCharFormat m_listFormat;
    QTextCharFormat m_blockCommentFormat;
    QTextCharFormat m_hrFormat;

    // JSON formats
    QTextCharFormat m_keyFormat;
    QTextCharFormat m_stringFormat;
    QTextCharFormat m_numberFormat;
    QTextCharFormat m_boolNullFormat;
    QTextCharFormat m_bracketFormat;

    // YAML formats
    QTextCharFormat m_yamlKeyFormat;
    QTextCharFormat m_yamlValueFormat;
    QTextCharFormat m_yamlCommentFormat;
    QTextCharFormat m_yamlAnchorFormat;
    QTextCharFormat m_yamlTagFormat;
};
