# RTL Text Misalignment Fix

A small always-on Windows background tool that fixes a common bidirectional
(bidi) text bug: when you type or paste Arabic (or any RTL script) mixed
with Latin punctuation (`.` `,` `;` `:` `!` `?`), the punctuation often
renders on the wrong side of the sentence instead of right after the last
word — and selecting/copying that text can silently drop or misplace
characters at the boundary.

This tool fixes it system-wide: in any app, any text field, as you type or
whenever you copy/paste.

## The problem

```
لسلام عليكم أحمد,
```

Should read (comma right after "أحمد"):

```
السلام عليكم أحمد،
```

But in many apps the `,` and `.` end up floating at the *start* of the line
instead of the end, because:

- Arabic is RTL, but ASCII punctuation like `.` and `,` has **no inherent
  direction** in the Unicode Bidi Algorithm — it's a "neutral" character.
- Many text fields default their paragraph direction to LTR rather than
  detecting RTL content, so neutral punctuation gets anchored at the wrong
  visual position.
- The same ambiguity is what causes mouse-drag text selection to clip or
  duplicate characters at the RTL/LTR boundary (e.g. a missing `ا` after
  copy-pasting).

## The fix

The tool inserts an invisible **Right-to-Left Mark** (U+200F) immediately
after Latin punctuation whenever it directly follows Arabic text. RLM has
strong RTL directionality, so it pulls the punctuation into the correct
visual position everywhere the Unicode Bidi Algorithm is applied — no
visible change to the text, just a hidden formatting character.

It applies this fix in three ways:

1. **Live typing** — as you type, right after you hit `.`, `,`, `;`, `:`,
   `!`, or `?` following Arabic text, the fix is applied in real time.
2. **Clipboard** — every time you copy or cut text anywhere, it's
   auto-corrected in the clipboard, so pasting it anywhere is correct too.
3. **Manual fix** (`Ctrl+Alt+F`) — select any already-broken text (typed
   before the tool was running, or pasted from an unfixed source) and
   press the hotkey to fix it in place.

## Requirements

- Windows 10/11
- [AutoHotkey v2](https://www.autohotkey.com/) (free, open source)

## Installation

### 1. Install AutoHotkey v2

Using `winget` (recommended):

```powershell
winget install --id AutoHotkey.AutoHotkey -e
```

Or download the installer directly from
[autohotkey.com](https://www.autohotkey.com/).

### 2. Get the script

Clone the repo:

```bash
git clone https://github.com/abdulmoezshadi90-art/rtl-text-misalignment-fix.git
```

Or just download `BidiFixer.ahk` directly.

### 3. Run it

Double-click `BidiFixer.ahk`. A green "H" icon will appear in your system
tray, and a notification confirms it's running.

### 4. (Optional but recommended) Run it automatically at login

Press `Win+R`, type `shell:startup`, hit Enter. Create a shortcut in that
folder pointing to:

```
Target:  C:\path\to\AutoHotkey64.exe "C:\path\to\BidiFixer.ahk"
```

Or in PowerShell:

```powershell
$startupDir = [Environment]::GetFolderPath("Startup")
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut((Join-Path $startupDir "RTL-Fix.lnk"))
$Shortcut.TargetPath = "C:\Users\<you>\AppData\Local\Programs\AutoHotkey\v2\AutoHotkey64.exe"
$Shortcut.Arguments = '"C:\path\to\BidiFixer.ahk"'
$Shortcut.Save()
```

Now it starts automatically every time you log into Windows.

## Usage

| Situation | What to do |
|---|---|
| Typing Arabic + punctuation | Just type normally. |
| Copying/pasting Arabic text | Just copy/paste normally. |
| Already-broken existing text | Select it, press `Ctrl+Alt+F`. |

## Controls

- **Check it's running:** look for the green "H" icon in the system tray
  (may be under the hidden icons arrow `^`).
- **Pause/exit:** right-click the tray icon → `Exit` (or `Suspend Hotkeys`
  to temporarily disable without closing).
- **Stop auto-start:** delete the shortcut from `shell:startup`.

## Known limitation

This does **not** fix mouse-drag selection glitches at the RTL/LTR boundary
in apps whose text engine has its own selection bug — that happens during
selection, before any text reaches the clipboard, so there's nothing to
intercept. Workaround: select Arabic text using the keyboard (`Home` then
`Shift+End`, or `Shift+Ctrl+Arrow`) instead of dragging with the mouse.

## How it works (technical)

`BidiFixer.ahk` uses two AutoHotkey v2 mechanisms:

- An [`InputHook`](https://www.autohotkey.com/docs/v2/lib/InputHook.htm) in
  visible/passthrough mode (`"V"`) to passively observe every character
  typed system-wide (resolved through whatever keyboard layout is active,
  so it works across language switching) without blocking or altering
  normal input.
- [`OnClipboardChange`](https://www.autohotkey.com/docs/v2/lib/OnClipboardChange.htm)
  to intercept and rewrite clipboard text on every copy/cut.

Both paths run the same fix: a regex that finds Arabic-script characters
(`U+0600`–`U+06FF`, `U+0750`–`U+077F`, `U+08A0`–`U+08FF`,
`U+FB50`–`U+FDFF`, `U+FE70`–`U+FEFF`) immediately followed by Latin
punctuation, and inserts `U+200F` (RLM) right after the punctuation if it
isn't already there.

## License

MIT — see [LICENSE](LICENSE).
