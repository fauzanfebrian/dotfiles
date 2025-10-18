#!/bin/bash

# ========================================================================================
#  Linux Mint / Ubuntu "Cockpit" Setup Script
#  Author: Muhammad Fauzan Febriansyah (curated by Gemini)
#  Description: A comprehensive script to provision a full development environment
#               on a fresh Linux Mint installation.
# ========================================================================================

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Color Definitions ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Helper Functions ---
# Function to check if the script is run as root
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}Please run this script with sudo: sudo ./setup.sh${NC}"
        exit 1
    fi
}

# --- Installation & Tweak Functions ---

system_tweaks_and_essentials() {
    echo -e "${BLUE}>>> Phase 1: System Tweaks & Essential Packages${NC}"

    echo "--> Updating package lists and upgrading system..."
    apt-get update && apt-get full-upgrade -y

    echo "--> Installing essential tools and dependencies for pyenv..."
    apt-get install -y git curl wget build-essential timeshift btop ncdu ca-certificates fonts-jetbrains-mono zram-tools tlp thermald \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

    echo "--> Enabling SSD TRIM timer..."
    systemctl enable fstrim.timer
    systemctl start fstrim.timer

    echo "--> Tuning memory and swap behavior (swappiness & zram)..."
    echo "vm.swappiness=10" > /etc/sysctl.d/99-swappiness.conf
    echo "vm.vfs_cache_pressure=50" > /etc/sysctl.d/99-vfs-cache.conf
    sysctl --system
    echo "ALGO=zstd" > /etc/default/zramswap
    echo "PERCENT=50" >> /etc/default/zramswap
    systemctl enable zramswap.service && systemctl restart zramswap.service

    echo "--> Creating 4GB fallback swap file (if it doesn't exist)..."
    # Check for any existing swap file (not just named /swapfile)
    if swapon --noheadings --show=NAME,TYPE | awk '$2 == "file" {print $1}' | grep -q '^/'; then
        echo -e "${YELLOW}--> A swap file already exists on this system. Skipping creation of new swap file.${NC}"
    else
        fallocate -l 4G /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        # Make swap file permanent with low priority
        if ! grep -q '/swapfile' /etc/fstab; then
            echo '/swapfile none swap sw,pri=-2 0 0' >> /etc/fstab
        fi
    fi

    echo "--> Enabling power and thermal management..."
    systemctl enable tlp.service && systemctl start tlp.service
    systemctl enable thermald.service && systemctl start thermald.service

    echo "--> Aggressively debloating default Mint applications..."
    DEBLOAT_PKGS=(warpinator mintwelcome hexchat thunderbird celluloid hypnotix rhythmbox drawing libre*)
    for pkg in "${DEBLOAT_PKGS[@]}"; do
        if dpkg -s "$pkg" &> /dev/null; then
            apt-get purge -y "$pkg"
        fi
    done

    echo "--> Disabling unnecessary services..."
    systemctl disable --now ModemManager.service
    systemctl disable --now whoopsie.service

    echo "--> Reducing GRUB boot timeout..."
    sed -i 's/GRUB_TIMEOUT=10/GRUB_TIMEOUT=5/' /etc/default/grub
    update-grub

    echo "--> Cleaning up..."
    apt-get autoremove -y && apt-get clean
    echo -e "${GREEN}System tweaks complete.${NC}"
}

install_docker() {
    if command -v docker &> /dev/null; then echo -e "${YELLOW}--> Docker is already installed. Skipping.${NC}"; return; fi
    echo -e "${BLUE}>>> Phase 2: Installing Docker Engine${NC}"
    echo "--> Removing old Docker packages..."
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do apt-get remove -y $pkg > /dev/null 2>&1 || true; done
    echo "--> Setting up Docker's official repository..."
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    echo "--> Installing Docker packages..."
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo "--> Adding current user ($SUDO_USER) to the 'docker' group..."
    usermod -aG docker "$SUDO_USER"
    echo -e "${GREEN}Docker Engine installation complete.${NC}"
}

