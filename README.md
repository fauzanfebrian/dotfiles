# .dotfiles

Personal development environment for **Linux Mint / Ubuntu**, managed with [GNU Stow](https://www.gnu.org/software/stow/).

Each top-level directory is a Stow package whose contents mirror the target path inside `$HOME`. Running `./install.sh` creates or refreshes symlinks with **`--restow --adopt`** so existing plain files are adopted instead of causing conflicts.

## Stack

| Layer | Tool | Config location |
|---|---|---|
| Terminal emulator | [Ghostty](https://ghostty.org) | `~/.config/ghostty/` |
| Shell | Bash 5.x | `~/.bashrc` |
| Prompt | [Starship](https://starship.rs) | `~/.config/starship.toml` |
| Editor | Vim 9+ (vim-plug) | `~/.vimrc` |
| Clipboard | [CopyQ](https://hluk.github.io/CopyQ/) | `~/.config/copyq/` |
| Fonts | JetBrains Mono, FiraCode, SF Pro | `~/.local/share/fonts/` |

**Theme:** Cobalt2 — applied consistently across Ghostty, CopyQ, and Starship prompt colors.

## Repository layout

```
.dotfiles/
├── bash/                  → ~/.bashrc
├── copyq/                 → ~/.config/copyq/…
├── fonts/                 → ~/.local/share/fonts/…
├── ghostty/               → ~/.config/ghostty/…
├── starship/              → ~/.config/starship.toml
├── vim/                   → ~/.vimrc
├── .stow-global-ignore    — patterns excluded from stow (see below)
├── install.sh             — stow all packages into ~ (--restow --adopt)
├── system-bootstrap.sh    — privileged: apt, Go, Docker, stow, copyq, vim
└── user-bootstrap.sh      — user: Starship, pyenv, NVM, Ghostty
```

### Stow boundaries

`.stow-global-ignore` lists regexes (relative to each package directory) so stray files such as `README.md`, editor swap files, or bootstrap scripts are never linked into `$HOME` if they appear inside a package tree.

## Prerequisites

### From `system-bootstrap.sh` (sudo)

Core build tools, Docker, Go under `/usr/local/go`, **stow**, **copyq**, **vim**, and typical Mint/Ubuntu tuning (zram, swap file, etc.).

### From `user-bootstrap.sh` (normal user)

**Starship**, **pyenv**, **NVM**, **Ghostty** (the Ghostty Ubuntu installer may prompt for `sudo`).

### Optional / manual

| Tool | Notes |
|---|---|
| [ripgrep](https://github.com/BurntSushi/ripgrep) | `apt install ripgrep` — powers Vim `:Rg` |

### Fonts (bundled in `fonts/` package)

- **JetBrains Mono** — primary font for Ghostty, Vim, and CopyQ
- **FiraCode** — alternative ligature font
- **SF Pro Display** — UI/display font

After stowing fonts, run `fc-cache -fv` if new fonts do not appear immediately.

## Installation

### 1. Clone

```bash
git clone https://github.com/fauzanfebrian/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### 2. System bootstrap (sudo, from your user account)

```bash
sudo ./system-bootstrap.sh
```

Requires `SUDO_USER` (run `sudo` from a logged-in user, not a root-only console).

### 3. User bootstrap (no sudo)

```bash
./user-bootstrap.sh
```

### 4. Stow configurations

```bash
./install.sh
```

### 5. Session / group refresh

Log out and back in so the **docker** group and other changes apply.

### Post-install

```bash
nvm install --lts
pyenv install 3.12          # or your preferred version
```

## Stow commands reference

`./install.sh` is equivalent to:

```bash
stow --restow --adopt -t ~ bash vim ghostty fonts copyq starship
```

Other examples:

```bash
stow --restow --adopt -t ~ bash
stow -D -t ~ bash
```

## Environment variables

| Variable | Default | Purpose |
|---|---|---|
| `EDITOR` / `VISUAL` | `vim` | Default editor |
| `GOPATH` | `~/go` | Go workspace |
| `GOBIN` | `$GOPATH/bin` | Go binary output |
| `PYENV_ROOT` | `~/.pyenv` | pyenv installation |
| `NVM_DIR` | `~/.nvm` | NVM installation |
| `IS_MAIN_TERMINAL` | `true`/`false` | Interactive, non-VSCode terminals |

## Design decisions

- **NVM and pyenv are lazy-loaded** — `nvm`, `node`, `npm`, `npx`, `pyenv`, `python`, `python3`, `pip`, and `pip3` are thin wrappers that run the real installers on first use, keeping new shells fast.
- **PATH deduplication** is done in pure Bash (no `awk` subprocess).
- **Interactive `.bashrc` does not use `set -o pipefail`** — avoids surprising pipeline exit status in daily use.
- **Vim** uses `<leader>w` / `<leader>q` / `<leader>x` for save/quit, `<leader>fh` for fzf history, and `]b` / `[b` for buffer navigation.

## License

Personal configuration. Use at your own discretion.
