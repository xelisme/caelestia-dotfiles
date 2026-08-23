#!/bin/sh
set -e

DOTDIR="$(cd "$(dirname "$0")" && pwd)/config"
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"

install_file() {
    src="$DOTDIR/$1"
    dst="$HOME/.config/$1"
    [ -f "$src" ] || { echo "skip (tidak ada di repo): $1"; return 0; }
    mkdir -p "$(dirname "$dst")"
    if [ -f "$dst" ] && ! cmp -s "$dst" "$src"; then
        cp "$dst" "$dst$BACKUP_SUFFIX"
        echo "backup: $dst -> $dst$BACKUP_SUFFIX"
    fi
    cp "$src" "$dst"
    echo "installed: $1"
}

for f in \
    caelestia/hypr-vars.lua \
    caelestia/hypr-user.lua \
    caelestia/shell.json \
    caelestia/user-config.fish \
    caelestia/monitors/eDP-1/shell.json \
    kitty/kitty.conf \
    swappy/config \
    environment.d/screenshots.conf
do
    install_file "$f"
done

echo "selesai. jalankan 'hyprctl reload' atau re-login."
