#!/usr/bin/env bash
# Bootstrap script for the "rick" config: kitty, fastfetch, ble.sh, bash.
# For restoring this config on Ubuntu 26.04 (apt) only.
#
# This repo is a backup of the Ubuntu setup, not an active config for Arch.
#
# Usage:
#   git clone <this-repo> ~/rice-vault
#   ~/rice-vault/ubuntu/26.04/rick/bootstrap.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/.dotfiles-backup-$TIMESTAMP"

log() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$1"; }

# ---------------------------------------------------------------------------
# 1. Check package manager and install dependencies
# ---------------------------------------------------------------------------
if command -v apt-get >/dev/null 2>&1; then
    log "Ubuntu/Debian (apt) detected"
    sudo apt-get update
    sudo apt-get install -y kitty fastfetch git curl tar make wmctrl x11-xserver-utils || \
        warn "kitty/fastfetch may not be in this Ubuntu version's repos — install manually if this fails (e.g. PPA or .deb from GitHub releases)."
else
    warn "This script only targets apt-based systems (this repo is an Ubuntu backup, not an Arch config)."
    warn "Install manually: kitty, fastfetch, git, curl, tar, make, wmctrl, xrandr."
fi

# ---------------------------------------------------------------------------
# 2. Install ble.sh (Bash Line Editor) from latest release tarball
# ---------------------------------------------------------------------------
if [ -f "$HOME/.local/share/blesh/ble.sh" ]; then
    log "ble.sh already installed in ~/.local/share/blesh — skipping."
else
    log "Installing ble.sh..."
    BLESH_TAG="$(curl -fsSL https://api.github.com/repos/akinomyoga/ble.sh/releases/latest | grep -m1 '"tag_name"' | cut -d'"' -f4)"
    TMP_DIR="$(mktemp -d)"
    curl -fsSL -o "$TMP_DIR/ble.tar.xz" \
        "https://github.com/akinomyoga/ble.sh/releases/download/${BLESH_TAG}/ble-${BLESH_TAG}.tar.xz"
    tar xJf "$TMP_DIR/ble.tar.xz" -C "$TMP_DIR"
    make -C "$TMP_DIR"/ble-*/ install PREFIX="$HOME/.local"
    rm -rf "$TMP_DIR"
fi

# ---------------------------------------------------------------------------
# 3. Symlink dotfiles into place (backing up anything real that's in the way)
# ---------------------------------------------------------------------------
link() {
    local src="$1" dst="$2"

    # Already linked correctly? nothing to do.
    if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
        log "Already linked: $dst"
        return
    fi

    if [ -e "$dst" ] || [ -L "$dst" ]; then
        mkdir -p "$BACKUP_DIR/$(dirname "${dst#$HOME/}")"
        log "Backing up $dst -> $BACKUP_DIR/${dst#$HOME/}"
        mv "$dst" "$BACKUP_DIR/${dst#$HOME/}"
    fi

    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    log "Linked: $dst -> $src"
}

link "$REPO_DIR/bash/.bashrc"                  "$HOME/.bashrc"
link "$REPO_DIR/blesh/.blerc"                  "$HOME/.blerc"
link "$REPO_DIR/kitty"                         "$HOME/.config/kitty"
link "$REPO_DIR/fastfetch"                     "$HOME/.config/fastfetch"
link "$REPO_DIR/bin/kitty-positioned.sh"       "$HOME/.local/bin/kitty-positioned.sh"
chmod +x "$REPO_DIR/bin/kitty-positioned.sh"

if [ -d "$BACKUP_DIR" ]; then
    log "Old files saved to: $BACKUP_DIR"
fi

# ---------------------------------------------------------------------------
# 4. Restore desktop background (GNOME)
# ---------------------------------------------------------------------------
if command -v gsettings >/dev/null 2>&1; then
    cp "$REPO_DIR/background/background.webp" "$HOME/.config/background"
    gsettings set org.gnome.desktop.background picture-uri "file://$HOME/.config/background"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$HOME/.config/background"
    gsettings set org.gnome.desktop.background picture-options 'zoom'
    log "Desktop background restored."
else
    warn "gsettings not found — skipping desktop background restore. Image is at $REPO_DIR/background/background.webp"
fi

log "Done. Open a new terminal (or 'exec bash') to apply everything."
