#include "md4crenderer.h"

#include <md4c-html.h>
#include <QByteArray>
#include <QRegularExpression>

namespace {

void mdHtmlCallback(const MD_CHAR *data, MD_SIZE size, void *userdata)
{
    auto *output = static_cast<QByteArray *>(userdata);
    output->append(data, static_cast<qsizetype>(size));
}

} // namespace

Md4cRenderer::Md4cRenderer(QObject *parent)
    : QObject(parent)
{
}

QString Md4cRenderer::render(const QString &markdown) const
{
    QByteArray input = markdown.toUtf8();
    QByteArray output;
    output.reserve(input.size() * 2);

    unsigned parserFlags = MD_FLAG_TABLES | MD_FLAG_STRIKETHROUGH | MD_FLAG_TASKLISTS;
    unsigned rendererFlags = 0;

    int result = md_html(input.constData(),
                         static_cast<MD_SIZE>(input.size()),
                         mdHtmlCallback,
                         &output,
                         parserFlags,
                         rendererFlags);

    if (result != 0) {
        qWarning("Md4cRenderer: md_html() failed with code %d", result);
        return QString();
    }

    return QString::fromUtf8(output);
}

QString Md4cRenderer::renderWithLineMap(const QString &markdown) const
{
    QString html = render(markdown);
    if (html.isEmpty())
        return html;

    QStringList sourceLines = markdown.split(QLatin1Char('\n'));

    // Regex matching block-level opening tags
    static const QRegularExpression blockTagRx(
        QStringLiteral(R"(<(h[1-6]|p|pre|blockquote|ul|ol|table|hr|li)(\s[^>]*)?>)"),
        QRegularExpression::CaseInsensitiveOption);

    // Regex to strip HTML tags from a snippet
    static const QRegularExpression htmlTagRx(QStringLiteral("<[^>]*>"));

    QString result;
    result.reserve(html.size() + sourceLines.size() * 30);

    int sourceLine = 0; // track forward-only search position
    int lastPos = 0;

    auto it = blockTagRx.globalMatch(html);
    while (it.hasNext()) {
        auto match = it.next();
        int tagStart = static_cast<int>(match.capturedStart());
        int tagEnd = static_cast<int>(match.capturedEnd());

        // Copy everything before this tag
        result.append(html.mid(lastPos, tagStart - lastPos));

        // Extract text content after the tag for matching against source
        int searchEnd = qMin(tagEnd + 200, static_cast<int>(html.size()));
        QString snippet = html.mid(tagEnd, searchEnd - tagEnd);
        snippet.remove(htmlTagRx);
        snippet = snippet.left(60).trimmed();

        // Search forward in source lines for a match
        int foundLine = -1;
        if (!snippet.isEmpty()) {
            QString probe = snippet.left(20);
            for (int i = sourceLine; i < sourceLines.size(); ++i) {
                if (sourceLines[i].contains(probe)) {
                    foundLine = i + 1; // 1-based
                    sourceLine = i;
                    break;
                }
            }
        } else {
            // Empty snippet (e.g. <hr>, <ul> with no immediate text).
            // For <hr>, search for a line starting with --- or *** or ___
            QString tagName = match.captured(1).toLower();
            if (tagName == QLatin1String("hr")) {
                static const QRegularExpression hrRx(
                    QStringLiteral(R"(^\s*([-*_])\s*\1\s*\1[\s\1]*$)"));
                for (int i = sourceLine; i < sourceLines.size(); ++i) {
                    if (hrRx.match(sourceLines[i]).hasMatch()) {
                        foundLine = i + 1;
                        sourceLine = i;
                        break;
                    }
                }
            }
        }

        // Inject data-source-line into the tag
        if (foundLine > 0) {
            QString tag = match.captured(0);
            tag.insert(tag.size() - 1,
                       QStringLiteral(" data-source-line=\"%1\"").arg(foundLine));
            result.append(tag);
        } else {
            result.append(match.captured(0));
        }

        lastPos = tagEnd;
    }

    result.append(html.mid(lastPos));
    return result;
}
