#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; Arabic Bidi Punctuation Fixer
; Problem: Latin punctuation (. , ; : ! ?) typed right after Arabic text
; has no inherent direction (it's a "neutral" character in the Unicode
; Bidi Algorithm). Many apps default text fields to LTR paragraph
; direction, so that neutral punctuation gets anchored at the visual
; start of the line instead of immediately after the Arabic word,
; which is also what causes cursor/selection misplacement on
; copy-paste (dropped/duplicated characters at the boundary).
;
; Fix: insert an invisible Right-to-Left Mark (U+200F) right after the
; punctuation whenever it directly follows Arabic text. RLM has strong
; RTL directionality, so it pulls the neutral punctuation into the
; correct visual position everywhere the algorithm is applied.

RLM := Chr(0x200F)
ArabicRegex := "[\x{0600}-\x{06FF}\x{0750}-\x{077F}\x{08A0}-\x{08FF}\x{FB50}-\x{FDFF}\x{FE70}-\x{FEFF}]"
PunctChars := ".,;:!?"

; ---------- Live typing fix ----------
; Passively watches every character typed system-wide (via the active
; window's own keyboard layout, so it works with Arabic/English layout
; switching) without blocking or altering normal typing. When a
; watched punctuation mark is typed immediately after Arabic text, it
; injects the RLM mark right after it.

lastChar := ""

StartTypingWatcher() {
    global
    ih := InputHook("V")
    ih.OnChar := TypedChar
    ih.OnEnd := (*) => StartTypingWatcher()  ; auto-restart if it ever ends
    ih.Start()
}

TypedChar(ih, char) {
    global lastChar, ArabicRegex, PunctChars, RLM
    if (StrLen(char) = 1 && InStr(PunctChars, char) && RegExMatch(lastChar, ArabicRegex)) {
        SetTimer(() => SendText(RLM), -1)
    }
    if (char != RLM)
        lastChar := char
}

StartTypingWatcher()

; ---------- Clipboard fix (covers copy AND paste) ----------
; Any time the clipboard changes (copy, cut, or another app setting
; it), rewrite the text so punctuation after Arabic carries the RLM
; mark. This means pasted text is fixed regardless of where it came
; from.

OnClipboardChange(FixClipboard)

FixClipboard(DataType) {
    if (DataType != 1)  ; not text
        return
    text := A_Clipboard
    if (text = "")
        return
    fixed := FixBidiPunctuation(text)
    if (fixed != text)
        A_Clipboard := fixed
}

FixBidiPunctuation(text) {
    global ArabicRegex, RLM
    return RegExReplace(text, "(" . ArabicRegex . ")([.,;:!?]+)(?!\x{200F})", "$1$2" . RLM)
}

; ---------- Manual fix hotkey ----------
; Ctrl+Alt+F: re-fixes whatever text is currently selected in the
; active app (select text, press the hotkey). Useful for text typed
; before the watcher was running, or pasted from a source this tool
; didn't see.

^!f::FixSelection()

FixSelection() {
    savedClip := ClipboardAll()
    A_Clipboard := ""
    Send("^c")
    if !ClipWait(1) {
        A_Clipboard := savedClip
        return
    }
    fixed := FixBidiPunctuation(A_Clipboard)
    if (fixed != A_Clipboard) {
        A_Clipboard := fixed
        Send("^v")
        Sleep(200)
    }
    A_Clipboard := savedClip
}

; ---------- Startup notice ----------
TrayTip("Arabic Bidi Fixer", "Running. Ctrl+Alt+F fixes the current selection.", 1)
