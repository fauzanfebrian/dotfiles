#############################################
# ~/.bashrc — Linux Mint Developer Setup (Final)
# Stack: bash, ghostty, vim, inshellisense,
#        atuin, pyenv, golang, nvm, docker
# Goals: readable prompt, Atuin-compatible history,
#        integrated duration timer, clean environment.
#############################################

# ------------------------------------------------------------
# 1) Only run for interactive shells
# ------------------------------------------------------------
case $- in
  *i*) ;;        # interactive: continue
  *) return;;    # non-interactive: stop here
esac

# ------------------------------------------------------------
# 2) Basic environment
# ------------------------------------------------------------
export EDITOR=vim
export VISUAL=vim
export PAGER=less
PATH="$HOME/.local/bin:$PATH"

# ------------------------------------------------------------
# 3) Go toolchain
# ------------------------------------------------------------
export GOPATH="${GOPATH:-$HOME/go}"
export GOBIN="$GOPATH/bin"
PATH="$GOBIN:$PATH"
if [ -d /usr/local/go/bin ]; then PATH="/usr/local/go/bin:$PATH"; fi

# Optional: deduplicate PATH entries (idempotent)
PATH="$(awk -v RS=: '!a[$0]++{s=s?$0 RS s:$0} END{print s}' <<<"$PATH")"

# ------------------------------------------------------------
# 4) History (Atuin handles most of this)
# ------------------------------------------------------------
shopt -s histappend cmdhist
HISTSIZE=200000
HISTFILESIZE=400000
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT='%F %T '

# ------------------------------------------------------------
# 5) Shell QoL toggles
# ------------------------------------------------------------
shopt -s checkwinsize   # auto update LINES/COLUMNS
shopt -s cdspell        # fix minor typos in cd
shopt -s globstar       # enable ** recursive globbing
set -o pipefail         # fail pipeline on error

# ------------------------------------------------------------
# 6) Colors & aliases
# ------------------------------------------------------------
if command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors -b 2>/dev/null || true)"
fi
alias ls='ls --color=auto -h'
alias ll='ls -alF'
alias la='ls -A'
alias grep='grep --color=auto'
alias vi='vim'

# ------------------------------------------------------------
# 7) Atuin & inshellisense
# ------------------------------------------------------------
# Load Atuin early (adds preexec/precmd hooks)
if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init bash)"
fi

# inshellisense: must be initialized last so it doesn’t steal Tab
if command -v is >/dev/null 2>&1; then
  is init bash | sed '/^$/d' >> /tmp/.is_init.$$ && source /tmp/.is_init.$$ && rm /tmp/.is_init.$$
fi

# ------------------------------------------------------------
# 8) Bash completion (git, docker, etc.)
# ------------------------------------------------------------
if [ -r /usr/share/bash-completion/bash_completion ]; then
  . /usr/share/bash-completion/bash_completion
elif [ -r /etc/bash_completion ]; then
  . /etc/bash_completion
fi

# Docker completion if not already provided
if command -v docker >/dev/null 2>&1 && ! complete -p docker >/dev/null 2>&1; then
  source <(docker completion bash)
fi

# Git prompt helpers (branch/status extras)
for __gp in \
  /usr/share/git-core/contrib/completion/git-prompt.sh \
  /usr/share/git/completion/git-prompt.sh \
  /etc/bash_completion.d/git-prompt \
  /usr/lib/git-core/git-sh-prompt
do
  [ -r "$__gp" ] && . "$__gp" && break
done
unset __gp

# Minimal branch fallback if no __git_ps1
__git_branch_fallback() { git rev-parse --abbrev-ref HEAD 2>/dev/null || true; }

# ------------------------------------------------------------
# 9) pyenv (Python)
# ------------------------------------------------------------
if command -v pyenv >/dev/null 2>&1; then
  export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
  eval "$(pyenv init -)"
  if command -v pyenv-virtualenv-init >/dev/null 2>&1; then
    eval "$(pyenv virtualenv-init -)"
  fi
fi

# ------------------------------------------------------------
# 10) nvm (Node)
# ------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# ------------------------------------------------------------
# 11) Timer hooks (Atuin-safe)
# ------------------------------------------------------------
# These integrate with bash-preexec rather than DEBUG traps.
# They record command durations cleanly and don’t overwrite Atuin hooks.
__timer_preexec() { __last_cmd_start="$EPOCHREALTIME"; }
__timer_precmd() {
  if [[ -n "$__last_cmd_start" ]]; then
    __last_cmd_dur="$(awk -v now="$EPOCHREALTIME" -v st="$__last_cmd_start" 'BEGIN{print now-st}')"
  else
    __last_cmd_dur=""
  fi
}

