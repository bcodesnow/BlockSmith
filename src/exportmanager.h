#pragma once

#include <QObject>
#include <QString>
#include <QtQml/qqmlregistration.h>

class Md4cRenderer;
class QWebEnginePage;
class QProcess;

class ExportManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Use via AppController.exportManager")

public:
    explicit ExportManager(Md4cRenderer *renderer, QObject *parent = nullptr);

    // Export the current markdown content to various formats
    // lightBackground: true = print-friendly white theme, false = dark theme
    // fontSize: "small", "medium" (default), "large"
    Q_INVOKABLE void exportHtml(const QString &markdown, const QString &outputPath,
                                const QString &docDir, bool lightBackground = false,
                                const QString &fontSize = QStringLiteral("medium"));
    Q_INVOKABLE void exportPdf(const QString &markdown, const QString &outputPath,
                               const QString &docDir, bool lightBackground = false,
                               const QString &fontSize = QStringLiteral("medium"));
    Q_INVOKABLE void exportDocx(const QString &mdFilePath, const QString &outputPath);

    // Convert a .docx file to HTML for read-only viewing
    Q_INVOKABLE void convertDocxToHtml(const QString &docxPath);

    // Check if pandoc is installed
    Q_INVOKABLE bool isPandocAvailable() const;

    // Generate default output path: same dir as source, with given extension
    Q_INVOKABLE QString defaultExportPath(const QString &mdFilePath,
                                          const QString &extension) const;

signals:
    void exportComplete(const QString &outputPath);
    void exportError(const QString &message);
    void docxHtmlReady(const QString &html);
    void docxConvertError(const QString &message);

private:
    QString buildStandaloneHtml(const QString &markdown, const QString &docDir,
                                bool lightBackground, const QString &fontSize) const;
    QString findPandoc() const;

    Md4cRenderer *m_renderer;
};
