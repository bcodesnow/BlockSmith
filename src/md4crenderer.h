#pragma once

#include <QObject>
#include <QString>
#include <QtQml/qqmlregistration.h>

class Md4cRenderer : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit Md4cRenderer(QObject *parent = nullptr);

    Q_INVOKABLE QString render(const QString &markdown) const;
    Q_INVOKABLE QString renderWithLineMap(const QString &markdown) const;
};
