#!/bin/bash

#######################################################################
# ~/.bashrc — Linux Mint Developer Setup (Optimized)
#
# Stack: bash, ghostty, vim, starship, atuin, pyenv, golang, nvm, docker
#######################################################################

# ---------------------------------------------------------------------
# 1) Execution Guard
# ---------------------------------------------------------------------
case $- in
    *i*) ;;
      *) return;;
esac

# ---------------------------------------------------------------------
# 2) Core Environment
# ---------------------------------------------------------------------
export EDITOR=vim
export VISUAL=vim
export PAGER=less
export PATH="$HOME/.local/bin:$PATH"

# Load profile if it exists
[ -f ~/.bash_profile ] && source ~/.bash_profile

# ---------------------------------------------------------------------
# 3) Environment Detector
# ---------------------------------------------------------------------
if [[ -n "$PS1" && "${TERM_PROGRAM}" != "vscode" ]]; then
    export IS_MAIN_TERMINAL=true
else
    export IS_MAIN_TERMINAL=false
fi

# ---------------------------------------------------------------------
# 4) Go Toolchain
# ---------------------------------------------------------------------
export GOPATH="${GOPATH:-$HOME/go}"
export GOBIN="$GOPATH/bin"
# Add to path immediately
PATH="$GOBIN:$PATH"
if [ -d /usr/local/go/bin ]; then PATH="/usr/local/go/bin:$PATH"; fi

# ---------------------------------------------------------------------
# 5) History Settings (Bash Fallback)
#    Atuin will override this, but good to have a fallback.
# ---------------------------------------------------------------------
shopt -s histappend cmdhist
HISTSIZE=200000
HISTFILESIZE=400000
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT='%F %T '

# ---------------------------------------------------------------------
# 6) Shell Quality-of-Life
# ---------------------------------------------------------------------
shopt -s checkwinsize
shopt -s cdspell
shopt -s globstar
set -o pipefail

# ---------------------------------------------------------------------
# 7) Colors & Base Aliases
# ---------------------------------------------------------------------
if command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors -b 2>/dev/null || true)"
fi
alias ls='ls --color=auto -h'
alias ll='ls -alF'
alias la='ls -A'
alias grep='grep --color=auto'
alias vi='vim'

# ---------------------------------------------------------------------
# 8) Version Managers (Load Order: Pyenv -> NVM)
# ---------------------------------------------------------------------

# --- Pyenv ---
export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
if [[ -d "$PYENV_ROOT/bin" ]]; then
    PATH="$PYENV_ROOT/bin:$PATH"
    if command -v pyenv >/dev/null 2>&1; then
        eval "$(pyenv init -)"
        if command -v pyenv-virtualenv-init >/dev/null 2>&1; then
            eval "$(pyenv virtualenv-init -)"
        fi
    fi
fi

# --- NVM ---
# Note: NVM is slow. If you want speed, consider switching to 'fnm'.
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# ---------------------------------------------------------------------
# 9) Completions & Shell UX
# ---------------------------------------------------------------------

# Base completions
if [ -r /usr/share/bash-completion/bash_completion ]; then
  . /usr/share/bash-completion/bash_completion
elif [ -r /etc/bash_completion ]; then
  . /etc/bash_completion
fi

# Docker completion
if command -v docker >/dev/null 2>&1 && ! complete -p docker >/dev/null 2>&1; then
  source <(docker completion bash)
fi

# ---------------------------------------------------------------------
# 10) Prompt & Modern Tools (The "Anti-Glitch" Configuration)
# ---------------------------------------------------------------------

# CLEAN PATH: Remove duplicates before initializing the prompt
PATH="$(awk -v RS=: '!a[$0]++{s=s?s RS $0:$0} END{print s}' <<<"$PATH")"

# A) Starship (Replaces manual PS1 logic)
#    This handles Git, Timings, and Status without fighting the terminal.
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
else
    # Fallback if Starship isn't installed
    PS1='\[\e[32m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\$ '
fi

if [ "$IS_MAIN_TERMINAL" = true ]; then
    # B) Atuin (History)
    #    Load AFTER Starship to ensure keybindings adhere correctly.
    if command -v atuin >/dev/null 2>&1; then
        eval "$(atuin init bash)"
    fi

    # C) Inshellisense
    #    WARNING: This tool is the primary cause of Ghostty rendering glitches.
    #    It conflicts with native terminal rendering. Uncomment at your own risk.
    if command -v is >/dev/null 2>&1; then
      eval "$(is init bash)"
    fi
fi

# ---------------------------------------------------------------------
# 11) Application Aliases
# ---------------------------------------------------------------------

# Docker
alias d='docker'
alias dc='docker compose'
alias dps='docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
alias dim='docker images'
alias drm='docker rm'
alias drmi='docker rmi'
alias dlog='docker logs -f --tail=200'

# Git
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gca='git commit --amend --no-edit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -n 20'
alias gco='git checkout'
alias gb='git branch -vv'

# Go / Python
alias gob='go build ./...'
alias got='go test ./...'
alias gor='go run'
alias pipu='python -m pip install --upgrade pip'
alias venv='python -m venv .venv && source .venv/bin/activate'

# System
alias reboot-windows='sudo grub-reboot "Windows Boot Manager (on /dev/nvme0n1p1)" && sudo reboot'
unset -f command_not_found_handle 2>/dev/null || true