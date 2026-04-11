#!/bin/bash
# User-level bootstrap: Starship, Atuin, pyenv, NVM, Ghostty.
# Run as your normal user (no sudo). Some installers may prompt for sudo internally.

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NVM_VERSION="${NVM_VERSION:-v0.39.7}"

if [[ "${EUID:-}" -eq 0 ]]; then
    echo -e "${YELLOW}Do not run as root. Run as your normal user: ./user-bootstrap.sh${NC}"
    exit 1
fi

install_starship() {
    if command -v starship &>/dev/null; then
        echo -e "${YELLOW}--> Starship already installed. Skipping.${NC}"
        return
    fi
    echo -e "${BLUE}--> Installing Starship...${NC}"
    curl -sS https://starship.rs/install.sh | sh -s -- -y
}

install_atuin() {
    if command -v atuin &>/dev/null; then
        echo -e "${YELLOW}--> Atuin already installed. Skipping.${NC}"
        return
    fi
    echo -e "${BLUE}--> Installing Atuin...${NC}"
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
}

install_pyenv() {
    if [[ -d "${HOME}/.pyenv" ]]; then
        echo -e "${YELLOW}--> pyenv already present at ~/.pyenv. Skipping.${NC}"
        return
    fi
    echo -e "${BLUE}--> Installing pyenv...${NC}"
    curl -fsSL https://pyenv.run | bash
}

install_nvm() {
    if [[ -d "${HOME}/.nvm" ]]; then
        echo -e "${YELLOW}--> NVM already present at ~/.nvm. Skipping.${NC}"
        return
    fi
    echo -e "${BLUE}--> Installing NVM (${NVM_VERSION})...${NC}"
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
}

install_ghostty() {
    if command -v ghostty &>/dev/null; then
        echo -e "${YELLOW}--> Ghostty already installed. Skipping.${NC}"
        return
    fi
    echo -e "${BLUE}--> Installing Ghostty (Ubuntu installer; may use sudo)...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"
}

main() {
    echo -e "${BLUE}>>> User bootstrap (Starship, Atuin, pyenv, NVM, Ghostty)${NC}"
    install_starship
    install_atuin
    install_pyenv
    install_nvm
    install_ghostty

    echo -e "\n${GREEN}=====================================================${NC}"
    echo -e "${GREEN}     User bootstrap complete.${NC}"
    echo -e "${GREEN}=====================================================${NC}"
    echo -e "\n${YELLOW}Suggested follow-up:${NC}"
    echo "  nvm install --lts"
    echo "  pyenv install 3.12   # or your preferred version"
    echo "  npm install -g @inshellisense/cli && inshellisense bind"
    echo "  atuin import auto"
    echo "  ./install.sh         # stow dotfiles from this repo"
    echo ""
}

main
