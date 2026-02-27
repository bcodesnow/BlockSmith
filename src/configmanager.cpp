#include "configmanager.h"

#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QStandardPaths>
#include <QGuiApplication>

ConfigManager::ConfigManager(QObject *parent)
    : QObject(parent)
{
    // Defaults
    m_ignorePatterns = {"node_modules", ".git", "dist", "build",
                        "__pycache__", ".venv", "venv", "target", ".build"};
    m_triggerFiles = {"CLAUDE.md", "claude.md", ".claude.md",
                      "AGENTS.md", "agents.md", ".agents.md", ".git"};
    m_windowGeometry = {{"x", 100}, {"y", 100}, {"w", 1400}, {"h", 900}};
    m_splitterSizes = {250, -1, 280};

    load();
}

QString ConfigManager::configDir() const
{
    QString base = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    // AppConfigLocation on Windows: C:/Users/<user>/AppData/Local/<app>
    // We want a "BlockSmith" subfolder under the generic config location
    return base;
}

QString ConfigManager::configFilePath() const
{
    return configDir() + "/config.json";
}

QStringList ConfigManager::searchPaths() const { return m_searchPaths; }

void ConfigManager::setSearchPaths(const QStringList &paths)
{
    if (m_searchPaths != paths) {
        m_searchPaths = paths;
        emit searchPathsChanged();
    }
}

QStringList ConfigManager::ignorePatterns() const { return m_ignorePatterns; }

void ConfigManager::setIgnorePatterns(const QStringList &patterns)
{
    if (m_ignorePatterns != patterns) {
        m_ignorePatterns = patterns;
        emit ignorePatternsChanged();
    }
}

QStringList ConfigManager::triggerFiles() const { return m_triggerFiles; }

void ConfigManager::setTriggerFiles(const QStringList &files)
{
    if (m_triggerFiles != files) {
        m_triggerFiles = files;
        emit triggerFilesChanged();
    }
}

QVariantMap ConfigManager::windowGeometry() const { return m_windowGeometry; }

void ConfigManager::setWindowGeometry(const QVariantMap &geometry)
{
    if (m_windowGeometry != geometry) {
        m_windowGeometry = geometry;
        emit windowGeometryChanged();
    }
}

QList<int> ConfigManager::splitterSizes() const { return m_splitterSizes; }

void ConfigManager::setSplitterSizes(const QList<int> &sizes)
{
    if (m_splitterSizes != sizes) {
        m_splitterSizes = sizes;
        emit splitterSizesChanged();
    }
}

bool ConfigManager::autoScanOnStartup() const { return m_autoScanOnStartup; }

void ConfigManager::setAutoScanOnStartup(bool enabled)
{
    if (m_autoScanOnStartup != enabled) {
        m_autoScanOnStartup = enabled;
        emit autoScanOnStartupChanged();
    }
}

bool ConfigManager::syntaxHighlightEnabled() const { return m_syntaxHighlightEnabled; }

void ConfigManager::setSyntaxHighlightEnabled(bool enabled)
{
    if (m_syntaxHighlightEnabled != enabled) {
        m_syntaxHighlightEnabled = enabled;
        emit syntaxHighlightEnabledChanged();
    }
}

int ConfigManager::scanDepth() const { return m_scanDepth; }

void ConfigManager::setScanDepth(int depth)
{
    if (m_scanDepth != depth) {
        m_scanDepth = depth;
        emit scanDepthChanged();
    }
}

bool ConfigManager::editorToolbarVisible() const { return m_editorToolbarVisible; }

void ConfigManager::setEditorToolbarVisible(bool visible)
{
    if (m_editorToolbarVisible != visible) {
        m_editorToolbarVisible = visible;
        emit editorToolbarVisibleChanged();
    }
}

QString ConfigManager::imageSubfolder() const { return m_imageSubfolder; }

void ConfigManager::setImageSubfolder(const QString &subfolder)
{
    if (m_imageSubfolder != subfolder) {
        m_imageSubfolder = subfolder;
        emit imageSubfolderChanged();
    }
}

bool ConfigManager::statusBarWordCount() const { return m_statusBarWordCount; }
void ConfigManager::setStatusBarWordCount(bool enabled)
{
    if (m_statusBarWordCount != enabled) { m_statusBarWordCount = enabled; emit statusBarWordCountChanged(); }
}

bool ConfigManager::statusBarCharCount() const { return m_statusBarCharCount; }
void ConfigManager::setStatusBarCharCount(bool enabled)
{
    if (m_statusBarCharCount != enabled) { m_statusBarCharCount = enabled; emit statusBarCharCountChanged(); }
}

