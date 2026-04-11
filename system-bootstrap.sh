#!/bin/bash
# Privileged system bootstrap: apt, Go toolchain, Docker, and apt-installed CLI deps.
# Run as: sudo ./system-bootstrap.sh  (from a user session so SUDO_USER is set)

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

check_sudo_and_user() {
    if [[ "${EUID:-}" -ne 0 ]]; then
        echo -e "${YELLOW}Run with sudo: sudo ./system-bootstrap.sh${NC}"
        exit 1
    fi
    if [[ -z "${SUDO_USER:-}" ]]; then
        echo -e "${YELLOW}SUDO_USER is unset. Run from a normal user account, e.g. sudo ./system-bootstrap.sh${NC}"
        exit 1
    fi
}

system_tweaks_and_essentials() {
    echo -e "${BLUE}>>> Phase 1: System tweaks and essential packages${NC}"

    echo "--> Updating package lists and upgrading system..."
    apt-get update && apt-get full-upgrade -y

    echo "--> Installing essential tools and pyenv build dependencies..."
    apt-get install -y git curl wget build-essential timeshift btop ncdu ca-certificates fonts-jetbrains-mono zram-tools tlp thermald \
        libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

    echo "--> Installing stow, copyq, vim (for dotfiles and daily use)..."
    apt-get install -y stow copyq vim

    echo "--> Enabling SSD TRIM timer..."
    systemctl enable fstrim.timer
    systemctl start fstrim.timer

    echo "--> Tuning memory and swap behavior (swappiness and zram)..."
    echo "vm.swappiness=10" > /etc/sysctl.d/99-swappiness.conf
    echo "vm.vfs_cache_pressure=50" > /etc/sysctl.d/99-vfs-cache.conf
    sysctl --system
    echo "ALGO=zstd" > /etc/default/zramswap
    echo "PERCENT=50" >> /etc/default/zramswap
    systemctl enable zramswap.service && systemctl restart zramswap.service

    echo "--> Creating 4GB fallback swap file (if none exists)..."
    if swapon --noheadings --show=NAME,TYPE | awk '$2 == "file" {print $1}' | grep -q '^/'; then
        echo -e "${YELLOW}--> A swap file already exists. Skipping.${NC}"
    else
        fallocate -l 4G /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        if ! grep -q '/swapfile' /etc/fstab; then
            echo '/swapfile none swap sw,pri=-2 0 0' >> /etc/fstab
        fi
    fi

    echo "--> Enabling power and thermal management..."
    systemctl enable tlp.service && systemctl start tlp.service
    systemctl enable thermald.service && systemctl start thermald.service

    echo "--> Debloating default Mint applications (explicit package names + libreoffice*)..."
    DEBLOAT_PKGS=(warpinator mintwelcome hexchat thunderbird celluloid hypnotix rhythmbox drawing)
    for pkg in "${DEBLOAT_PKGS[@]}"; do
        if dpkg -s "$pkg" &>/dev/null; then
            apt-get purge -y "$pkg"
        fi
    done
    mapfile -t _libreoffice_pkgs < <(dpkg-query -W -f='${Package}\n' 2>/dev/null | grep -E '^libreoffice' || true)
    if [[ "${#_libreoffice_pkgs[@]}" -gt 0 ]]; then
        apt-get purge -y "${_libreoffice_pkgs[@]}"
    fi

    echo "--> Disabling unnecessary services..."
    systemctl disable --now ModemManager.service 2>/dev/null || true
    systemctl disable --now whoopsie.service 2>/dev/null || true

    echo "--> Reducing GRUB boot timeout..."
    if [[ -f /etc/default/grub ]]; then
        sed -i 's/GRUB_TIMEOUT=10/GRUB_TIMEOUT=5/' /etc/default/grub
        update-grub
    fi

    echo "--> Cleaning up..."
    apt-get autoremove -y && apt-get clean
    echo -e "${GREEN}System tweaks complete.${NC}"
}

install_docker() {
    if command -v docker &>/dev/null; then
        echo -e "${YELLOW}--> Docker is already installed. Skipping.${NC}"
        return
    fi
    echo -e "${BLUE}>>> Phase 2: Docker Engine${NC}"
    echo "--> Removing old Docker packages..."
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
        apt-get remove -y "$pkg" >/dev/null 2>&1 || true
    done
    echo "--> Setting up Docker apt repository..."
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" \
        | tee /etc/apt/sources.list.d/docker.list >/dev/null
    apt-get update
    echo "--> Installing Docker packages..."
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo "--> Adding user '${SUDO_USER}' to the docker group..."
    usermod -aG docker "$SUDO_USER"
    echo -e "${GREEN}Docker installation complete.${NC}"
}

install_golang() {
    if command -v go &>/dev/null; then
        echo -e "${YELLOW}--> Go is already installed. Skipping.${NC}"
        return
    fi
    echo -e "${BLUE}>>> Phase 3: Go (latest linux-amd64 from go.dev)${NC}"
    echo "--> Resolving latest Go tarball..."
    LATEST_GO_URL=$(curl -s https://go.dev/dl/ | grep -oE '/dl/go[0-9]+(\.[0-9]+)*\.linux-amd64\.tar\.gz' | head -1 | sed 's#^#https://go.dev#')
    if [[ -z "${LATEST_GO_URL}" ]]; then
        echo "Could not resolve latest Go URL. Install Go manually."
        return
    fi
    LATEST_GO_FILENAME=$(basename "$LATEST_GO_URL")
    echo "--> Downloading ${LATEST_GO_FILENAME}..."
    wget -q --show-progress -O "/tmp/${LATEST_GO_FILENAME}" "$LATEST_GO_URL"
    echo "--> Extracting to /usr/local/go..."
    rm -rf /usr/local/go
    tar -C /usr/local -xzf "/tmp/${LATEST_GO_FILENAME}"
    rm -f "/tmp/${LATEST_GO_FILENAME}"
    echo -e "${GREEN}Go installation complete.${NC}"
}

main() {
    check_sudo_and_user
    system_tweaks_and_essentials
    install_docker
    install_golang

    echo -e "\n${GREEN}=====================================================${NC}"
    echo -e "${GREEN}     System bootstrap complete.${NC}"
    echo -e "${GREEN}=====================================================${NC}"
    echo -e "\n${YELLOW}Next:${NC}"
    echo "  1. Run ./user-bootstrap.sh as ${SUDO_USER} (no sudo)."
    echo "  2. Run ./install.sh to stow dotfiles."
    echo "  3. Log out and back in for the docker group to apply."
    echo ""
}

main
