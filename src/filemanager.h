#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>

class Document;
class ConfigManager;

class FileManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Use via AppController.fileManager")

public:
    explicit FileManager(Document *document, ConfigManager *config,
                         QObject *parent = nullptr);

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

    Document *m_document = nullptr;
    ConfigManager *m_config = nullptr;
};
