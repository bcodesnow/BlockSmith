#include "imagehandler.h"

#include <QClipboard>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QImage>
#include <QMimeData>

static const QStringList imageExtensions = {
    "png", "jpg", "jpeg", "gif", "svg", "webp", "bmp"
};

ImageHandler::ImageHandler(QObject *parent)
    : QObject(parent)
{
}

bool ImageHandler::clipboardHasImage() const
{
    const QMimeData *mime = QGuiApplication::clipboard()->mimeData();
    return mime && mime->hasImage();
}

QString ImageHandler::saveClipboardImage(const QString &destDir, const QString &fileName)
{
    const QMimeData *mime = QGuiApplication::clipboard()->mimeData();
    if (!mime || !mime->hasImage()) {
        emit imageError("No image in clipboard");
        return {};
    }

    QImage image = qvariant_cast<QImage>(mime->imageData());
    if (image.isNull()) {
        emit imageError("Could not read clipboard image");
        return {};
    }

    QDir dir(destDir);
    if (!dir.exists() && !dir.mkpath(".")) {
        emit imageError("Could not create directory: " + destDir);
        return {};
    }

    QString path = destDir + "/" + fileName + ".png";

    // Avoid overwriting
    if (QFileInfo::exists(path)) {
        int counter = 1;
        while (QFileInfo::exists(destDir + "/" + fileName + "-" + QString::number(counter) + ".png"))
            counter++;
        path = destDir + "/" + fileName + "-" + QString::number(counter) + ".png";
    }

    if (!image.save(path, "PNG")) {
        emit imageError("Failed to save image");
        return {};
    }

    emit imageSaved(path);
    return path;
}

QString ImageHandler::copyImageFile(const QString &sourcePath, const QString &destDir)
{
    QFileInfo srcInfo(sourcePath);
    if (!srcInfo.exists() || !srcInfo.isFile()) {
        emit imageError("Source file not found");
        return {};
    }

    if (!isImageFile(sourcePath)) {
        emit imageError("Not a supported image format");
        return {};
    }

    QDir dir(destDir);
    if (!dir.exists() && !dir.mkpath(".")) {
        emit imageError("Could not create directory: " + destDir);
        return {};
    }

    QString destPath = destDir + "/" + srcInfo.fileName();

    // Skip copy if source is already in destination
    if (QFileInfo(sourcePath).absoluteFilePath() == QFileInfo(destPath).absoluteFilePath())
        return destPath;

    // Avoid overwriting
    if (QFileInfo::exists(destPath)) {
        QString baseName = srcInfo.completeBaseName();
        QString suffix = srcInfo.suffix();
        int counter = 1;
        while (QFileInfo::exists(destDir + "/" + baseName + "-" + QString::number(counter) + "." + suffix))
            counter++;
        destPath = destDir + "/" + baseName + "-" + QString::number(counter) + "." + suffix;
    }

    if (!QFile::copy(sourcePath, destPath)) {
        emit imageError("Failed to copy image");
        return {};
    }

    emit imageSaved(destPath);
    return destPath;
}

QString ImageHandler::generateImageName() const
{
    return "img-" + QDateTime::currentDateTime().toString("yyyyMMdd-HHmmss");
}

QString ImageHandler::getDocumentDir(const QString &filePath) const
{
    return QFileInfo(filePath).absolutePath();
}

QString ImageHandler::fileNameOf(const QString &path) const
{
    return QFileInfo(path).fileName();
}

bool ImageHandler::isImageFile(const QString &path) const
{
    QString suffix = QFileInfo(path).suffix().toLower();
    return imageExtensions.contains(suffix);
}
