#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>

class Document;
class ConfigManager;
class TabModel;

class FileManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Use via AppController.fileManager")

public:
    explicit FileManager(ConfigManager *config, QObject *parent = nullptr);

    void setTabModel(TabModel *model);

    Q_INVOKABLE QString createFile(const QString &parentDir, const QString &fileName);
    Q_INVOKABLE QString createFolder(const QString &parentDir, const QString &folderName);
    Q_INVOKABLE QString renameItem(const QString &oldPath, const QString &newName);
    Q_INVOKABLE QString moveItem(const QString &sourcePath, const QString &destDir);
    Q_INVOKABLE QString deleteItem(const QString &path);
    Q_INVOKABLE QString duplicateFile(const QString &sourcePath);

signals:
    void fileOperationComplete();

private:
    bool isProjectRoot(const QString &path) const;
    bool isSamePath(const QString &a, const QString &b) const;
    bool isPathInside(const QString &path, const QString &directoryPath) const;
    QString remapPathPrefix(const QString &path, const QString &oldPrefix, const QString &newPrefix) const;
    void repointOpenDocuments(const QString &oldPath, const QString &newPath, bool sourceIsDirectory);
    void clearOpenDocumentsForDeletedPath(const QString &deletedPath, bool isDirectory);

    ConfigManager *m_config = nullptr;
    TabModel *m_tabModel = nullptr;
};
