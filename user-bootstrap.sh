#!/bin/bash
# User-level bootstrap: Starship, NVM.
# Run as your normal user (no sudo).

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NVM_VERSION="${NVM_VERSION:-v0.40.4}"

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

install_nvm() {
    if [[ -d "${HOME}/.nvm" ]]; then
        echo -e "${YELLOW}--> NVM already present at ~/.nvm. Skipping.${NC}"
        return
    fi
    echo -e "${BLUE}--> Installing NVM (${NVM_VERSION})...${NC}"
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
}

main() {
    echo -e "${BLUE}>>> User bootstrap (Starship, NVM)${NC}"
    install_starship
    install_nvm

    echo -e "\n${GREEN}=====================================================${NC}"
    echo -e "${GREEN}     User bootstrap complete.${NC}"
    echo -e "${GREEN}=====================================================${NC}"
    echo -e "\n${YELLOW}Suggested follow-up:${NC}"
    echo "  nvm install --lts"
    echo "  pyenv install 3.12   # or your preferred version"
    echo "  ./install.sh         # stow dotfiles from this repo"
    echo ""
}

main
