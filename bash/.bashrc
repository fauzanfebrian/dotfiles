#!/bin/bash

#######################################################################
# ~/.bashrc — macOS Developer Setup
#
# Stack: bash 5.x (Homebrew), ghostty, vim, starship, fzf, pyenv,
#        golang, nvm, docker
# Pyenv and NVM are lazy-loaded on first use (see wrapper functions).
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
export PROMPT_COMMAND="history -a; history -n; history -w"
export NODE_EXTRA_CA_CERTS="$HOME/.certs/ZscalerRootCA.pem"
export AWS_CA_BUNDLE="$HOME/.certs/ZscalerRootCA.pem"
export REQUESTS_CA_BUNDLE="$HOME/.certs/ZscalerRootCA.pem"

# ---------------------------------------------------------------------
# 3) Homebrew
# ---------------------------------------------------------------------
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ---------------------------------------------------------------------
# 4) Go Toolchain
# ---------------------------------------------------------------------
export GOPATH="${GOPATH:-$HOME/go}"
export GOBIN="$GOPATH/bin"
PATH="$GOBIN:$PATH"

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
shopt -s globstar 2>/dev/null

# ---------------------------------------------------------------------
# 7) Colors & Base Aliases
# ---------------------------------------------------------------------
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced
alias ls='ls -h'
alias ll='ls -alF'
alias la='ls -A'
alias grep='grep --color=auto'
alias vi='vim'

# ---------------------------------------------------------------------
# 8) Pyenv (lazy) — from Homebrew; versions live under ~/.pyenv by default
# ---------------------------------------------------------------------
export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
if ! command -v pyenv >/dev/null 2>&1; then
  case ":${PATH}:" in *":${PYENV_ROOT}/bin:"*) ;; *)
    PATH="${PYENV_ROOT}/bin:${PATH}"
    ;;
  esac
fi

_lazy_pyenv_init() {
  unset -f pyenv python python3 pip pip3 _lazy_pyenv_init
  if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init -)"
    if command -v pyenv-virtualenv-init >/dev/null 2>&1; then
      eval "$(pyenv virtualenv-init -)"
    fi
  fi
}

pyenv() {
  _lazy_pyenv_init
  pyenv "$@"
}

python() {
  _lazy_pyenv_init
  command python "$@"
}

python3() {
  _lazy_pyenv_init
  command python3 "$@"
}

pip() {
  _lazy_pyenv_init
  command pip "$@"
}

pip3() {
  _lazy_pyenv_init
  command pip3 "$@"
}

# ---------------------------------------------------------------------
# 9) NVM (lazy) — no nvm.sh at startup
# ---------------------------------------------------------------------
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

_lazy_nvm_init() {
  unset -f nvm node npm npx _lazy_nvm_init
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    . "$NVM_DIR/nvm.sh"
  fi
  if [[ -s "$NVM_DIR/bash_completion" ]]; then
    . "$NVM_DIR/bash_completion"
  fi
}

nvm() {
  _lazy_nvm_init
  nvm "$@"
}

node() {
  _lazy_nvm_init
  command node "$@"
}

npm() {
  _lazy_nvm_init
  command npm "$@"
}

npx() {
  _lazy_nvm_init
  command npx "$@"
}

# ---------------------------------------------------------------------
# 10) Completions
# bash-completion@2 needs Bash ≥ 4.2 ([[ -v ... ]]). macOS /bin/bash is 3.2;
# use Homebrew bash as login shell, or completions are skipped here.
# ---------------------------------------------------------------------
if [[ "${BASH_VERSINFO[0]}" -gt 4 ]] || [[ "${BASH_VERSINFO[0]}" -eq 4 && "${BASH_VERSINFO[1]}" -ge 2 ]]; then
  export BASH_COMPLETION_COMPAT_DIR="/opt/homebrew/etc/bash_completion.d"
  if [[ -r "/opt/homebrew/share/bash-completion/bash_completion" ]]; then
    source "/opt/homebrew/share/bash-completion/bash_completion"
  fi
  if command -v docker >/dev/null 2>&1 && ! complete -p docker >/dev/null 2>&1; then
    source <(docker completion bash)
  fi
fi

# ---------------------------------------------------------------------
# 11) PATH deduplication (pure Bash, no subprocess)
# ---------------------------------------------------------------------
_dedup_path() {
  local _rest="${PATH:-}" _dir _out="" _seen="|"
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

if command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --bash)"
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
