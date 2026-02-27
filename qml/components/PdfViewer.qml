import QtQuick
import QtWebEngine
import BlockSmith

WebEngineView {
    id: pdfView

    backgroundColor: Theme.bg
    zoomFactor: AppController.configManager.zoomLevel / 100.0

    settings.localContentCanAccessRemoteUrls: false
    settings.localContentCanAccessFileUrls: true
    settings.javascriptEnabled: true
    settings.localStorageEnabled: false
    settings.focusOnNavigationEnabled: false

    Connections {
        target: AppController
        function onCurrentDocumentChanged() {
            pdfView.loadPdf()
        }
    }

    Component.onCompleted: loadPdf()

    function loadPdf() {
        let doc = AppController.currentDocument
        if (!doc) return
        let fp = doc.filePath
        if (fp && doc.fileType === Document.Pdf) {
            let fileUrl = "file:///" + fp.replace(/\\/g, "/")
            url = fileUrl
        }
    }
}
