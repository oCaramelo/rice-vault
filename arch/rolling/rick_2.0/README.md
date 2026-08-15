# rick_2.0

My current Arch Linux (Hyprland) terminal + desktop setup. Successor to
[`ubuntu/26.04/rick`](../../../ubuntu/26.04/rick), rebuilt around Hyprland
after migrating from Ubuntu/GNOME to Arch.

Includes:

- **[Hyprland](https://hypr.land/)** — window manager (`hypr/hyprland.lua`, Lua config: monitors,
  autostart, look & feel, keybindings incl. custom floating-quadrant terminal layout, window rules)
- **[hyprpaper](https://github.com/hyprwm/hyprpaper)** — wallpaper (`hypr/hyprpaper.conf` + `hypr/background.webp`)
- **[waybar](https://github.com/Alexays/Waybar)** — status bar (`waybar/config.jsonc`, `waybar/style.css`,
  plus helper scripts: `mic.sh`, `workspace_scroll.sh`, `weather.sh`, `weather_forecast.sh`, `power_menu.xml`)
- **[rofi](https://github.com/davatorium/rofi)** — app launcher (`rofi/config.rasi` + `rofi/themes/hyprland.rasi`,
  theme matched to the waybar/Hyprland palette)
- **[kitty](https://sw.kovidgoyal.net/kitty/)** — terminal emulator (`kitty/kitty.conf`, wallpaper background
  that fades out after the first command, `kitty/assets/rick_tinker.gif` idle animation)
- **[fastfetch](https://github.com/fastfetch-cli/fastfetch)** — system info fetch (`fastfetch/config.jsonc` + assets)
- **[ble.sh](https://github.com/akinomyoga/ble.sh)** — Bash Line Editor, with a custom color palette (`blesh/.blerc`)
- **bash** — `.bashrc` (wiring up ble.sh, fastfetch-once-per-session, kitty background fade,
  idle GIF), `.bash_aliases`, `.bash_profile`
- **bin/kitty-idle-gif.sh** — plays `rick_tinker.gif` in a kitty window after 30s of no keystrokes

## Restoring on Arch Linux

```bash
git clone https://github.com/oCaramelo/rice-vault.git ~/rice-vault
~/rice-vault/arch/rolling/rick_2.0/bootstrap.sh
```

The script (pacman only):

1. Installs Hyprland + ecosystem packages (`hyprland`, `hyprpaper`, `hyprpolkitagent`, `waybar`,
   `rofi`, `kitty`, `fastfetch`, `dolphin`, audio/bluetooth/network tools, fonts) via `pacman`.
   Attempts `iwgtk` (AUR-only) via `yay`/`paru` if available, otherwise warns to install it manually.
2. Downloads and installs `ble.sh` (latest release) into `~/.local/share/blesh`, if not already present.
3. Backs up any existing configs to `~/.dotfiles-backup-<timestamp>` and creates symlinks:
   - `~/.bashrc`, `~/.bash_aliases`, `~/.bash_profile` → `bash/`
   - `~/.blerc` → `blesh/.blerc`
   - `~/.config/kitty` → `kitty/`
   - `~/.config/fastfetch` → `fastfetch/`
   - `~/.config/hypr` → `hypr/`
   - `~/.config/waybar` → `waybar/`
   - `~/.config/rofi` → `rofi/`
   - `~/.local/bin/kitty-idle-gif.sh` → `bin/kitty-idle-gif.sh`

## Updating this backup

Since the configs are symlinked, just edit the files normally (`~/.config/hypr/hyprland.lua`,
`~/.bashrc`, etc.) — changes are reflected directly in the repo. Then, from the repo root:

```bash
git add -A
git commit -m "update rick_2.0 config"
git push
```
