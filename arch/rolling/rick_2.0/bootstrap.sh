#!/usr/bin/env bash
# Bootstrap script for the "rick_2.0" config: Hyprland, waybar, rofi, kitty,
# fastfetch, ble.sh, bash. For restoring this config on Arch Linux (pacman)
# only.
#
# Usage:
#   git clone <this-repo> ~/rice-vault
#   ~/rice-vault/arch/rolling/rick_2.0/bootstrap.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/.dotfiles-backup-$TIMESTAMP"

log() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$1"; }

# ---------------------------------------------------------------------------
# 1. Check package manager and install dependencies
# ---------------------------------------------------------------------------
if command -v pacman >/dev/null 2>&1; then
    log "Arch Linux (pacman) detected"
    sudo pacman -S --needed \
        hyprland hyprpaper hyprpolkitagent waybar rofi kitty fastfetch dolphin \
        git curl tar make jq playerctl brightnessctl power-profiles-daemon \
        wireplumber pavucontrol blueman bluez bluez-utils \
        networkmanager network-manager-applet wl-clipboard cliphist \
        otf-font-awesome ttf-jetbrains-mono-nerd breeze-icons python

    if ! command -v iwgtk >/dev/null 2>&1; then
        if command -v yay >/dev/null 2>&1; then
            yay -S --needed iwgtk
        elif command -v paru >/dev/null 2>&1; then
            paru -S --needed iwgtk
        else
            warn "iwgtk is AUR-only and no AUR helper (yay/paru) was found — install it manually."
        fi
    fi
else
    warn "This script only targets pacman-based systems (this config is Arch-specific)."
    warn "Install manually: hyprland, hyprpaper, hyprpolkitagent, waybar, rofi, kitty, fastfetch,"
    warn "dolphin, git, curl, tar, make, jq, playerctl, brightnessctl, power-profiles-daemon,"
    warn "wireplumber, pavucontrol, blueman, bluez(-utils), networkmanager(-applet),"
    warn "wl-clipboard, cliphist, iwgtk, otf-font-awesome, ttf-jetbrains-mono-nerd, breeze-icons, python."
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

link "$REPO_DIR/bash/.bashrc"          "$HOME/.bashrc"
link "$REPO_DIR/bash/.bash_aliases"    "$HOME/.bash_aliases"
link "$REPO_DIR/bash/.bash_profile"    "$HOME/.bash_profile"
link "$REPO_DIR/blesh/.blerc"          "$HOME/.blerc"
link "$REPO_DIR/kitty"                 "$HOME/.config/kitty"
link "$REPO_DIR/fastfetch"             "$HOME/.config/fastfetch"
link "$REPO_DIR/hypr"                  "$HOME/.config/hypr"
link "$REPO_DIR/waybar"                "$HOME/.config/waybar"
link "$REPO_DIR/rofi"                  "$HOME/.config/rofi"
link "$REPO_DIR/bin/kitty-idle-gif.sh" "$HOME/.local/bin/kitty-idle-gif.sh"
chmod +x "$REPO_DIR"/waybar/*.sh "$REPO_DIR/bin/kitty-idle-gif.sh"

if [ -d "$BACKUP_DIR" ]; then
    log "Old files saved to: $BACKUP_DIR"
fi

log "Done. Log out/in (or restart Hyprland) to apply everything."
