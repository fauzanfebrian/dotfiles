# Dotfiles

Personal configuration files by [fauzanfebrian](https://github.com/fauzanfebrian),
based on **Linux Mint / Ubuntu** environment and managed with **GNU Stow**.

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

---

## Installation

Clone the repo anywhere:

```bash
git clone https://github.com/fauzanfebrian/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup.sh
```

---

## Requirements

Install GNU Stow if not already present:

```bash
sudo apt install stow
```

---

## Notes

- Designed for **Linux Mint / Ubuntu** systems.
- Fonts are placed under `~/.local/share/fonts`.
- Run `fc-cache -fv` to refresh fonts if needed.
- To remove symlinks, use:
  ```bash
  stow -D -t ~ bash vim ghostty inshellisense fonts
  ```

---

> Simple, versioned, and portable dotfiles setup for Linux Mint / Ubuntu.