bool ConfigManager::statusBarLineCount() const { return m_statusBarLineCount; }
void ConfigManager::setStatusBarLineCount(bool enabled)
{
    if (m_statusBarLineCount != enabled) { m_statusBarLineCount = enabled; emit statusBarLineCountChanged(); }
}

bool ConfigManager::statusBarReadingTime() const { return m_statusBarReadingTime; }
void ConfigManager::setStatusBarReadingTime(bool enabled)
{
    if (m_statusBarReadingTime != enabled) { m_statusBarReadingTime = enabled; emit statusBarReadingTimeChanged(); }
}

bool ConfigManager::includeClaudeCodeFolder() const { return m_includeClaudeCodeFolder; }
void ConfigManager::setIncludeClaudeCodeFolder(bool enabled)
{
    if (m_includeClaudeCodeFolder != enabled) { m_includeClaudeCodeFolder = enabled; emit includeClaudeCodeFolderChanged(); }
}

QString ConfigManager::claudeCodeFolderPath() const
{
    return QDir::homePath() + QStringLiteral("/.claude");
}

int ConfigManager::zoomLevel() const { return m_zoomLevel; }

void ConfigManager::setZoomLevel(int level)
{
    level = qBound(50, level, 200);
    if (m_zoomLevel != level) {
        m_zoomLevel = level;
        emit zoomLevelChanged();
    }
}

int ConfigManager::splitLeftWidth() const { return m_splitLeftWidth; }

void ConfigManager::setSplitLeftWidth(int width)
{
    if (m_splitLeftWidth != width) {
        m_splitLeftWidth = width;
        emit splitLeftWidthChanged();
    }
}

int ConfigManager::splitRightWidth() const { return m_splitRightWidth; }

void ConfigManager::setSplitRightWidth(int width)
{
    if (m_splitRightWidth != width) {
        m_splitRightWidth = width;
        emit splitRightWidthChanged();
    }
}

bool ConfigManager::autoSaveEnabled() const { return m_autoSaveEnabled; }

void ConfigManager::setAutoSaveEnabled(bool enabled)
{
    if (m_autoSaveEnabled != enabled) {
        m_autoSaveEnabled = enabled;
        emit autoSaveEnabledChanged();
    }
}

int ConfigManager::autoSaveInterval() const { return m_autoSaveInterval; }

void ConfigManager::setAutoSaveInterval(int seconds)
{
    seconds = qBound(5, seconds, 600);
    if (m_autoSaveInterval != seconds) {
        m_autoSaveInterval = seconds;
        emit autoSaveIntervalChanged();
    }
}

QStringList ConfigManager::recentFiles() const { return m_recentFiles; }

void ConfigManager::setRecentFiles(const QStringList &files)
{
    if (m_recentFiles != files) {
        m_recentFiles = files;
        emit recentFilesChanged();
    }
}

void ConfigManager::addRecentFile(const QString &filePath)
{
    QStringList files = m_recentFiles;
    files.removeAll(filePath);
    files.prepend(filePath);
    while (files.size() > 10)
        files.removeLast();
    setRecentFiles(files);
}

bool ConfigManager::searchIncludeMarkdown() const { return m_searchIncludeMarkdown; }

void ConfigManager::setSearchIncludeMarkdown(bool enabled)
{
    if (m_searchIncludeMarkdown != enabled) {
        m_searchIncludeMarkdown = enabled;
        emit searchIncludeMarkdownChanged();
    }
}

bool ConfigManager::searchIncludeJson() const { return m_searchIncludeJson; }

void ConfigManager::setSearchIncludeJson(bool enabled)
{
    if (m_searchIncludeJson != enabled) {
        m_searchIncludeJson = enabled;
        emit searchIncludeJsonChanged();
    }
}

bool ConfigManager::searchIncludeYaml() const { return m_searchIncludeYaml; }

void ConfigManager::setSearchIncludeYaml(bool enabled)
{
    if (m_searchIncludeYaml != enabled) {
        m_searchIncludeYaml = enabled;
        emit searchIncludeYamlChanged();
    }
}

bool ConfigManager::searchIncludeJsonl() const { return m_searchIncludeJsonl; }

void ConfigManager::setSearchIncludeJsonl(bool enabled)
{
    if (m_searchIncludeJsonl != enabled) {
        m_searchIncludeJsonl = enabled;
        emit searchIncludeJsonlChanged();
    }
}

