#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_BIN="/home/el3laimy/.local/bin/godot"

echo "=================================================="
echo "🌸 Launching Finest Garden Prototype (Godot 4.7.1) 🌸"
echo "=================================================="

if [ ! -x "$GODOT_BIN" ]; then
    GODOT_BIN="$(which godot || which godot4 || true)"
fi

if [ -z "$GODOT_BIN" ] || [ ! -x "$GODOT_BIN" ]; then
    echo "❌ Godot executable not found at $GODOT_BIN"
    exit 1
fi

echo "✓ Using Godot: $GODOT_BIN"
echo "✓ Project: $PROJECT_DIR"

exec "$GODOT_BIN" --path "$PROJECT_DIR" "$@"
