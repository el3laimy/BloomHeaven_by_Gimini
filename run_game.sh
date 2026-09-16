#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Resolve Godot executable: respect GODOT_BIN environment variable, then PATH, then standard fallbacks
if [ -z "$GODOT_BIN" ] || [ ! -x "$GODOT_BIN" ]; then
    GODOT_BIN="$(command -v godot || command -v godot4 || echo "")"
fi

if [ -z "$GODOT_BIN" ] || [ ! -x "$GODOT_BIN" ]; then
    if [ -x "$HOME/.local/bin/godot" ]; then
        GODOT_BIN="$HOME/.local/bin/godot"
    fi
fi

echo "=================================================="
echo "🌸 Launching Finest Garden Prototype (Godot 4.7.1) 🌸"
echo "=================================================="

if [ -z "$GODOT_BIN" ] || [ ! -x "$GODOT_BIN" ]; then
    echo "❌ Godot executable not found. Please ensure 'godot' is in your PATH or set GODOT_BIN."
    exit 1
fi

echo "✓ Using Godot: $GODOT_BIN"
echo "✓ Project: $PROJECT_DIR"

exec "$GODOT_BIN" --path "$PROJECT_DIR" "$@"