bool ConfigManager::searchIncludePlaintext() const { return m_searchIncludePlaintext; }

void ConfigManager::setSearchIncludePlaintext(bool enabled)
{
    if (m_searchIncludePlaintext != enabled) {
        m_searchIncludePlaintext = enabled;
        emit searchIncludePlaintextChanged();
    }
}

bool ConfigManager::searchIncludePdf() const { return m_searchIncludePdf; }

void ConfigManager::setSearchIncludePdf(bool enabled)
{
    if (m_searchIncludePdf != enabled) {
        m_searchIncludePdf = enabled;
        emit searchIncludePdfChanged();
    }
}

QString ConfigManager::themeMode() const { return m_themeMode; }

void ConfigManager::setThemeMode(const QString &mode)
{
    if (m_themeMode != mode) {
        m_themeMode = mode;
        emit themeModeChanged();
    }
}

QString ConfigManager::editorFontFamily() const { return m_editorFontFamily; }

void ConfigManager::setEditorFontFamily(const QString &family)
{
    if (m_editorFontFamily != family) {
        m_editorFontFamily = family;
        emit editorFontFamilyChanged();
    }
}

bool ConfigManager::wordWrap() const { return m_wordWrap; }

void ConfigManager::setWordWrap(bool enabled)
{
    if (m_wordWrap != enabled) {
        m_wordWrap = enabled;
        emit wordWrapChanged();
    }
}

void ConfigManager::load()
{
    QFile file(configFilePath());
    if (!file.open(QIODevice::ReadOnly))
        return;

    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &parseError);
    file.close();

    if (parseError.error != QJsonParseError::NoError || !doc.isObject())
        return;

    QJsonObject root = doc.object();

    if (root.contains("searchPaths")) {
        QStringList paths;
        for (const auto &v : root["searchPaths"].toArray())
            paths.append(v.toString());
        m_searchPaths = paths;
    }

    if (root.contains("ignorePatterns")) {
        QStringList patterns;
        for (const auto &v : root["ignorePatterns"].toArray())
            patterns.append(v.toString());
        m_ignorePatterns = patterns;
    }

    if (root.contains("triggerFiles")) {
        QStringList files;
        for (const auto &v : root["triggerFiles"].toArray())
            files.append(v.toString());
        m_triggerFiles = files;
    }

    if (root.contains("windowGeometry")) {
        m_windowGeometry = root["windowGeometry"].toObject().toVariantMap();
    }

    if (root.contains("splitterSizes")) {
        QList<int> sizes;
        for (const auto &v : root["splitterSizes"].toArray())
            sizes.append(v.toInt());
        m_splitterSizes = sizes;
    }

    if (root.contains("autoScanOnStartup"))
        m_autoScanOnStartup = root["autoScanOnStartup"].toBool(true);

    if (root.contains("syntaxHighlightEnabled"))
        m_syntaxHighlightEnabled = root["syntaxHighlightEnabled"].toBool(true);

    if (root.contains("scanDepth"))
        m_scanDepth = root["scanDepth"].toInt(0);

    if (root.contains("editorToolbarVisible"))
        m_editorToolbarVisible = root["editorToolbarVisible"].toBool(true);
    else if (root.contains("markdownToolbarVisible"))  // backward compat
        m_editorToolbarVisible = root["markdownToolbarVisible"].toBool(true);

    if (root.contains("imageSubfolder"))
        m_imageSubfolder = root["imageSubfolder"].toString("images");

    if (root.contains("statusBarWordCount"))
        m_statusBarWordCount = root["statusBarWordCount"].toBool(true);
    if (root.contains("statusBarCharCount"))
        m_statusBarCharCount = root["statusBarCharCount"].toBool(true);
    if (root.contains("statusBarLineCount"))
        m_statusBarLineCount = root["statusBarLineCount"].toBool(true);
    if (root.contains("statusBarReadingTime"))
        m_statusBarReadingTime = root["statusBarReadingTime"].toBool(true);

    if (root.contains("includeClaudeCodeFolder"))
        m_includeClaudeCodeFolder = root["includeClaudeCodeFolder"].toBool(false);

    if (root.contains("zoomLevel"))
        m_zoomLevel = qBound(50, root["zoomLevel"].toInt(100), 200);

    if (root.contains("splitLeftWidth"))
        m_splitLeftWidth = root["splitLeftWidth"].toInt(250);
    if (root.contains("splitRightWidth"))
        m_splitRightWidth = root["splitRightWidth"].toInt(280);

    if (root.contains("autoSaveEnabled"))
        m_autoSaveEnabled = root["autoSaveEnabled"].toBool(false);
    if (root.contains("autoSaveInterval"))
        m_autoSaveInterval = qBound(5, root["autoSaveInterval"].toInt(30), 600);

    if (root.contains("recentFiles")) {
        QStringList files;
        for (const auto &v : root["recentFiles"].toArray())
            files.append(v.toString());
        m_recentFiles = files;
    }

    if (root.contains("searchIncludeMarkdown"))
        m_searchIncludeMarkdown = root["searchIncludeMarkdown"].toBool(true);
    if (root.contains("searchIncludeJson"))
        m_searchIncludeJson = root["searchIncludeJson"].toBool(true);
    if (root.contains("searchIncludeYaml"))
        m_searchIncludeYaml = root["searchIncludeYaml"].toBool(true);
    if (root.contains("searchIncludeJsonl"))
        m_searchIncludeJsonl = root["searchIncludeJsonl"].toBool(false);
    if (root.contains("searchIncludePlaintext"))
        m_searchIncludePlaintext = root["searchIncludePlaintext"].toBool(true);
    if (root.contains("searchIncludePdf"))
        m_searchIncludePdf = root["searchIncludePdf"].toBool(false);

    if (root.contains("themeMode"))
        m_themeMode = root["themeMode"].toString("dark");
    if (root.contains("editorFontFamily"))
        m_editorFontFamily = root["editorFontFamily"].toString("Consolas");
    if (root.contains("wordWrap"))
        m_wordWrap = root["wordWrap"].toBool(true);
}

