#!/bin/bash
# macOS system bootstrap: Homebrew, CLI essentials, fonts, Docker, Go, shell setup.
# Run as your normal user (Homebrew must not run as root).

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
RED='\033[0;31m'

# Homebrew runs Git. `schannel` is Windows-only; a synced ~/.gitconfig breaks
# `brew update` on macOS. GIT_SSL_BACKEND alone is ignored by some Apple Git builds.
ensure_macos_git_for_homebrew() {
    [[ "$(uname -s)" != Darwin ]] && return 0

    export GIT_SSL_BACKEND=secure-transport

    local eff eff_lc
    eff="$(git config --get http.sslBackend 2>/dev/null || true)"
    eff_lc="$(printf '%s' "$eff" | tr '[:upper:]' '[:lower:]')"
    if [[ "$eff_lc" == schannel ]]; then
        echo -e "${YELLOW}--> Git http.sslBackend is schannel (Windows-only). Setting global override to secure-transport.${NC}"
        git config --global http.sslBackend secure-transport
        eff="$(git config --get http.sslBackend 2>/dev/null || true)"
        eff_lc="$(printf '%s' "$eff" | tr '[:upper:]' '[:lower:]')"
        if [[ "$eff_lc" == schannel ]]; then
            echo -e "${RED}--> Git still uses schannel (likely from an include). Edit ~/.gitconfig or ~/.config/git/config and remove or override http.sslBackend.${NC}"
            exit 1
        fi
    fi
}

install_homebrew() {
    if command -v brew &>/dev/null; then
        echo -e "${YELLOW}--> Homebrew already installed. Updating...${NC}"
        brew update
        return
    fi
    echo -e "${BLUE}>>> Installing Homebrew${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
}

install_essentials() {
    echo -e "${BLUE}>>> Installing CLI essentials${NC}"

    local formulae=(
        bash
        bash-completion@2
        stow
        vim
        ripgrep
        fzf
        coreutils
        git
        curl
        wget
        btop
        pyenv
    )

    for pkg in "${formulae[@]}"; do
        if brew list --formula "$pkg" &>/dev/null; then
            echo -e "${YELLOW}--> ${pkg} already installed. Skipping.${NC}"
        else
            echo "--> Installing ${pkg}..."
            brew install "$pkg"
        fi
    done
}

install_fonts() {
    echo -e "${BLUE}>>> Installing fonts${NC}"

    local casks=(
        font-jetbrains-mono
        font-fira-code
    )

    for cask in "${casks[@]}"; do
        if brew list --cask "$cask" &>/dev/null; then
            echo -e "${YELLOW}--> ${cask} already installed. Skipping.${NC}"
        else
            echo "--> Installing ${cask}..."
            brew install --cask "$cask"
        fi
    done
}

install_docker() {
    if brew list --cask docker &>/dev/null || command -v docker &>/dev/null; then
        echo -e "${YELLOW}--> Docker Desktop already installed. Skipping.${NC}"
        return
    fi
    echo -e "${BLUE}>>> Installing Docker Desktop${NC}"
    brew install --cask docker
}

install_golang() {
    if brew list --formula go &>/dev/null; then
        echo -e "${YELLOW}--> Go already installed. Skipping.${NC}"
        return
    fi
    echo -e "${BLUE}>>> Installing Go${NC}"
    brew install go
}

setup_shell() {
    echo -e "${BLUE}>>> Setting Homebrew Bash as default shell${NC}"

    local brew_bash="/opt/homebrew/bin/bash"
    if [[ ! -x "$brew_bash" ]]; then
        echo -e "${YELLOW}--> Homebrew bash not found at ${brew_bash}. Skipping shell setup.${NC}"
        return
    fi

    if ! grep -qF "$brew_bash" /etc/shells; then
        echo "--> Adding ${brew_bash} to /etc/shells (requires sudo)..."
        echo "$brew_bash" | sudo tee -a /etc/shells >/dev/null
    fi

    if [[ "$SHELL" != "$brew_bash" ]]; then
        echo "--> Changing default shell to ${brew_bash}..."
        chsh -s "$brew_bash"
    else
        echo -e "${YELLOW}--> Already using ${brew_bash} as default shell.${NC}"
    fi
}

main() {
    if [[ "${EUID:-}" -eq 0 ]]; then
        echo -e "${YELLOW}Do not run as root. Homebrew requires a normal user.${NC}"
        exit 1
    fi

    ensure_macos_git_for_homebrew
    install_homebrew
    install_essentials
    install_fonts
    install_docker
    install_golang
    setup_shell

    echo -e "\n${GREEN}=====================================================${NC}"
    echo -e "${GREEN}     System bootstrap complete.${NC}"
    echo -e "${GREEN}=====================================================${NC}"
    echo -e "\n${YELLOW}Next:${NC}"
    echo "  1. Run ./user-bootstrap.sh (Starship, NVM)."
    echo "  2. Run ./install.sh to stow dotfiles."
    echo "  3. Open a new terminal for shell changes to apply."
    echo ""
}

main
