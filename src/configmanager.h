#pragma once

#include <QObject>
#include <QStringList>
#include <QVariantMap>
#include <QList>
#include <QtQml/qqmlregistration.h>

class ConfigManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QStringList searchPaths READ searchPaths WRITE setSearchPaths NOTIFY searchPathsChanged)
    Q_PROPERTY(QStringList ignorePatterns READ ignorePatterns WRITE setIgnorePatterns NOTIFY ignorePatternsChanged)
    Q_PROPERTY(QStringList triggerFiles READ triggerFiles WRITE setTriggerFiles NOTIFY triggerFilesChanged)
    Q_PROPERTY(QVariantMap windowGeometry READ windowGeometry WRITE setWindowGeometry NOTIFY windowGeometryChanged)
    Q_PROPERTY(QList<int> splitterSizes READ splitterSizes WRITE setSplitterSizes NOTIFY splitterSizesChanged)
    Q_PROPERTY(bool autoScanOnStartup READ autoScanOnStartup WRITE setAutoScanOnStartup NOTIFY autoScanOnStartupChanged)
    Q_PROPERTY(bool syntaxHighlightEnabled READ syntaxHighlightEnabled WRITE setSyntaxHighlightEnabled NOTIFY syntaxHighlightEnabledChanged)
    Q_PROPERTY(int scanDepth READ scanDepth WRITE setScanDepth NOTIFY scanDepthChanged)
    Q_PROPERTY(bool markdownToolbarVisible READ markdownToolbarVisible WRITE setMarkdownToolbarVisible NOTIFY markdownToolbarVisibleChanged)

public:
    explicit ConfigManager(QObject *parent = nullptr);

    QStringList searchPaths() const;
    void setSearchPaths(const QStringList &paths);

    QStringList ignorePatterns() const;
    void setIgnorePatterns(const QStringList &patterns);

    QStringList triggerFiles() const;
    void setTriggerFiles(const QStringList &files);

    QVariantMap windowGeometry() const;
    void setWindowGeometry(const QVariantMap &geometry);

    QList<int> splitterSizes() const;
    void setSplitterSizes(const QList<int> &sizes);

    bool autoScanOnStartup() const;
    void setAutoScanOnStartup(bool enabled);

    bool syntaxHighlightEnabled() const;
    void setSyntaxHighlightEnabled(bool enabled);

    int scanDepth() const;
    void setScanDepth(int depth);

    bool markdownToolbarVisible() const;
    void setMarkdownToolbarVisible(bool visible);

    Q_INVOKABLE void load();
    Q_INVOKABLE void save();

signals:
    void searchPathsChanged();
    void ignorePatternsChanged();
    void triggerFilesChanged();
    void windowGeometryChanged();
    void splitterSizesChanged();
    void autoScanOnStartupChanged();
    void syntaxHighlightEnabledChanged();
    void scanDepthChanged();
    void markdownToolbarVisibleChanged();

private:
    QString configDir() const;
    QString configFilePath() const;

    QStringList m_searchPaths;
    QStringList m_ignorePatterns;
    QStringList m_triggerFiles;
    QVariantMap m_windowGeometry;
    QList<int> m_splitterSizes;
    bool m_autoScanOnStartup = true;
    bool m_syntaxHighlightEnabled = true;
    int m_scanDepth = 0; // 0 = unlimited
    bool m_markdownToolbarVisible = true;
};
