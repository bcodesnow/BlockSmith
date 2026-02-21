#pragma once
#include <QObject>
#include <QtQml/qqmlregistration.h>

class ScrollBridge : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit ScrollBridge(QObject *parent = nullptr);

    // Called from JavaScript via WebChannel
    Q_INVOKABLE void onPreviewScroll(double scrollPercent);
    Q_INVOKABLE void onHeadingClicked(int sourceLine, const QString &text);

signals:
    void previewScrolled(double percent);
    void headingClicked(int sourceLine, QString text);
};