void ConfigManager::save()
{
    QDir dir(configDir());
    if (!dir.exists())
        dir.mkpath(".");

    QJsonObject root;

    QJsonArray pathsArr;
    for (const auto &p : m_searchPaths)
        pathsArr.append(p);
    root["searchPaths"] = pathsArr;

    QJsonArray patternsArr;
    for (const auto &p : m_ignorePatterns)
        patternsArr.append(p);
    root["ignorePatterns"] = patternsArr;

    QJsonArray triggerArr;
    for (const auto &f : m_triggerFiles)
        triggerArr.append(f);
    root["triggerFiles"] = triggerArr;

    root["windowGeometry"] = QJsonObject::fromVariantMap(m_windowGeometry);

    QJsonArray splitterArr;
    for (int s : m_splitterSizes)
        splitterArr.append(s);
    root["splitterSizes"] = splitterArr;

    root["autoScanOnStartup"] = m_autoScanOnStartup;
    root["syntaxHighlightEnabled"] = m_syntaxHighlightEnabled;
    root["scanDepth"] = m_scanDepth;
    root["editorToolbarVisible"] = m_editorToolbarVisible;
    root["imageSubfolder"] = m_imageSubfolder;
    root["statusBarWordCount"] = m_statusBarWordCount;
    root["statusBarCharCount"] = m_statusBarCharCount;
    root["statusBarLineCount"] = m_statusBarLineCount;
    root["statusBarReadingTime"] = m_statusBarReadingTime;
    root["includeClaudeCodeFolder"] = m_includeClaudeCodeFolder;
    root["zoomLevel"] = m_zoomLevel;
    root["splitLeftWidth"] = m_splitLeftWidth;
    root["splitRightWidth"] = m_splitRightWidth;
    root["autoSaveEnabled"] = m_autoSaveEnabled;
    root["autoSaveInterval"] = m_autoSaveInterval;

    QJsonArray recentArr;
    for (const auto &f : m_recentFiles)
        recentArr.append(f);
    root["recentFiles"] = recentArr;

    root["searchIncludeMarkdown"] = m_searchIncludeMarkdown;
    root["searchIncludeJson"] = m_searchIncludeJson;
    root["searchIncludeYaml"] = m_searchIncludeYaml;
    root["searchIncludeJsonl"] = m_searchIncludeJsonl;
    root["searchIncludePlaintext"] = m_searchIncludePlaintext;
    root["searchIncludePdf"] = m_searchIncludePdf;

    root["themeMode"] = m_themeMode;
    root["editorFontFamily"] = m_editorFontFamily;
    root["wordWrap"] = m_wordWrap;

    QFile file(configFilePath());
    if (!file.open(QIODevice::WriteOnly)) {
        qWarning("ConfigManager: Could not write %s", qPrintable(configFilePath()));
        emit saveFailed(tr("Could not save configuration"));
        return;
    }

    file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
    file.close();
}
