import QtQuick
import QtWebEngine
import QtWebChannel
import BlockSmith

WebEngineView {
    id: previewWeb

    property string markdown: ""
    property ScrollBridge scrollBridge: ScrollBridge {
        id: scrollBridgeObj
        objectName: "scrollBridge"
        WebChannel.id: "scrollBridge"
    }

    backgroundColor: Theme.bg
    url: "qrc:/preview/index.html"

    zoomFactor: AppController.configManager.zoomLevel / 100.0

    webChannel: WebChannel {
        id: previewChannel
        registeredObjects: [scrollBridgeObj]
    }

    // Security: lock down the embedded browser
    settings.localContentCanAccessRemoteUrls: false
    settings.localContentCanAccessFileUrls: true
    settings.javascriptEnabled: true
    settings.javascriptCanAccessClipboard: false
    settings.localStorageEnabled: false
    settings.pluginsEnabled: false

    // Intercept link clicks — open in system browser
    onNavigationRequested: function(request) {
        if (request.navigationType === WebEngineNavigationRequest.LinkClickedNavigation) {
            Qt.openUrlExternally(request.url)
            request.reject()
        }
    }

    // Track page readiness
    property bool _pageReady: false
    onLoadingChanged: function(info) {
        if (info.status === WebEngineView.LoadSucceededStatus) {
            _pageReady = true
            pushContent()
        }
    }

    onMarkdownChanged: previewTimer.restart()

    Timer {
        id: previewTimer
        interval: 200
        onTriggered: previewWeb.pushContent()
    }

    function pushContent() {
        if (!_pageReady) return
        let html = AppController.md4cRenderer.renderWithLineMap(markdown)

        // Resolve relative image paths to absolute file:// URLs
        let docPath = AppController.currentDocument.filePath
        if (docPath) {
            let dir = AppController.imageHandler.getDocumentDir(docPath)
            let fileUrl = "file:///" + dir.replace(/\\/g, "/") + "/"
            // Match src="..." that aren't already absolute (http, file, data)
            html = html.replace(/src="(?!https?:\/\/|file:\/\/|data:)([^"]+)"/g,
                               'src="' + fileUrl + '$1"')
        }

        runJavaScript("updateContent(" + JSON.stringify(html) + ")")
    }

    function scrollToPercent(pct) {
        if (!_pageReady) return
        runJavaScript("scrollToPercent(" + pct + ")")
    }

    function scrollToLine(lineNum) {
        if (!_pageReady) return
        runJavaScript("scrollToLine(" + lineNum + ")")
    }
}
