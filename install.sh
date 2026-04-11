#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

# Idempotent: restow and adopt pre-existing plain files into the package tree
stow --restow --adopt -t ~ bash
stow --restow --adopt -t ~ vim
stow --restow --adopt -t ~ ghostty
stow --restow --adopt -t ~ inshellisense
stow --restow --adopt -t ~ fonts
stow --restow --adopt -t ~ copyq
stow --restow --adopt -t ~ starship
stow --restow --adopt -t ~ atuin

echo "✅ All dotfiles stowed into ~"
