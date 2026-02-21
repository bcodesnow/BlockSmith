#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QIcon>
#include <QLocale>
#include <QtWebEngineQuick/qtwebenginequickglobal.h>

#ifdef Q_OS_WIN
#include <dwmapi.h>
#endif

int main(int argc, char *argv[])
{
    QtWebEngineQuick::initialize();

    // Force English UI so Qt Dialog buttons show "Cancel"/"Save" instead of
    // translations from the system locale (e.g. German "Abbrechen"/"Speichern").
    QLocale::setDefault(QLocale(QLocale::English, QLocale::UnitedStates));

    QGuiApplication app(argc, argv);
    app.setApplicationName("BlockSmith");
    app.setOrganizationName("BlockSmith");
    QIcon appIcon;
    for (int size : {16, 24, 32, 48, 64, 96, 128, 256, 512})
        appIcon.addFile(QString(":/resources/icons/blocksmith_%1.png").arg(size), QSize(size, size));
    app.setWindowIcon(appIcon);

    QQuickStyle::setStyle("Fusion");

    QQmlApplicationEngine engine;

    // On window creation: cloak it so DWM doesn't flash a white frame,
    // show it (scene graph renders while cloaked), uncloak on first frame.
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated, &app,
        [](QObject *obj, const QUrl &) {
            auto *window = qobject_cast<QQuickWindow *>(obj);
            if (!window) return;
#ifdef Q_OS_WIN
            auto hwnd = reinterpret_cast<HWND>(window->winId());
            BOOL cloak = TRUE;
            DwmSetWindowAttribute(hwnd, DWMWA_CLOAK, &cloak, sizeof(cloak));

            window->show();

            QObject::connect(window, &QQuickWindow::frameSwapped, window, [hwnd]() {
                BOOL uncloak = FALSE;
                DwmSetWindowAttribute(hwnd, DWMWA_CLOAK, &uncloak, sizeof(uncloak));
            }, Qt::SingleShotConnection);
#else
            window->show();
#endif
        });

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("BlockSmith", "Main");

    return app.exec();
}
