#!/usr/bin/env bash
# Shows an animated GIF in this kitty window whenever it's had no keystrokes
# for IDLE_SECONDS, clearing it again on the next keystroke.
#
# Launched from .bashrc in a throwaway subshell, detached from the shell's
# own job table (so ble.sh never announces it as a job). It exits on its
# own, below, once its tty stops existing (window closed) - no reliance on
# SIGHUP or job-table cleanup.
#
# Idle is measured via the controlling tty's atime (the same mechanism
# `w`/`who -u` use for their IDLE column): every real keystroke is a read()
# on the pty that bumps atime, while non-blocking polling reads (e.g. from
# ble.sh's own idle scheduler) don't, since no bytes are consumed.
#
# The GIF is written directly to the tty as a LOCAL icat invocation, not
# via the `kitty @` remote-control socket used elsewhere in .bashrc:
#   - a remote-controlled `kitten icat` tears down its placement as soon as
#     the requesting process exits (confirmed empirically - it only stays
#     up with --hold, which needs a real interactive stdin to wait on and
#     prints a "press enter/esc" banner, neither of which we want here);
#   - a local icat normally needs to *query* the terminal (an escape-code
#     round trip) for window size, which would race ble.sh's own reads on
#     the same tty. That's avoided here by fetching cols/rows/pixel-size
#     ourselves via a plain TIOCGWINSZ ioctl (kernel-level, no bytes sent
#     over the tty stream) and passing it via --use-window-size, combined
#     with --transfer-mode=file and --stdin=no so icat never reads the tty
#     at all - it only ever writes to it.

set -u

GIF="$HOME/.config/kitty/assets/rick_tinker.gif"
IDLE_SECONDS=30
POLL_IDLE=2      # how often to check while waiting to cross IDLE_SECONDS
POLL_ACTIVE=0.2  # how often to check while the GIF is showing, so resuming
                 # activity clears it almost instantly instead of lagging
TOP_OFFSET=2    # rows of headroom above the image, nudging it down a bit

[ -f "$GIF" ] || exit 0
[ -n "${KITTY_LISTEN_ON:-}" ] || exit 0
[ -n "${KITTY_WINDOW_ID:-}" ] || exit 0

# Passed in explicitly by .bashrc (captured while stdin was still the real
# terminal) rather than read here via `tty`: once backgrounded through a
# non-interactive subshell (no job control), bash redirects stdin to
# /dev/null, which would make a local `tty` call report "not a tty".
TTY_PATH="${1:-}"
[ -n "$TTY_PATH" ] && [ -c "$TTY_PATH" ] || exit 0

shown=0

window_geometry() {
    python3 -c '
import fcntl, struct, sys, termios
try:
    fd = open(sys.argv[1], "rb")
    buf = fcntl.ioctl(fd.fileno(), termios.TIOCGWINSZ, struct.pack("HHHH", 0, 0, 0, 0))
    rows, cols, xpix, ypix = struct.unpack("HHHH", buf)
except Exception:
    sys.exit(1)
if cols and rows and xpix and ypix:
    print(cols, rows, xpix, ypix)
else:
    sys.exit(1)
' "$TTY_PATH"
}

settle_background() {
    # Same steps as .bashrc's PREEXEC background-hide hook, run early so the
    # idle GIF isn't shown over the (semi-transparent) wallpaper if no
    # command has run yet in this window.
    kitty @ set-background-image none >/dev/null 2>&1
    kitty @ set-colors background="#1D222E" >/dev/null 2>&1
}

show_gif() {
    local geo cols rows xpix ypix height
    geo=$(window_geometry) || return 1
    read -r cols rows xpix ypix <<< "$geo"
    height=$(( rows - TOP_OFFSET ))
    (( height > 0 )) || return 1
    settle_background
    # Clear the visible screen (scrollback is untouched, still reachable),
    # so old command output isn't sitting behind the GIF.
    printf '\e[2J\e[H' > "$TTY_PATH"
    kitty +kitten icat \
        --engine=builtin --stdin=no --transfer-mode=file \
        --use-window-size="${cols},${rows},${xpix},${ypix}" \
        --place="${cols}x${height}@0x${TOP_OFFSET}" \
        --loop=-1 \
        -- "$GIF" \
        > "$TTY_PATH" 2>/dev/null
    # --place leaves the terminal's real cursor at the image's top-left
    # corner; move it back home so ble.sh's next prompt redraw (it has no
    # idea we moved it) doesn't land - and let the user start typing -
    # right on top of the GIF.
    printf '\e[H' > "$TTY_PATH"
}

shell_pid() {
    kitty @ ls 2>/dev/null | python3 -c '
import json, sys
wid = int(sys.argv[1])
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(1)
for osw in data:
    for tab in osw.get("tabs", []):
        for w in tab.get("windows", []):
            if w.get("id") == wid:
                print(w.get("pid", ""))
                sys.exit(0)
sys.exit(1)
' "$KITTY_WINDOW_ID"
}

hide_gif() {
    kitty +kitten icat --clear > "$TTY_PATH" 2>/dev/null
    printf '\e[2J\e[H' > "$TTY_PATH"
    # We cleared the screen out from under ble.sh without it knowing, so it
    # won't repaint the prompt on its own. SIGWINCH is the standard "the
    # terminal changed, redraw everything" signal - ble.sh already handles
    # it (for real window resizes), so it forces exactly the full repaint
    # we need here too.
    local pid
    pid=$(shell_pid) && [ -n "$pid" ] && kill -WINCH "$pid" 2>/dev/null
}

while true; do
    if (( shown == 1 )); then
        sleep "$POLL_ACTIVE"
    else
        sleep "$POLL_IDLE"
    fi

    atime=$(stat -c %X "$TTY_PATH" 2>/dev/null) || exit 0
    printf -v now '%(%s)T' -1  # bash builtin, avoids forking `date` every tick
    idle=$(( now - atime ))

    if (( idle >= IDLE_SECONDS && shown == 0 )); then
        show_gif && shown=1
    elif (( idle < IDLE_SECONDS && shown == 1 )); then
        hide_gif
        shown=0
    fi
done
