#include "configmanager.h"

#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QStandardPaths>

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

    QFile file(configFilePath());
    if (!file.open(QIODevice::WriteOnly)) {
        qWarning("ConfigManager: Could not write %s", qPrintable(configFilePath()));
        return;
    }

    file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
    file.close();
}
