# .dotfiles

Personal development environment for **macOS**, managed with [GNU Stow](https://www.gnu.org/software/stow/).

Each top-level directory is a Stow package whose contents mirror the target path inside `$HOME`. Running `./install.sh` creates or refreshes symlinks with **`--restow --adopt`** so existing plain files are adopted instead of causing conflicts.

## Stack

| Layer | Tool | Config location |
|---|---|---|
| Terminal emulator | [Ghostty](https://ghostty.org) | `~/.config/ghostty/` |
| Shell | Bash 5.x (Homebrew) | `~/.bashrc` |
| Prompt | [Starship](https://starship.rs) | `~/.config/starship.toml` |
| History / fuzzy search | [fzf](https://github.com/junegunn/fzf) | Ctrl+R history, Ctrl+T files, Alt+C cd |
| Tab completion | [bash-completion@2](https://github.com/scop/bash-completion) | Homebrew managed |
| Editor | Vim 9+ (vim-plug) | `~/.vimrc` |
| Fonts | JetBrains Mono, Fira Code | Homebrew casks (SF Pro is built into macOS) |

**Theme:** Cobalt2 — applied consistently across Ghostty and Starship prompt colors.

## Repository layout

```
.dotfiles/
├── bash/                  → ~/.bashrc
├── ghostty/               → ~/.config/ghostty/…
├── starship/              → ~/.config/starship.toml
├── vim/                   → ~/.vimrc
├── .stow-global-ignore    — patterns excluded from stow
├── install.sh             — stow all packages into ~ (--restow --adopt)
├── system-bootstrap.sh    — Homebrew, CLI tools, fonts, Docker, Go, shell setup
└── user-bootstrap.sh      — Starship, NVM
```

### Stow boundaries

`.stow-global-ignore` lists regexes (relative to each package directory) so stray files such as `README.md`, editor swap files, or bootstrap scripts are never linked into `$HOME` if they appear inside a package tree.

## Prerequisites

### From `system-bootstrap.sh`

Installs [Homebrew](https://brew.sh) (if not present) and the following via `brew`:

**Formulae:** bash, bash-completion@2, stow, vim, ripgrep, fzf, coreutils, git, curl, wget, btop, pyenv

**Casks:** font-jetbrains-mono, font-fira-code, docker (Docker Desktop)

**Also:** go, and sets Homebrew's Bash 5.x as the default login shell.

### From `user-bootstrap.sh`

**Starship** and **NVM** — installed via their official install scripts.

**pyenv** is installed with Homebrew in `system-bootstrap.sh` (not the pyenv.run curl installer).

### Optional / manual

| Tool | Notes |
|---|---|
| [Ghostty](https://ghostty.org) | `brew install --cask ghostty` or download from ghostty.org |

## Installation

### 1. Clone

```bash
git clone https://github.com/fauzanfebrian/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### 2. System bootstrap

```bash
./system-bootstrap.sh
```

Installs Homebrew, CLI tools, fonts, Docker Desktop, Go, and sets Bash 5.x as the default shell. Do **not** run as root.

### 3. User bootstrap

```bash
./user-bootstrap.sh
```

### 4. Stow configurations

```bash
./install.sh
```

### 5. Post-install

Open a new terminal for shell changes to take effect, then:

```bash
nvm install --lts
pyenv install 3.12          # or your preferred version
```

If `pyenv install` fails while compiling Python, install the usual build headers first, for example: `brew install openssl readline sqlite3 xz`.

## Stow commands reference

`./install.sh` is equivalent to:

```bash
stow --restow --adopt -t ~ bash vim ghostty starship
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

## Design decisions

- **NVM and pyenv are lazy-loaded** — `nvm`, `node`, `npm`, `npx`, `pyenv`, `python`, `python3`, `pip`, and `pip3` are thin wrappers that run the real initializers on first use, keeping new shells fast.
- **fzf provides fuzzy Ctrl+R history search**, Ctrl+T file finder, and Alt+C directory jumper — lightweight and fast, no daemon needed.
- **bash-completion@2** provides rich tab completion for git, docker, brew, and many other commands.
- **PATH deduplication** is done in pure Bash (no `awk` subprocess).
- **Interactive `.bashrc` does not use `set -o pipefail`** — avoids surprising pipeline exit status in daily use.
- **Vim** uses `<leader>w` / `<leader>q` / `<leader>x` for save/quit, `<leader>fh` for fzf history, and `]b` / `[b` for buffer navigation.
- **Homebrew Bash 5.x** is used instead of macOS's bundled Bash 3.2 for `globstar`, associative arrays, and modern shell features.

## License

Personal configuration. Use at your own discretion.
