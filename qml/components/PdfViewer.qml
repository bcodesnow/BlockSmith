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
        target: AppController.currentDocument
        function onFilePathChanged() {
            pdfView.loadPdf()
        }
    }

    Component.onCompleted: loadPdf()

    function loadPdf() {
        let fp = AppController.currentDocument.filePath
        if (fp && AppController.currentDocument.fileType === Document.Pdf) {
            let fileUrl = "file:///" + fp.replace(/\\/g, "/")
            url = fileUrl
        }
    }
}
