import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import BlockSmith

Dialog {
    id: dialog

    parent: Overlay.overlay
    anchors.centerIn: parent
    width: 500
    height: 340

    modal: true
    title: "Export Document"
    standardButtons: Dialog.Cancel
    palette.accent: Theme.accent
    palette.highlight: Theme.accent

    property bool exporting: false
    property string selectedFormat: "pdf"
    property bool pandocAvailable: false
    signal notify(string message)

    function openDialog() {
        if (!AppController.currentDocument.filePath) return

        pandocAvailable = AppController.exportManager.isPandocAvailable()
        selectedFormat = "pdf"
        errorLabel.text = ""
        exporting = false
        updateOutputPath()
        dialog.open()
    }

    function updateOutputPath() {
        let ext = selectedFormat
        outputField.text = AppController.exportManager.defaultExportPath(
            AppController.currentDocument.filePath, ext)
    }

    // Connect export signals
    Connections {
        target: AppController.exportManager
        function onExportComplete(outputPath) {
            dialog.exporting = false
            dialog.close()
            dialog.notify("Exported to " + outputPath)
            if (openAfterCheck.checked)
                Qt.openUrlExternally("file:///" + outputPath.replace(/\\/g, "/"))
        }
        function onExportError(message) {
            dialog.exporting = false
            errorLabel.text = message
        }
    }

    FileDialog {
        id: saveDialog
        fileMode: FileDialog.SaveFile
        nameFilters: {
            if (selectedFormat === "pdf") return ["PDF files (*.pdf)"]
            if (selectedFormat === "html") return ["HTML files (*.html)"]
            if (selectedFormat === "docx") return ["Word documents (*.docx)"]
            return ["All files (*)"]
        }
        onAccepted: {
            let path = selectedFile.toString()
            if (Qt.platform.os === "windows")
                path = path.replace(/^file:\/\/\//, "")
            else
                path = path.replace(/^file:\/\//, "")
            outputField.text = decodeURIComponent(path)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.sp12

        // Format selection
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.sp4

            Label {
                text: "Format"
                font.pixelSize: Theme.fontSizeM
                font.bold: true
                color: Theme.textSecondary
            }

            RowLayout {
                spacing: Theme.sp16

                ButtonGroup { id: formatGroup }

                RadioButton {
                    text: "PDF"
                    ButtonGroup.group: formatGroup
                    checked: selectedFormat === "pdf"
                    enabled: !dialog.exporting
                    onClicked: { selectedFormat = "pdf"; updateOutputPath() }
                    palette.windowText: Theme.textPrimary
                }
                RadioButton {
                    text: "HTML"
                    ButtonGroup.group: formatGroup
                    checked: selectedFormat === "html"
                    enabled: !dialog.exporting
                    onClicked: { selectedFormat = "html"; updateOutputPath() }
                    palette.windowText: Theme.textPrimary
                }
                RadioButton {
                    text: "DOCX"
                    ButtonGroup.group: formatGroup
                    checked: selectedFormat === "docx"
                    enabled: !dialog.exporting && pandocAvailable
                    onClicked: { selectedFormat = "docx"; updateOutputPath() }
                    palette.windowText: pandocAvailable ? Theme.textPrimary : Theme.textMuted
                }

                Label {
                    visible: !pandocAvailable
                    text: "(pandoc not found)"
                    font.pixelSize: Theme.fontSizeXS
                    color: Theme.textMuted
                }
            }
        }

        // Output path
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.sp4

            Label {
                text: "Output"
                font.pixelSize: Theme.fontSizeM
                font.bold: true
                color: Theme.textSecondary
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.sp8

                TextField {
                    id: outputField
                    Layout.fillWidth: true
                    font.pixelSize: Theme.fontSizeM
                    color: Theme.textPrimary
                    placeholderText: "Output file path..."
                    placeholderTextColor: Theme.textPlaceholder
                    enabled: !dialog.exporting
                    background: Rectangle {
                        color: Theme.bg
                        radius: Theme.radius
                        border.color: outputField.activeFocus ? Theme.borderFocus : Theme.border
                        border.width: 1
                    }
                }

                Button {
                    text: "..."
                    flat: true
                    enabled: !dialog.exporting
                    implicitWidth: 36
                    palette.buttonText: Theme.textPrimary
                    background: Rectangle {
                        color: parent.hovered ? Theme.bgButtonHov : Theme.bgButton
                        radius: Theme.radius
                        border.color: Theme.borderHover
                        border.width: 1
                    }
                    onClicked: saveDialog.open()
                }
            }
        }

        // Options
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.sp16

            CheckBox {
                id: lightBgCheck
                text: "Light background (print-friendly)"
                checked: true
                enabled: !dialog.exporting && selectedFormat !== "docx"
                palette.windowText: Theme.textPrimary
            }

            Label {
                text: "Font size:"
                font.pixelSize: Theme.fontSizeM
                color: selectedFormat === "docx" ? Theme.textMuted : Theme.textSecondary
            }

            ComboBox {
                id: fontSizeCombo
                model: ["Small", "Medium", "Large"]
                currentIndex: 1
                enabled: !dialog.exporting && selectedFormat !== "docx"
                implicitWidth: 100
                palette.buttonText: Theme.textPrimary
                palette.window: Theme.bgPanel
                palette.button: Theme.bgButton
                palette.highlight: Theme.accent
            }
        }

        CheckBox {
            id: openAfterCheck
            text: "Open file after export"
            checked: true
            enabled: !dialog.exporting
            palette.windowText: Theme.textPrimary
        }

        // Error label
        Label {
            id: errorLabel
            Layout.fillWidth: true
            color: Theme.accentRed
            font.pixelSize: Theme.fontSizeXS
            wrapMode: Text.Wrap
            visible: text.length > 0
        }

        // Progress
        RowLayout {
            Layout.fillWidth: true
            visible: dialog.exporting
            spacing: Theme.sp8

            BusyIndicator {
                running: dialog.exporting
                implicitWidth: 20
                implicitHeight: 20
            }
            Label {
                text: "Exporting..."
                font.pixelSize: Theme.fontSizeM
                color: Theme.textSecondary
            }
        }

        // Spacer + Export button
        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.sp8

            Item { Layout.fillWidth: true }

            Button {
                text: "Export"
                highlighted: true
                enabled: !dialog.exporting && outputField.text.length > 0
                onClicked: {
                    errorLabel.text = ""
                    dialog.exporting = true

                    let md = AppController.currentDocument.rawContent
                    let docDir = AppController.imageHandler.getDocumentDir(
                        AppController.currentDocument.filePath)
                    let out = outputField.text

                    let fs = fontSizeCombo.currentText.toLowerCase()

                    if (selectedFormat === "pdf") {
                        AppController.exportManager.exportPdf(md, out, docDir, lightBgCheck.checked, fs)
                    } else if (selectedFormat === "html") {
                        AppController.exportManager.exportHtml(md, out, docDir, lightBgCheck.checked, fs)
                    } else if (selectedFormat === "docx") {
                        AppController.exportManager.exportDocx(
                            AppController.currentDocument.filePath, out)
                    }
                }
            }
        }
    }
}
