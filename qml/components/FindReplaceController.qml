import QtQuick
import BlockSmith

QtObject {
    id: ctrl

    required property var editor       // Editor component (has .textArea, .ensureVisible)
    required property var bar          // FindReplaceBar component (has .matchCount, .currentMatch)

    property var matches: []
    property int matchIndex: -1

    function performFind(text, caseSensitive, direction) {
        if (text.length === 0) {
            matches = []
            matchIndex = -1
            bar.matchCount = 0
            bar.currentMatch = 0
            return
        }

        let found = AppController.currentDocument.findMatches(text, caseSensitive)
        matches = found
        bar.matchCount = found.length

        if (found.length === 0) {
            matchIndex = -1
            bar.currentMatch = 0
            return
        }

        let cursorPos = editor.textArea.cursorPosition
        let bestIdx = 0

        if (direction === "next") {
            for (let i = 0; i < found.length; i++) {
                if (found[i].start >= cursorPos) {
                    bestIdx = i
                    break
                }
                if (i === found.length - 1) bestIdx = 0
            }
        } else {
            bestIdx = found.length - 1
            for (let i = found.length - 1; i >= 0; i--) {
                if (found[i].start < cursorPos - 1) {
                    bestIdx = i
                    break
                }
                if (i === 0) bestIdx = found.length - 1
            }
        }

        matchIndex = bestIdx
        bar.currentMatch = bestIdx + 1
        selectMatch(bestIdx)
    }

    function selectMatch(idx) {
        if (idx < 0 || idx >= matches.length) return
        let match = matches[idx]
        editor.textArea.select(match.start, match.end)
        let rect = editor.textArea.positionToRectangle(match.start)
        editor.ensureVisible(rect.y)
    }

    function findNext(text, caseSensitive) {
        if (matches.length > 0 && matchIndex >= 0) {
            matchIndex = (matchIndex + 1) % matches.length
            bar.currentMatch = matchIndex + 1
            selectMatch(matchIndex)
        } else {
            performFind(text, caseSensitive, "next")
        }
    }

    function findPrev(text, caseSensitive) {
        if (matches.length > 0 && matchIndex >= 0) {
            matchIndex = (matchIndex - 1 + matches.length) % matches.length
            bar.currentMatch = matchIndex + 1
            selectMatch(matchIndex)
        } else {
            performFind(text, caseSensitive, "prev")
        }
    }

    function replaceOne(findText, replaceText, caseSensitive) {
        if (matchIndex < 0 || matchIndex >= matches.length) return
        let match = matches[matchIndex]
        editor.textArea.remove(match.start, match.end)
        editor.textArea.insert(match.start, replaceText)
        performFind(findText, caseSensitive, "next")
    }

    function replaceAll(findText, replaceText, caseSensitive) {
        if (findText.length === 0 || matches.length === 0) return
        for (let i = matches.length - 1; i >= 0; i--) {
            let match = matches[i]
            editor.textArea.remove(match.start, match.end)
            editor.textArea.insert(match.start, replaceText)
        }
        performFind(findText, caseSensitive, "next")
    }

    function clear() {
        matches = []
        matchIndex = -1
    }
}
