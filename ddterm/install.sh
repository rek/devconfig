#!/bin/bash
# Installs ddterm patches and Claude Code hooks
# - Ctrl+Click on file.tsx:42 patterns in ddterm opens VS Code at that line
# - tab-title.sh: detects PRs from current branch, updates ddterm tab title

DDTERM_DIR="$HOME/.local/share/gnome-shell/extensions/ddterm@amezin.github.com"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- ddterm file:line click-to-vscode patches ---
cp "$SCRIPT_DIR/urldetect_patterns.js" "$DDTERM_DIR/ddterm/app/urldetect_patterns.js"
cp "$SCRIPT_DIR/urldetect.js" "$DDTERM_DIR/ddterm/app/urldetect.js"
cp "$SCRIPT_DIR/terminalpage.js" "$DDTERM_DIR/ddterm/app/terminalpage.js"
cp "$SCRIPT_DIR/com.github.amezin.ddterm.gschema.xml" "$DDTERM_DIR/schemas/com.github.amezin.ddterm.gschema.xml"

glib-compile-schemas "$DDTERM_DIR/schemas/"
dconf write /com/github/amezin/ddterm/detect-file-line true

echo "ddterm patches installed. Restart: gnome-extensions disable ddterm@amezin.github.com && gnome-extensions enable ddterm@amezin.github.com"

# --- Claude Code hooks (symlinked so edits in devconfig are live) ---
mkdir -p "$HOME/.claude/hooks"
ln -sf "$SCRIPT_DIR/tab-title.sh" "$HOME/.claude/hooks/tab-title.sh"

echo "Claude hooks symlinked. Ensure tab-title.sh is registered in ~/.claude/settings.json (UserPromptSubmit + SessionEnd)."
