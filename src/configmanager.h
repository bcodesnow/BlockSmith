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
    Q_PROPERTY(bool editorToolbarVisible READ editorToolbarVisible WRITE setEditorToolbarVisible NOTIFY editorToolbarVisibleChanged)
    Q_PROPERTY(QString imageSubfolder READ imageSubfolder WRITE setImageSubfolder NOTIFY imageSubfolderChanged)
    Q_PROPERTY(bool statusBarWordCount READ statusBarWordCount WRITE setStatusBarWordCount NOTIFY statusBarWordCountChanged)
    Q_PROPERTY(bool statusBarCharCount READ statusBarCharCount WRITE setStatusBarCharCount NOTIFY statusBarCharCountChanged)
    Q_PROPERTY(bool statusBarLineCount READ statusBarLineCount WRITE setStatusBarLineCount NOTIFY statusBarLineCountChanged)
    Q_PROPERTY(bool statusBarReadingTime READ statusBarReadingTime WRITE setStatusBarReadingTime NOTIFY statusBarReadingTimeChanged)
    Q_PROPERTY(bool includeClaudeCodeFolder READ includeClaudeCodeFolder WRITE setIncludeClaudeCodeFolder NOTIFY includeClaudeCodeFolderChanged)
    Q_PROPERTY(int zoomLevel READ zoomLevel WRITE setZoomLevel NOTIFY zoomLevelChanged)
    Q_PROPERTY(int splitLeftWidth READ splitLeftWidth WRITE setSplitLeftWidth NOTIFY splitLeftWidthChanged)
    Q_PROPERTY(int splitRightWidth READ splitRightWidth WRITE setSplitRightWidth NOTIFY splitRightWidthChanged)
    Q_PROPERTY(bool autoSaveEnabled READ autoSaveEnabled WRITE setAutoSaveEnabled NOTIFY autoSaveEnabledChanged)
    Q_PROPERTY(int autoSaveInterval READ autoSaveInterval WRITE setAutoSaveInterval NOTIFY autoSaveIntervalChanged)
    Q_PROPERTY(QStringList recentFiles READ recentFiles WRITE setRecentFiles NOTIFY recentFilesChanged)
    Q_PROPERTY(QString lastOpenFile READ lastOpenFile WRITE setLastOpenFile NOTIFY lastOpenFileChanged)
    Q_PROPERTY(bool searchIncludeMarkdown READ searchIncludeMarkdown WRITE setSearchIncludeMarkdown NOTIFY searchIncludeMarkdownChanged)
    Q_PROPERTY(bool searchIncludeJson READ searchIncludeJson WRITE setSearchIncludeJson NOTIFY searchIncludeJsonChanged)
    Q_PROPERTY(bool searchIncludeYaml READ searchIncludeYaml WRITE setSearchIncludeYaml NOTIFY searchIncludeYamlChanged)
    Q_PROPERTY(bool searchIncludeJsonl READ searchIncludeJsonl WRITE setSearchIncludeJsonl NOTIFY searchIncludeJsonlChanged)
    Q_PROPERTY(bool searchIncludePlaintext READ searchIncludePlaintext WRITE setSearchIncludePlaintext NOTIFY searchIncludePlaintextChanged)
    Q_PROPERTY(bool searchIncludePdf READ searchIncludePdf WRITE setSearchIncludePdf NOTIFY searchIncludePdfChanged)
    Q_PROPERTY(bool searchIncludeDocx READ searchIncludeDocx WRITE setSearchIncludeDocx NOTIFY searchIncludeDocxChanged)
    Q_PROPERTY(QString themeMode READ themeMode WRITE setThemeMode NOTIFY themeModeChanged)
    Q_PROPERTY(QString editorFontFamily READ editorFontFamily WRITE setEditorFontFamily NOTIFY editorFontFamilyChanged)
    Q_PROPERTY(bool wordWrap READ wordWrap WRITE setWordWrap NOTIFY wordWrapChanged)

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

    bool editorToolbarVisible() const;
    void setEditorToolbarVisible(bool visible);

    QString imageSubfolder() const;
    void setImageSubfolder(const QString &subfolder);

    bool statusBarWordCount() const;
    void setStatusBarWordCount(bool enabled);
    bool statusBarCharCount() const;
    void setStatusBarCharCount(bool enabled);
    bool statusBarLineCount() const;
    void setStatusBarLineCount(bool enabled);
    bool statusBarReadingTime() const;
    void setStatusBarReadingTime(bool enabled);

    bool includeClaudeCodeFolder() const;
    void setIncludeClaudeCodeFolder(bool enabled);
    Q_INVOKABLE QString claudeCodeFolderPath() const;

    int zoomLevel() const;
    void setZoomLevel(int level);

    int splitLeftWidth() const;
    void setSplitLeftWidth(int width);
    int splitRightWidth() const;
    void setSplitRightWidth(int width);

    bool autoSaveEnabled() const;
    void setAutoSaveEnabled(bool enabled);
    int autoSaveInterval() const;
    void setAutoSaveInterval(int seconds);

    QStringList recentFiles() const;
    void setRecentFiles(const QStringList &files);
    Q_INVOKABLE void addRecentFile(const QString &filePath);

    QString lastOpenFile() const;
    void setLastOpenFile(const QString &filePath);

    bool searchIncludeMarkdown() const;
    void setSearchIncludeMarkdown(bool enabled);

    bool searchIncludeJson() const;
    void setSearchIncludeJson(bool enabled);

    bool searchIncludeYaml() const;
    void setSearchIncludeYaml(bool enabled);

    bool searchIncludeJsonl() const;
    void setSearchIncludeJsonl(bool enabled);

    bool searchIncludePlaintext() const;
    void setSearchIncludePlaintext(bool enabled);

    bool searchIncludePdf() const;
    void setSearchIncludePdf(bool enabled);

    bool searchIncludeDocx() const;
    void setSearchIncludeDocx(bool enabled);

    QString themeMode() const;
    void setThemeMode(const QString &mode);

    QString editorFontFamily() const;
    void setEditorFontFamily(const QString &family);

    bool wordWrap() const;
    void setWordWrap(bool enabled);

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
    void editorToolbarVisibleChanged();
    void imageSubfolderChanged();
    void statusBarWordCountChanged();
    void statusBarCharCountChanged();
    void statusBarLineCountChanged();
    void statusBarReadingTimeChanged();
    void includeClaudeCodeFolderChanged();
    void zoomLevelChanged();
    void splitLeftWidthChanged();
    void splitRightWidthChanged();
    void autoSaveEnabledChanged();
    void autoSaveIntervalChanged();
    void recentFilesChanged();
    void lastOpenFileChanged();
    void searchIncludeMarkdownChanged();
    void searchIncludeJsonChanged();
    void searchIncludeYamlChanged();
    void searchIncludeJsonlChanged();
    void searchIncludePlaintextChanged();
    void searchIncludePdfChanged();
    void searchIncludeDocxChanged();
    void themeModeChanged();
    void editorFontFamilyChanged();
    void wordWrapChanged();
    void saveFailed(const QString &message);

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
    bool m_editorToolbarVisible = true;
    QString m_imageSubfolder = QStringLiteral("images");
    bool m_statusBarWordCount = true;
    bool m_statusBarCharCount = true;
    bool m_statusBarLineCount = true;
    bool m_statusBarReadingTime = true;
    bool m_includeClaudeCodeFolder = false;
    int m_zoomLevel = 100;
    int m_splitLeftWidth = 250;
    int m_splitRightWidth = 280;
    bool m_autoSaveEnabled = false;
    int m_autoSaveInterval = 30;
    QStringList m_recentFiles;
    QString m_lastOpenFile;
    bool m_searchIncludeMarkdown = true;
    bool m_searchIncludeJson = true;
    bool m_searchIncludeYaml = true;
    bool m_searchIncludeJsonl = false;
    bool m_searchIncludePlaintext = true;
    bool m_searchIncludePdf = false;
    bool m_searchIncludeDocx = false;
    QString m_themeMode = QStringLiteral("dark");
    QString m_editorFontFamily = QStringLiteral("Consolas");
    bool m_wordWrap = true;
};
