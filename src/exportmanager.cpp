#include "exportmanager.h"
#include "md4crenderer.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSaveFile>
#include <QStandardPaths>
#include <QTextStream>
#include <QProcess>
#include <QRegularExpression>
#include <QWebEnginePage>
#include <QPageLayout>
#include <QPageSize>
#include <QMarginsF>

// Font size presets: body / code
static int bodyFontSize(const QString &size)
{
    if (size == QLatin1String("small"))  return 11;
    if (size == QLatin1String("large"))  return 16;
    return 13; // medium (default)
}

static int codeFontSize(const QString &size)
{
    if (size == QLatin1String("small"))  return 10;
    if (size == QLatin1String("large"))  return 14;
    return 12; // medium (default)
}

// CSS template with %1 = body font size, %2 = code font size
// Dark theme — matches resources/preview/index.html
static const char *kDarkCssTpl = R"(
  body {
    background: #1e1e1e; color: #d4d4d4;
    font-family: Segoe UI, sans-serif; font-size: %1px;
    padding: 24px 32px; margin: 0; max-width: 900px; margin: 0 auto;
  }
  h1, h2, h3, h4 { color: #e0e0e0; margin-top: 12px; }
  code {
    background: #333; padding: 2px 4px;
    font-family: Consolas, monospace; border-radius: 3px; font-size: %2px;
  }
  pre {
    background: #2a2a2a; padding: 10px; border-radius: 4px;
    margin: 8px 0; overflow-x: auto;
  }
  pre code { background: transparent; padding: 0; }
  a { color: #6c9bd2; }
  blockquote {
    border-left: 3px solid #555; padding-left: 8px;
    color: #aaa; margin: 8px 0;
  }
  table { border-collapse: collapse; margin: 8px 0; width: 100%; }
  th, td { border: 1px solid #555; padding: 6px 10px; text-align: left; }
  th { background: #333; color: #e0e0e0; font-weight: bold; }
  tr:nth-child(even) { background: #2a2a2a; }
  hr { border: none; border-top: 1px solid #555; margin: 16px 0; }
  img { max-width: 100%; height: auto; border-radius: 4px; }
  ul, ol { padding-left: 24px; margin: 6px 0; }
  li { margin: 3px 0; }
  input[type="checkbox"] { margin-right: 4px; }
)";

// Light theme — print-friendly white background
static const char *kLightCssTpl = R"(
  body {
    background: #fff; color: #222;
    font-family: Segoe UI, sans-serif; font-size: %1px;
    padding: 24px 32px; margin: 0; max-width: 900px; margin: 0 auto;
  }
  h1, h2, h3, h4 { color: #111; margin-top: 12px; }
  code {
    background: #f0f0f0; padding: 2px 4px;
    font-family: Consolas, monospace; border-radius: 3px; font-size: %2px;
  }
  pre {
    background: #f6f6f6; padding: 10px; border-radius: 4px;
    margin: 8px 0; overflow-x: auto; border: 1px solid #ddd;
  }
  pre code { background: transparent; padding: 0; }
  a { color: #2563eb; }
  blockquote {
    border-left: 3px solid #ccc; padding-left: 8px;
    color: #555; margin: 8px 0;
  }
  table { border-collapse: collapse; margin: 8px 0; width: 100%; }
  th, td { border: 1px solid #ccc; padding: 6px 10px; text-align: left; }
  th { background: #f0f0f0; color: #111; font-weight: bold; }
  tr:nth-child(even) { background: #fafafa; }
  hr { border: none; border-top: 1px solid #ddd; margin: 16px 0; }
  img { max-width: 100%; height: auto; border-radius: 4px; }
  ul, ol { padding-left: 24px; margin: 6px 0; }
  li { margin: 3px 0; }
  input[type="checkbox"] { margin-right: 4px; }
)";

ExportManager::ExportManager(Md4cRenderer *renderer, QObject *parent)
    : QObject(parent)
    , m_renderer(renderer)
{
}

QString ExportManager::buildStandaloneHtml(const QString &markdown,
                                           const QString &docDir,
                                           bool lightBackground,
                                           const QString &fontSize) const
{
    QString body = m_renderer->render(markdown);

    // Resolve relative image paths to absolute file:// URLs
    if (!docDir.isEmpty()) {
        QString fileUrl = QStringLiteral("file:///")
                          + QString(docDir).replace(QLatin1Char('\\'), QLatin1Char('/'))
                          + QLatin1Char('/');
        static const QRegularExpression imgRx(
            QStringLiteral("src=\"(?!https?://|file://|data:)([^\"]+)\""));
        body.replace(imgRx, QStringLiteral("src=\"") + fileUrl + QStringLiteral("\\1\""));
    }

    const char *cssTpl = lightBackground ? kLightCssTpl : kDarkCssTpl;
    QString css = QString::fromLatin1(cssTpl)
                      .arg(bodyFontSize(fontSize))
                      .arg(codeFontSize(fontSize));

    return QStringLiteral("<!DOCTYPE html>\n<html>\n<head>\n"
                          "<meta charset=\"utf-8\">\n"
                          "<style>%1</style>\n"
                          "</head>\n<body>\n%2\n</body>\n</html>")
        .arg(css, body);
}

void ExportManager::exportHtml(const QString &markdown, const QString &outputPath,
                               const QString &docDir, bool lightBackground,
                               const QString &fontSize)
{
    QString html = buildStandaloneHtml(markdown, docDir, lightBackground, fontSize);

    QSaveFile file(outputPath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        emit exportError(QStringLiteral("Could not open file for writing: ") + outputPath);
        return;
    }

    QTextStream out(&file);
    out.setEncoding(QStringConverter::Utf8);
    out.setGenerateByteOrderMark(false);
    out << html;
    out.flush();

    if (!file.commit()) {
        emit exportError(QStringLiteral("Failed to write file: ") + outputPath);
        return;
    }

    emit exportComplete(outputPath);
}

void ExportManager::exportPdf(const QString &markdown, const QString &outputPath,
                              const QString &docDir, bool lightBackground,
                              const QString &fontSize)
{
    QString html = buildStandaloneHtml(markdown, docDir, lightBackground, fontSize);

    // Create an offscreen QWebEnginePage for rendering
    auto *page = new QWebEnginePage(this);

    connect(page, &QWebEnginePage::loadFinished, this,
            [this, page, outputPath](bool ok) {
                if (!ok) {
                    emit exportError(QStringLiteral("Failed to load HTML for PDF rendering"));
                    page->deleteLater();
                    return;
                }

                QPageLayout layout(QPageSize(QPageSize::A4), QPageLayout::Portrait,
                                   QMarginsF(15, 15, 15, 15), QPageLayout::Millimeter);

                page->printToPdf(outputPath, layout);
            });

    connect(page, &QWebEnginePage::pdfPrintingFinished, this,
            [this, page](const QString &filePath, bool success) {
                if (success)
                    emit exportComplete(filePath);
                else
                    emit exportError(QStringLiteral("PDF export failed"));
                page->deleteLater();
            });

    // Load HTML into the offscreen page — use docDir as base URL for images
    QUrl baseUrl = docDir.isEmpty() ? QUrl() : QUrl::fromLocalFile(docDir + "/");
    page->setHtml(html, baseUrl);
}

void ExportManager::exportDocx(const QString &mdFilePath, const QString &outputPath)
{
    QString pandoc = findPandoc();
    if (pandoc.isEmpty()) {
        emit exportError(QStringLiteral("Pandoc is not installed. "
                                        "Install from https://pandoc.org/installing.html"));
        return;
    }

    auto *proc = new QProcess(this);

    connect(proc, &QProcess::finished, this,
            [this, proc, outputPath](int exitCode, QProcess::ExitStatus status) {
                if (status == QProcess::NormalExit && exitCode == 0) {
                    emit exportComplete(outputPath);
                } else {
                    QString err = QString::fromUtf8(proc->readAllStandardError()).trimmed();
                    if (err.isEmpty())
                        err = QStringLiteral("Pandoc exited with code %1").arg(exitCode);
                    emit exportError(err);
                }
                proc->deleteLater();
            });

    proc->start(pandoc,
                {mdFilePath,
                 QStringLiteral("-o"), outputPath,
                 QStringLiteral("--from=markdown"),
                 QStringLiteral("--to=docx")});
}

void ExportManager::convertDocxToHtml(const QString &docxPath)
{
    QString pandoc = findPandoc();
    if (pandoc.isEmpty()) {
        emit docxConvertError(QStringLiteral("Pandoc is not installed. "
                                             "Install from https://pandoc.org/installing.html"));
        return;
    }

    auto *proc = new QProcess(this);

    connect(proc, &QProcess::finished, this,
            [this, proc](int exitCode, QProcess::ExitStatus status) {
                if (status == QProcess::NormalExit && exitCode == 0) {
                    QString html = QString::fromUtf8(proc->readAllStandardOutput());
                    emit docxHtmlReady(html);
                } else {
                    QString err = QString::fromUtf8(proc->readAllStandardError()).trimmed();
                    if (err.isEmpty())
                        err = QStringLiteral("Pandoc exited with code %1").arg(exitCode);
                    emit docxConvertError(err);
                }
                proc->deleteLater();
            });

    proc->start(pandoc,
                {docxPath,
                 QStringLiteral("--to=html"),
                 QStringLiteral("--embed-resources"),
                 QStringLiteral("--standalone")});
}

bool ExportManager::isPandocAvailable() const
{
    return !findPandoc().isEmpty();
}

QString ExportManager::findPandoc() const
{
    // Try PATH first
    QString path = QStandardPaths::findExecutable(QStringLiteral("pandoc"));
    if (!path.isEmpty())
        return path;

    // Check common Windows install locations
    const QStringList candidates = {
        QDir::homePath() + QStringLiteral("/AppData/Local/Pandoc/pandoc.exe"),
        QStringLiteral("C:/Program Files/Pandoc/pandoc.exe"),
    };
    for (const QString &candidate : candidates) {
        if (QFileInfo::exists(candidate))
            return candidate;
    }

    return {};
}

QString ExportManager::defaultExportPath(const QString &mdFilePath,
                                         const QString &extension) const
{
    if (mdFilePath.isEmpty())
        return {};

    QFileInfo fi(mdFilePath);
    return fi.absolutePath() + QLatin1Char('/') + fi.completeBaseName()
           + QLatin1Char('.') + extension;
}
