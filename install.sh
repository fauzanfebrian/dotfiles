#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

# Stow all packages into $HOME
stow --adopt -t ~ bash
stow --adopt -t ~ vim
stow --adopt -t ~ ghostty
stow --adopt -t ~ inshellisense
stow --adopt -t ~ fonts

echo "✅ All dotfiles stowed into ~"
