#include "md4crenderer.h"

#include <md4c-html.h>
#include <QByteArray>

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
