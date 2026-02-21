#include "scrollbridge.h"

ScrollBridge::ScrollBridge(QObject *parent) : QObject(parent) {}

void ScrollBridge::onPreviewScroll(double scrollPercent)
{
    emit previewScrolled(scrollPercent);
}

void ScrollBridge::onHeadingClicked(int sourceLine, const QString &text)
{
    emit headingClicked(sourceLine, text);
}
