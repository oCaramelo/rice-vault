# rick

Backup of my Ubuntu 26.04 terminal setup, taken before migrating to Arch.

This is **not** meant to be applied on Arch — it's an Ubuntu-specific config kept
here purely as a fallback, in case I ever go back to Ubuntu and want everything
restored quickly.

Includes:

- **[kitty](https://sw.kovidgoyal.net/kitty/)** — terminal emulator (`kitty/kitty.conf`, no theme, wallpaper background)
- **[fastfetch](https://github.com/fastfetch-cli/fastfetch)** — system info fetch (`fastfetch/config.jsonc` + assets)
- **[ble.sh](https://github.com/akinomyoga/ble.sh)** — Bash Line Editor, with a custom color palette (`blesh/.blerc`)
- **bash** — `.bashrc` wiring up the above
- **bin/kitty-positioned.sh** — script behind the launcher shortcut that opens a kitty window and cycles it through the four screen quadrants
- **background/** — desktop wallpaper

## Restoring on Ubuntu 26.04

```bash
git clone https://github.com/oCaramelo/rice-vault.git ~/rice-vault
~/rice-vault/ubuntu/26.04/rick/bootstrap.sh
```

The script (Ubuntu/Debian `apt` only):

1. Installs `kitty`, `fastfetch`, `git`, `curl`, `tar`, `make`, `wmctrl`, `xrandr` via `apt`.
2. Downloads and installs `ble.sh` (latest release) into `~/.local/share/blesh`, if not already present.
3. Backs up any existing configs to `~/.dotfiles-backup-<timestamp>` and creates symlinks:
   - `~/.bashrc` → `bash/.bashrc`
   - `~/.blerc` → `blesh/.blerc`
   - `~/.config/kitty` → `kitty/`
   - `~/.config/fastfetch` → `fastfetch/`
   - `~/.local/bin/kitty-positioned.sh` → `bin/kitty-positioned.sh`
4. Restores the desktop background via `gsettings` (GNOME).

## Updating this backup

Since the configs are symlinked, just edit the files normally (`~/.bashrc`, `~/.blerc`, etc.) — changes are reflected directly in the repo. Then, from the repo root:

```bash
git add -A
git commit -m "update rick config"
git push
```
