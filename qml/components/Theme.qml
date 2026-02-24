pragma Singleton
import QtQuick
import BlockSmith

QtObject {
    // Backgrounds
    readonly property color bg:          "#1e1e1e"
    readonly property color bgPanel:     "#2b2b2b"
    readonly property color bgHeader:    "#333333"
    readonly property color bgGutter:    "#1a1a1a"
    readonly property color bgButton:    "#3a3a3a"
    readonly property color bgButtonHov: "#555"
    readonly property color bgButtonPrs: "#666"
    readonly property color bgCard:      "#2f2f2f"
    readonly property color bgCardHov:   "#383838"
    readonly property color bgSelection: "#264f78"
    readonly property color bgActive:    "#3d6a99"
    readonly property color bgFooter:    "#252525"

    // Borders & Separators
    readonly property color border:      "#444"
    readonly property color borderHover: "#555"
    readonly property color borderFocus: "#6c9bd2"

    // Text
    readonly property color textPrimary:   "#ddd"
    readonly property color textSecondary: "#aaa"
    readonly property color textMuted:     "#888"
    readonly property color textDisabled:  "#666"
    readonly property color textEditor:    "#d4d4d4"
    readonly property color textWhite:     "#fff"
    readonly property color textBright:      "#eee"
    readonly property color textPlaceholder: "#666"

    // Cursor
    readonly property color cursorColor:  "#d4d4d4"
    readonly property real  cursorWidth:  2

    // Accent
    readonly property color accent:       "#6c9bd2"
    readonly property color accentGreen:  "#4caf50"
    readonly property color accentGreenLight: "#a5d6a7"
    readonly property color accentGold:   "#e0c060"
    readonly property color accentOrange: "#ff9800"
    readonly property color accentRed:    "#e06060"
    readonly property color accentPurple: "#8888cc"

    // Semantic: tags, diffs, categories
    readonly property color tagBg:              "#3d5a80"
    readonly property color highlightItemBg:    "#2a3a2a"
    readonly property color diffRegistryBg:     "#1a2530"
    readonly property color diffRegistryBorder: "#3d5a80"
    readonly property color diffFileBg:         "#2a2010"
    readonly property color diffFileBorder:     "#806020"
    readonly property color categoryAudit:      "#5a3d3d"
    readonly property color categoryReview:     "#3d5a3d"
    readonly property color categoryDebug:      "#5a4d3d"
    readonly property color categoryGenerate:   "#3d3d5a"
    readonly property color categoryDefault:    "#4a4a4a"

    // Fonts
    readonly property string fontMono: "Consolas"
    readonly property int fontSizeS:  10
    readonly property int fontSizeM:  12
    readonly property int fontSizeL:  13
    readonly property int fontSizeXS: 11   // header labels, descriptions

    // Zoom
    readonly property real zoomFactor: AppController.configManager.zoomLevel / 100.0
    readonly property real fontSizeLZoomed: Math.round(fontSizeL * zoomFactor)

    // Spacing
    readonly property int sp4:  4
    readonly property int sp8:  8
    readonly property int sp12: 12
    readonly property int sp16: 16

    // Sizes
    readonly property int headerHeight: 36
    readonly property int radius: 3

    // Role badge color (shared across JsonlViewer, JsonlEntryCard)
    function roleColor(role) {
        switch (role) {
        case "user":       return accent
        case "assistant":  return accentGreen
        case "system":     return accentGold
        case "tool":       return accentPurple
        case "progress":   return textMuted
        case "error":      return accentRed
        default:           return textSecondary
        }
    }

    // Preview CSS (shared across MdPreview, BlockEditorPopup, PromptEditorPopup)
    readonly property string previewCss:
        "<style>"
        + "body { color: #d4d4d4; font-family: Segoe UI, sans-serif; font-size: 13px; }"
        + "h1, h2, h3, h4 { color: #e0e0e0; margin-top: 12px; }"
        + "code { background: #333; padding: 2px 4px; font-family: Consolas; border-radius: 3px; font-size: 12px; }"
        + "pre { background: #2a2a2a; padding: 10px; border-radius: 4px; margin: 8px 0; }"
        + "pre code { background: transparent; padding: 0; }"
        + "a { color: #6c9bd2; }"
        + "blockquote { border-left: 3px solid #555; padding-left: 8px; color: #aaa; margin: 8px 0; }"
        + "table { border-collapse: collapse; margin: 8px 0; width: 100%; }"
        + "th, td { border: 1px solid #555; padding: 6px 10px; text-align: left; }"
        + "th { background: #333; color: #e0e0e0; font-weight: bold; }"
        + "tr:nth-child(even) { background: #2a2a2a; }"
        + "hr { border: none; border-top: 1px solid #555; margin: 16px 0; }"
        + "img { max-width: 100%; height: auto; border-radius: 4px; }"
        + "ul, ol { padding-left: 24px; margin: 6px 0; }"
        + "li { margin: 3px 0; }"
        + "</style>"
}
