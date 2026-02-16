#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>

class ImageHandler : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit ImageHandler(QObject *parent = nullptr);

    Q_INVOKABLE bool clipboardHasImage() const;
    Q_INVOKABLE QString saveClipboardImage(const QString &destDir, const QString &fileName);
    Q_INVOKABLE QString copyImageFile(const QString &sourcePath, const QString &destDir);
    Q_INVOKABLE QString generateImageName() const;
    Q_INVOKABLE QString getDocumentDir(const QString &filePath) const;
    Q_INVOKABLE QString fileNameOf(const QString &path) const;
    Q_INVOKABLE bool isImageFile(const QString &path) const;

signals:
    void imageSaved(const QString &relativePath);
    void imageError(const QString &error);
};
