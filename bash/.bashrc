#!/bin/bash

#######################################################################
# ~/.bashrc — Linux Mint Developer Setup (Optimized)
#
# Stack: bash, ghostty, vim, starship, pyenv, golang, nvm, docker
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
PATH="$GOBIN:$PATH"
if [ -d /usr/local/go/bin ]; then PATH="/usr/local/go/bin:$PATH"; fi

# ---------------------------------------------------------------------
# 5) History Settings
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
# 8) Pyenv
# ---------------------------------------------------------------------
export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
case ":${PATH}:" in *":${PYENV_ROOT}/bin:"*) ;; *)
  PATH="${PYENV_ROOT}/bin:${PATH}"
  ;;
esac

if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"
  if command -v pyenv-virtualenv-init >/dev/null 2>&1; then
    eval "$(pyenv virtualenv-init -)"
  fi
fi

# ---------------------------------------------------------------------
# 9) NVM
# ---------------------------------------------------------------------
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  # shellcheck source=/dev/null
  . "$NVM_DIR/nvm.sh"
fi
if [[ -s "$NVM_DIR/bash_completion" ]]; then
  # shellcheck source=/dev/null
  . "$NVM_DIR/bash_completion"
fi

# ---------------------------------------------------------------------
# 10) Completions & Shell UX
# ---------------------------------------------------------------------
if [ -r /usr/share/bash-completion/bash_completion ]; then
  # shellcheck source=/dev/null
  . /usr/share/bash-completion/bash_completion
elif [ -r /etc/bash_completion ]; then
  # shellcheck source=/dev/null
  . /etc/bash_completion
fi

if command -v docker >/dev/null 2>&1 && ! complete -p docker >/dev/null 2>&1; then
  # shellcheck source=/dev/null
  source <(docker completion bash)
fi

# ---------------------------------------------------------------------
# 11) PATH deduplication (pure Bash, no subprocess)
# ---------------------------------------------------------------------
_dedup_path() {
  local _rest="${PATH:-}" _dir _out="" _seen="|"
  # Trailing colon ensures the final segment is processed
  _rest="${_rest}:"
  while [[ -n "$_rest" ]]; do
    _dir="${_rest%%:*}"
    _rest="${_rest#*:}"
    [[ -z "$_dir" ]] && continue
    case "${_seen}" in *"|${_dir}|"*) ;; *)
      _seen="${_seen}${_dir}|"
      _out="${_out:+${_out}:}${_dir}"
      ;;
    esac
  done
  PATH="${_out}"
}
_dedup_path
unset -f _dedup_path

# ---------------------------------------------------------------------
# 12) Prompt & Modern Tools
# ---------------------------------------------------------------------
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
else
    PS1='\[\e[32m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\$ '
fi


# ---------------------------------------------------------------------
# 13) Application Aliases
# ---------------------------------------------------------------------
alias d='docker'
alias dc='docker compose'
alias dps='docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
alias dim='docker images'
alias drm='docker rm'
alias drmi='docker rmi'
alias dlog='docker logs -f --tail=200'

alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gca='git commit --amend --no-edit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -n 20'
alias gco='git checkout'
alias gb='git branch -vv'

alias gob='go build ./...'
alias got='go test ./...'
alias gor='go run'
alias pipu='python -m pip install --upgrade pip'
alias venv='python -m venv .venv && source .venv/bin/activate'

alias reboot-windows='sudo grub-reboot "Windows Boot Manager (on /dev/nvme0n1p1)" && sudo reboot'
unset -f command_not_found_handle 2>/dev/null || true


# Added by Antigravity CLI installer
export PATH="/home/fauzan/.local/bin:$PATH"