install_user_tools() {
    echo -e "${BLUE}>>> Phase 3: Installing User-level Tools (NVM, pyenv, etc.)${NC}"
    if [ ! -d "/home/$SUDO_USER/.nvm" ]; then echo "--> Installing NVM..."; curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash; else echo -e "${YELLOW}--> NVM is already installed. Skipping.${NC}"; fi
    if [ ! -d "/home/$SUDO_USER/.pyenv" ]; then echo "--> Installing pyenv..."; curl -fsSL https://pyenv.run | bash; else echo -e "${YELLOW}--> pyenv is already installed. Skipping.${NC}"; fi
    if [ ! -f "/home/$SUDO_USER/.local/bin/atuin" ]; then echo "--> Installing Atuin..."; curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh; else echo -e "${YELLOW}--> Atuin is already installed. Skipping.${NC}"; fi
    echo -e "${GREEN}User-level tools installation script executed.${NC}"
}

install_golang() {
    if command -v go &> /dev/null; then echo -e "${YELLOW}--> Go is already installed. Skipping.${NC}"; return; fi
    echo -e "${BLUE}>>> Phase 4: Installing Go (Latest Version)${NC}"
    echo "--> Fetching latest Go version..."
    LATEST_GO_URL=$(curl -s https://go.dev/dl/   | grep -oE '/dl/go[0-9]+(\.[0-9]+)*\.linux-amd64\.tar\.gz'   | head -1   | sed 's#^#https://go.dev#')
    if [ -z "$LATEST_GO_URL" ]; then echo "Could not find latest Go version. Install it manually."; return; fi
    LATEST_GO_FILENAME=$(basename "$LATEST_GO_URL")
    echo "--> Downloading $LATEST_GO_FILENAME..."
    wget -q --show-progress -O "/tmp/$LATEST_GO_FILENAME" "$LATEST_GO_URL"
    echo "--> Extracting Go to /usr/local..."
    rm -rf /usr/local/go
    tar -C /usr/local -xzf "/tmp/$LATEST_GO_FILENAME"
    rm "/tmp/$LATEST_GO_FILENAME"
    echo -e "${GREEN}Go installation complete. Your dotfiles/.bashrc must set Go environment variables.${NC}"
}

install_applications() {
    echo -e "${BLUE}>>> Phase 5: Installing Applications (Ghostty, VS Code)${NC}"
    if ! command -v ghostty &> /dev/null; then echo "--> Installing Ghostty..."; /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"; else echo -e "${YELLOW}--> Ghostty is already installed. Skipping.${NC}"; fi

    if ! command -v stow &> /dev/null; then
        echo "--> Installing stow..."
        apt-get update
        apt-get install -y stow
    else
        echo -e "${YELLOW}--> stow is already installed. Skipping.${NC}"
    fi

    if ! command -v copyq &> /dev/null; then
        echo "--> Installing copyq..."
        apt-get update
        apt-get install -y copyq
    else
        echo -e "${YELLOW}--> copyq is already installed. Skipping.${NC}"
    fi
    echo -e "${GREEN}Application installation complete.${NC}"
}

# --- Main Execution Logic ---
main() {
    check_sudo
    system_tweaks_and_essentials
    install_docker
    install_golang
    install_applications
    echo "Switching to user '$SUDO_USER' for user-specific installations..."
    sudo -u $SUDO_USER bash -c "$(declare -f install_user_tools); install_user_tools"

    echo -e "\n\n${GREEN}====================================================="
    echo -e "      🚀 BASE SYSTEM SETUP COMPLETE 🚀"
    echo -e "=====================================================${NC}"
    echo -e "\n${YELLOW}!!! IMPORTANT NEXT STEPS !!!${NC}"
    echo "1. The script has finished. Now, apply your dotfiles."
    echo "   Example: 'cd ~/dotfiles && ./install.sh'"
    echo "2. You ${YELLOW}MUST LOG OUT and LOG BACK IN${NC} for all changes to take effect."
    echo "3. After logging back in, your custom .bashrc will be active. Open a terminal and run your"
    echo "   final setup commands as needed:"
    echo -e "   - ${GREEN}nvm install --lts${NC} (to install Node.js)"
    echo -e "   - ${GREEN}pyenv install 3.12.6${NC} (replace with your desired Python version)"
    echo -e "   - ${GREEN}npm install -g @inshellisense/cli${NC}"
    echo -e "   - ${GREEN}inshellisense bind${NC} (to set up smart autocomplete)"
    echo -e "   - ${GREEN}atuin import auto${NC} (to import your shell history)"
    echo ""
}

main