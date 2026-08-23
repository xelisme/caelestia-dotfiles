#!/bin/sh
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"

place() {
    src="$ROOT/$1"
    dst="$HOME/$2"
    if [ ! -f "$src" ]; then
        echo "skip (tidak ada di repo): $1"
        return 0
    fi
    mkdir -p "$(dirname "$dst")"
    if [ -f "$dst" ] && ! cmp -s "$dst" "$src"; then
        cp "$dst" "$dst$BACKUP_SUFFIX"
        echo "backup: $2 -> $2$BACKUP_SUFFIX"
    fi
    cp "$src" "$dst"
    echo "installed: $2"
}

CONFIGS="\
config/caelestia/hypr-vars.lua|.config/caelestia/hypr-vars.lua
config/caelestia/hypr-user.lua|.config/caelestia/hypr-user.lua
config/caelestia/shell.json|.config/caelestia/shell.json
config/caelestia/user-config.fish|.config/caelestia/user-config.fish
config/caelestia/cli.json|.config/caelestia/cli.json
config/caelestia/monitors/eDP-1/shell.json|.config/caelestia/monitors/eDP-1/shell.json
config/kitty/kitty.conf|.config/kitty/kitty.conf
config/swappy/config|.config/swappy/config
config/environment.d/screenshots.conf|.config/environment.d/screenshots.conf"

BINS="bin/screenshot-full|.local/bin/screenshot-full"

echo "$CONFIGS" | while IFS='|' read -r src dst; do
    [ -n "$src" ] && place "$src" "$dst"
done

echo "$BINS" | while IFS='|' read -r src dst; do
    [ -n "$src" ] && place "$src" "$dst" && chmod +x "$HOME/$dst"
done

echo "selesai. jalankan 'hyprctl reload' atau re-login."
