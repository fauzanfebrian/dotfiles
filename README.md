# Dotfiles

Personal configuration files by [fauzanfebrian](https://github.com/fauzanfebrian), based on **Linux Mint / Ubuntu**
environment and managed with **GNU Stow**.

Each directory here is a stow package that mirrors its target path inside `$HOME`.

```
~/.dotfiles
├── bash/              →  ~/.bashrc
├── vim/               →  ~/.vimrc
├── ghostty/           →  ~/.config/ghostty/
├── inshellisense/     →  ~/.config/inshellisense/
├── fonts/             →  ~/.local/share/fonts/
└── setup.sh           →  stow all packages into ~
```

## Installation

Installation is a two-step process: bootstrapping the system with necessary software, then applying the personal
configurations.

### Step 1: Run System Bootstrap (For a Fresh Install)

This script installs all applications, system tweaks, and development environments.

```bash
# Clone the repository
git clone https://github.com/fauzanfebrian/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Run the main setup script
sudo ./setup.sh

# IMPORTANT: Log out and log back in before proceeding to the next step.
```

### Step 2: Apply Configurations

This script will symlink all the configuration files into your home directory using Stow.

```bash
# From inside the ~/.dotfiles directory
./install.sh #warning this will remove all existed dotfiles in your home directory.
```

## Notes

-   Designed for **Linux Mint / Ubuntu** systems.
-   Fonts are placed under `~/.local/share/fonts`.
-   Run `fc-cache -fv` to refresh fonts if needed.
-   To remove symlinks, use:
    ```bash
    stow -D -t ~ bash vim ghostty inshellisense fonts
    ```

---

> Simple, versioned, and portable dotfiles setup for Linux Mint / Ubuntu.