# Defensive hook registration (keeps Atuin’s intact)
if ! declare -p preexec_functions >/dev/null 2>&1; then
  declare -a preexec_functions=()
fi
if ! declare -p precmd_functions >/dev/null 2>&1; then
  declare -a precmd_functions=()
fi
[[ " ${preexec_functions[*]} " == *" __timer_preexec "* ]] || preexec_functions+=(__timer_preexec)
[[ " ${precmd_functions[*]} " == *" __timer_precmd "* ]]   || precmd_functions+=(__timer_precmd)

# Helper: format seconds into readable strings
__fmt_seconds() {
  awk -v s="$1" 'BEGIN{
    if (s == "") exit;
    if (s < 1)       printf("%.0fms", s*1000);
    else if (s < 60) printf("%.2fs", s);
    else             { m=int(s/60); s-=60*m; printf("%dm%02.0fs", m, s); }
  }'
}

# ------------------------------------------------------------
# 12) Prompt builder (Cobalt2-flavored)
# ------------------------------------------------------------
__prompt_command() {
  local EXIT=${__LAST_EXIT:-0}
  local dur=""
  if [[ -n "$__last_cmd_dur" ]]; then
    dur="$(__fmt_seconds "$__last_cmd_dur")"
  fi

  # Colors (Cobalt2 tone)
  if tput setaf 1 >/dev/null 2>&1; then
    local RESET=$(tput sgr0)
    local Y=$(tput setaf 3)
    local C=$(tput setaf 6)
    local P=$(tput setaf 5)
    local B=$(tput setaf 4)
    local G=$(tput setaf 2)
    local R=$(tput setaf 1)
  else
    local RESET='\[\e[0m\]'
    local Y='\[\e[33m\]'; C='\[\e[36m\]'; P='\[\e[35m\]'
    local B='\[\e[34m\]'; G='\[\e[32m\]'; R='\[\e[31m\]'
  fi

  # Optional segments
  local hostpart=" ${B}\h${RESET}"   # always show device name
  local venvpart=""
  [[ -n "$VIRTUAL_ENV" ]] && venvpart=" ${P}($(basename "$VIRTUAL_ENV"))${RESET}"
  local gitpart=""
  if declare -F __git_ps1 >/dev/null; then
    gitpart="$(__git_ps1 ' ('%s')')"
    [[ -n "$gitpart" ]] && gitpart=" ${Y}${gitpart:2:-1}${RESET}"
  else
    local b="$(__git_branch_fallback)"
    [[ -n "$b" ]] && gitpart=" ${Y}${b}${RESET}"
  fi

  # Status & duration
  local statuspart=$([[ $EXIT -eq 0 ]] && echo "${G}✓${RESET}" || echo "${R}✗${EXIT}${RESET}")
  local durpart=""
  [[ -n "$dur" ]] && durpart=" ${C}${dur}${RESET}"

  # Directory
  local dirpart="${B}\w${RESET}"

  PS1="${statuspart}${durpart}${hostpart}${venvpart}${gitpart} ${dirpart}\n${Y}\u${RESET} ${C}❯${RESET} "
}

# ------------------------------------------------------------
# 13) PROMPT_COMMAND: merge safely with Atuin
# ------------------------------------------------------------
if [[ -n "${PROMPT_COMMAND}" ]]; then
  PROMPT_COMMAND="__LAST_EXIT=\$?; __prompt_command; ${PROMPT_COMMAND}"
else
  PROMPT_COMMAND="__LAST_EXIT=\$?; __prompt_command"
fi

# ------------------------------------------------------------
# 14) Docker aliases
# ------------------------------------------------------------
alias d='docker'
alias dc='docker compose'
alias dps='docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
alias dim='docker images'
alias drm='docker rm'
alias drmi='docker rmi'
alias dlog='docker logs -f --tail=200'

# ------------------------------------------------------------
# 15) Git aliases
# ------------------------------------------------------------
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gca='git commit --amend --no-edit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -n 20'
alias gco='git checkout'
alias gb='git branch -vv'

# ------------------------------------------------------------
# 16) Go / Python helpers
# ------------------------------------------------------------
alias gob='go build ./...'
alias got='go test ./...'
alias gor='go run'
alias pipu='python -m pip install --upgrade pip'
alias venv='python -m venv .venv && . .venv/bin/activate'

# ------------------------------------------------------------
# 17) Misc
# ------------------------------------------------------------
alias reboot-windows='sudo grub-reboot "Windows Boot Manager (on /dev/nvme0n1p1)" && sudo reboot'
unset -f command_not_found_handle 2>/dev/null || true

