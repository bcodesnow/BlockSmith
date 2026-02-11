#pragma once

#include <QSyntaxHighlighter>
#include <QTextCharFormat>
#include <QRegularExpression>
#include <QQuickTextDocument>
#include <QtQml/qqmlregistration.h>

class MdSyntaxHighlighter : public QSyntaxHighlighter
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QQuickTextDocument* document READ quickDocument WRITE setQuickDocument NOTIFY quickDocumentChanged)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)

public:
    explicit MdSyntaxHighlighter(QObject *parent = nullptr);

    QQuickTextDocument *quickDocument() const;
    void setQuickDocument(QQuickTextDocument *doc);

    bool enabled() const;
    void setEnabled(bool enabled);

protected:
    void highlightBlock(const QString &text) override;

signals:
    void quickDocumentChanged();
    void enabledChanged();

private:
    void setupFormats();

    struct HighlightRule {
        QRegularExpression pattern;
        QTextCharFormat format;
    };

    QQuickTextDocument *m_quickDocument = nullptr;
    bool m_enabled = true;

    QVector<HighlightRule> m_rules;
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
};
