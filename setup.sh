#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

# Stow all packages into $HOME
stow -t ~ bash
stow -t ~ vim
stow -t ~ ghostty
stow -t ~ inshellisense
stow -t ~ fonts

echo "✅ All dotfiles stowed into ~"
