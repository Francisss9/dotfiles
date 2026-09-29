# Dotfiles

## Requirements

- Arch Linux (or an Arch-based distro, e.g. Omarchy)
- Git (usually preinstalled)

Everything else (`base-devel`, `yay`, `stow`) is installed automatically by `bootstrap.sh`.

## Installation

```bash
git clone https://github.com/Francisss9/Dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh
hyprctl reload
```

`bootstrap.sh` installs prerequisites (`git`, `curl`, `wget`, `base-devel`, `yay`), then
runs `install.sh`, which in turn:

1. installs official + AUR packages (`packages/official.txt`, `packages/aur.txt`)
2. symlinks everything with GNU Stow (**this overwrites any existing config files
   without backup** — the repo is the source of truth)
3. runs `doctor.sh` to verify the result


### Configs only, no package installation

If you already have your packages installed (or don't want this machine to install
anything), you can link just the dotfiles configs:

```bash
cd ~/.dotfiles
./scripts/install/configs_only.sh
hyprctl reload
```

### Note on apps that generate their own config files

Some apps (e.g. Doom Emacs) create their own config files the first time you open
them, which can end up sitting on top of where a symlink should be. If `doctor.sh`
reports a config as a "REAL file" instead of linked after opening such an app for
the first time, just re-run:

```bash
cd ~/.dotfiles
rm -f <the conflicting file>
stow -D config && stow config
hyprctl reload
```

## After installing

- `./scripts/update/packages_update.sh` — re-export your currently installed packages
  into `packages/official.txt` / `aur.txt`
- `./scripts/update/sync.sh` — commit and push any local dotfiles changes
- `./scripts/utils/cleanup.sh` — clear package caches and rebuild font cache
- `./scripts/utils/doctor.sh` — check that all symlinks and packages are healthy

> [!IMPORTANT]
> It's best to use ```hyprctl reload``` as **final** step of any **change** if hyprland seems to either not change looks or show errors or any other type of problem.
