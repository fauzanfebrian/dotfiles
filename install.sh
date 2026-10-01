#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

stow --restow --adopt -t ~ bash
stow --restow --adopt -t ~ vim
stow --restow --adopt -t ~ ghostty
stow --restow --adopt -t ~ starship
stow --restow --adopt -t ~ claude

echo "All dotfiles stowed into ~"
