pragma Singleton
import QtQuick
import BlockSmith

QtObject {
    readonly property bool isDark: AppController.configManager.themeMode === "dark"

    // Backgrounds
    readonly property color bg:          isDark ? "#1e1e1e" : "#f5f5f5"
    readonly property color bgPanel:     isDark ? "#2b2b2b" : "#e8e8e8"
    readonly property color bgHeader:    isDark ? "#333333" : "#e0e0e0"
    readonly property color bgGutter:    isDark ? "#1a1a1a" : "#ebebeb"
    readonly property color bgButton:    isDark ? "#3a3a3a" : "#d5d5d5"
    readonly property color bgButtonHov: isDark ? "#555" : "#c0c0c0"
    readonly property color bgButtonPrs: isDark ? "#666" : "#b0b0b0"
    readonly property color bgCard:      isDark ? "#2f2f2f" : "#ffffff"
    readonly property color bgCardHov:   isDark ? "#383838" : "#f0f0f0"
    readonly property color bgSelection: isDark ? "#264f78" : "#add6ff"
    readonly property color bgActive:    isDark ? "#3d6a99" : "#0078d4"
    readonly property color bgFooter:    isDark ? "#252525" : "#e5e5e5"

    // Borders & Separators
    readonly property color border:      isDark ? "#444" : "#ccc"
    readonly property color borderHover: isDark ? "#555" : "#aaa"
    readonly property color borderFocus: isDark ? "#6c9bd2" : "#0078d4"

    // Text
    readonly property color textPrimary:     isDark ? "#ddd" : "#1e1e1e"
    readonly property color textSecondary:   isDark ? "#aaa" : "#555"
    readonly property color textMuted:       isDark ? "#888" : "#777"
    readonly property color textDisabled:    isDark ? "#666" : "#bbb"
    readonly property color textEditor:      isDark ? "#d4d4d4" : "#1e1e1e"
    readonly property color textWhite:       "#fff"
    readonly property color textBright:      isDark ? "#eee" : "#111"
    readonly property color textPlaceholder: isDark ? "#666" : "#aaa"

    // Cursor
    readonly property color cursorColor: isDark ? "#d4d4d4" : "#1e1e1e"
    readonly property real  cursorWidth: 2

    // Accent
    readonly property color accent:           isDark ? "#6c9bd2" : "#0078d4"
    readonly property color accentGreen:      isDark ? "#4caf50" : "#2e7d32"
    readonly property color accentGreenLight: isDark ? "#a5d6a7" : "#66bb6a"
    readonly property color accentGold:       isDark ? "#e0c060" : "#f9a825"
    readonly property color accentOrange:     isDark ? "#ff9800" : "#e65100"
    readonly property color accentRed:        isDark ? "#e06060" : "#c62828"
    readonly property color accentPurple:     isDark ? "#8888cc" : "#6a1b9a"

    // Semantic: tags, diffs, categories
    readonly property color tagBg:              isDark ? "#3d5a80" : "#bbdefb"
    readonly property color highlightItemBg:    isDark ? "#2a3a2a" : "#e8f5e9"
    readonly property color diffRegistryBg:     isDark ? "#1a2530" : "#e3f2fd"
    readonly property color diffRegistryBorder: isDark ? "#3d5a80" : "#90caf9"
    readonly property color diffFileBg:         isDark ? "#2a2010" : "#fff8e1"
    readonly property color diffFileBorder:     isDark ? "#806020" : "#ffcc02"
    readonly property color diffAddedBg:        isDark ? "#1a3320" : "#c8e6c9"
    readonly property color diffRemovedBg:      isDark ? "#3d1a1a" : "#ffcdd2"
    readonly property color categoryAudit:      isDark ? "#5a3d3d" : "#ffcdd2"
    readonly property color categoryReview:     isDark ? "#3d5a3d" : "#c8e6c9"
    readonly property color categoryDebug:      isDark ? "#5a4d3d" : "#ffe0b2"
    readonly property color categoryGenerate:   isDark ? "#3d3d5a" : "#d1c4e9"
    readonly property color categoryDefault:    isDark ? "#4a4a4a" : "#e0e0e0"

    // Fonts
    readonly property string fontMono: AppController.configManager.editorFontFamily || "Consolas"
    readonly property int fontSizeS:  10
    readonly property int fontSizeM:  12
    readonly property int fontSizeL:  13
    readonly property int fontSizeXS: 11

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
        + "body { color: " + (isDark ? "#d4d4d4" : "#1e1e1e") + "; font-family: Segoe UI, sans-serif; font-size: 13px; }"
        + "h1, h2, h3, h4 { color: " + (isDark ? "#e0e0e0" : "#1e1e1e") + "; margin-top: 12px; }"
        + "code { background: " + (isDark ? "#333" : "#eff1f3") + "; padding: 2px 4px; font-family: " + fontMono + "; border-radius: 3px; font-size: 12px; }"
        + "pre { background: " + (isDark ? "#2a2a2a" : "#f6f8fa") + "; padding: 10px; border-radius: 4px; margin: 8px 0; }"
        + "pre code { background: transparent; padding: 0; }"
        + "a { color: " + (isDark ? "#6c9bd2" : "#0969da") + "; }"
        + "blockquote { border-left: 3px solid " + (isDark ? "#555" : "#d0d7de") + "; padding-left: 8px; color: " + (isDark ? "#aaa" : "#57606a") + "; margin: 8px 0; }"
        + "table { border-collapse: collapse; margin: 8px 0; width: 100%; }"
        + "th, td { border: 1px solid " + (isDark ? "#555" : "#d0d7de") + "; padding: 6px 10px; text-align: left; }"
        + "th { background: " + (isDark ? "#333" : "#f6f8fa") + "; color: " + (isDark ? "#e0e0e0" : "#1e1e1e") + "; font-weight: bold; }"
        + "tr:nth-child(even) { background: " + (isDark ? "#2a2a2a" : "#f6f8fa") + "; }"
        + "hr { border: none; border-top: 1px solid " + (isDark ? "#555" : "#d0d7de") + "; margin: 16px 0; }"
        + "img { max-width: 100%; height: auto; border-radius: 4px; }"
        + "ul, ol { padding-left: 24px; margin: 6px 0; }"
        + "li { margin: 3px 0; }"
        + "</style>"
}
