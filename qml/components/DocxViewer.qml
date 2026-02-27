import QtQuick
import QtWebEngine
import BlockSmith

WebEngineView {
    id: docxView

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
            docxView.convertAndLoad()
        }
    }

    Connections {
        target: AppController.exportManager
        function onDocxHtmlReady(html) {
            docxView.loadHtml(html)
        }
        function onDocxConvertError(message) {
            let errorHtml = "<html><body style='background:" + Theme.bg
                + ";color:" + Theme.text
                + ";font-family:Segoe UI,sans-serif;padding:40px;'>"
                + "<h2>Cannot display DOCX</h2>"
                + "<p>" + message + "</p></body></html>"
            docxView.loadHtml(errorHtml)
        }
    }

    Component.onCompleted: convertAndLoad()

    function convertAndLoad() {
        let doc = AppController.currentDocument
        if (!doc) return
        let fp = doc.filePath
        if (fp && doc.fileType === Document.Docx) {
            AppController.exportManager.convertDocxToHtml(fp)
        }
    }
}
