#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QIcon>
#include <QtWebEngineQuick/qtwebenginequickglobal.h>

int main(int argc, char *argv[])
{
    QtWebEngineQuick::initialize();
    QGuiApplication app(argc, argv);
    app.setApplicationName("BlockSmith");
    app.setOrganizationName("BlockSmith");
    QIcon appIcon;
    for (int size : {16, 24, 32, 48, 64, 96, 128, 256, 512})
        appIcon.addFile(QString(":/resources/icons/blocksmith_%1.png").arg(size), QSize(size, size));
    app.setWindowIcon(appIcon);

    QQuickStyle::setStyle("Fusion");

    QQmlApplicationEngine engine;

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("BlockSmith", "Main");

    return app.exec();
}
