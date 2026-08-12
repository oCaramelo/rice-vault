# rice-vault

Backups of Linux system/terminal configs, organized by distro so I can restore
a known-good setup on any machine I go back to.

## Layout

```
<distro>/<distro-version>/<config-name>/
```

- **distro** — e.g. `ubuntu`, `arch`
- **distro-version** — e.g. `26.04`
- **config-name** — a name identifying the specific setup/theme, e.g. `rick`
  (inspired by Rick and Morty)

Each `<config-name>/` folder is self-contained: it has its own `README.md` and
`bootstrap.sh` to reinstall and re-link everything on that distro/version.

## Current configs

- [`ubuntu/26.04/rick`](ubuntu/26.04/rick) — kitty, fastfetch, ble.sh, bash, desktop background
