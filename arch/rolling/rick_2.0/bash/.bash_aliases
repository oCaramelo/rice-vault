# Launch GUI apps detached from this terminal's session, so closing the
# terminal never kills them (setsid drops the controlling TTY, so no SIGHUP
# reaches the app). Workspace placement is handled separately by Hyprland
# window rules in ~/.config/hypr/hyprland.lua (class-matched, not launcher-dependent).
firefox() {
    setsid -f firefox "$@" >/dev/null 2>&1
}

code() {
    setsid -f code "$@" >/dev/null 2>&1
}
