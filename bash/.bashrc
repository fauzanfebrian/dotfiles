#######################################################################
# ~/.bashrc — Linux Mint Developer Setup
#
# Stack: bash, ghostty, vim, inshellisense, atuin, pyenv, golang, nvm, docker
# Philosophy: A clean, performant, and informative two-line prompt that
#             integrates version managers, command timing, and git status
#             without feeling cluttered.
#######################################################################

# ---------------------------------------------------------------------
# 1) Execution Guard
#    Exit immediately if the shell is not interactive.
# ---------------------------------------------------------------------
case $- in
    *i*) ;;        # This is an interactive shell, so continue.
      *) return;;    # This is not interactive, so stop here.
esac

# ---------------------------------------------------------------------
# 2) Core Environment
#    Set default applications and extend the PATH.
# ---------------------------------------------------------------------
export EDITOR=vim
export VISUAL=vim
export PAGER=less
PATH="$HOME/.local/bin:$PATH"

# ---------------------------------------------------------------------
# 2.1) Environment Detector
#      Determines if we are in a full-featured terminal or a basic one (like in an IDE).
# ---------------------------------------------------------------------
if [[ -n "$PS1" && "${TERM_PROGRAM}" != "vscode" ]]; then
    # This is likely a primary, user-facing terminal (like Ghostty).
    export IS_MAIN_TERMINAL=true
else
    # This is likely a basic, integrated terminal (VS Code, Cursor, etc.).
    export IS_MAIN_TERMINAL=false
fi

# ---------------------------------------------------------------------
# 3) Go Toolchain
#    Ensure Go binaries are available in the PATH.
# ---------------------------------------------------------------------
export GOPATH="${GOPATH:-$HOME/go}"
export GOBIN="$GOPATH/bin"
PATH="$GOBIN:$PATH"
if [ -d /usr/local/go/bin ]; then PATH="/usr/local/go/bin:$PATH"; fi

# Idempotently remove duplicate entries from the PATH.
PATH="$(awk -v RS=: '!a[$0]++{s=s?s RS $0:$0} END{print s}' <<<"$PATH")"

# ---------------------------------------------------------------------
# 4) History Configuration
#    Set up history to be large and clean. Atuin will largely manage this.
# ---------------------------------------------------------------------
shopt -s histappend cmdhist
HISTSIZE=200000
HISTFILESIZE=400000
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT='%F %T '

# ---------------------------------------------------------------------
# 5) Shell Quality-of-Life Toggles
# ---------------------------------------------------------------------
shopt -s checkwinsize   # Automatically update LINES/COLUMNS on window resize.
shopt -s cdspell        # Fix minor typos when using 'cd'.
shopt -s globstar       # Enable recursive globbing with '**'.
set -o pipefail         # A pipeline's exit code is the last command's to fail.

# ---------------------------------------------------------------------
# 6) Colors & Base Aliases
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
# 7) Version Managers (NVM & Pyenv)
#    Load these first to correctly set up the PATH for other tools.
# ---------------------------------------------------------------------

# --- 7.1) pyenv (Python) ---
if command -v pyenv >/dev/null 2>&1; then
  export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
  eval "$(pyenv init -)"
  if command -v pyenv-virtualenv-init >/dev/null 2>&1; then
    eval "$(pyenv virtualenv-init -)"
  fi
fi

# --- 7.2) nvm (Node) ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# ---------------------------------------------------------------------
# 8) Completion Framework & Specialist Tools
#    Load order is critical: Base framework first, then specialists.
# ---------------------------------------------------------------------

# --- 8.1) Load Base Bash Completion Framework ---
if [ -r /usr/share/bash-completion/bash_completion ]; then
  . /usr/share/bash-completion/bash_completion
elif [ -r /etc/bash_completion ]; then
  . /etc/bash_completion
fi

# --- 8.2) Load Specialist Tools (Atuin & Inshellisense) ---
# Load Atuin (for advanced history and its own completions)
if [ "$IS_MAIN_TERMINAL" = true ]; then
  if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init bash)"
  fi

  # Load Inshellisense LAST to ensure it wins the Tab key binding.
  if command -v is >/dev/null 2>&1; then
    eval "$(is init bash)"
  fi
fi

# --- 8.3) (Optional) Manually source other completions ---
# Docker completion if not already provided by the base framework
if command -v docker >/dev/null 2>&1 && ! complete -p docker >/dev/null 2>&1; then
  source <(docker completion bash)
fi

# ---------------------------------------------------------------------
# 9) Git Prompt Helpers
# ---------------------------------------------------------------------
for __gp in \
  /usr/share/git-core/contrib/completion/git-prompt.sh \
  /usr/share/git/completion/git-prompt.sh \
  /etc/bash_completion.d/git-prompt \
  /usr/lib/git-core/git-sh-prompt
do
  [ -r "$__gp" ] && . "$__gp" && break
done
unset __gp

# Minimal branch fallback if the official __git_ps1 function isn't found
__git_branch_fallback() { git rev-parse --abbrev-ref HEAD 2>/dev/null || true; }

# ---------------------------------------------------------------------
# 10) Command Timer Hooks (Atuin-safe)
# ---------------------------------------------------------------------
if [ "$IS_MAIN_TERMINAL" = true ]; then
  __timer_preexec() {
      # Record the start time of a command before it executes.
      __last_cmd_start="$EPOCHREALTIME"
  }
  __timer_precmd() {
      # Before the prompt is drawn, calculate the duration of the last command.
      if [[ -n "$__last_cmd_start" ]]; then
          __last_cmd_dur="$(awk -v now="$EPOCHREALTIME" -v st="$__last_cmd_start" 'BEGIN{print now-st}')"
      else
          __last_cmd_dur=""
      fi
  }

  # Defensively register our hooks into the preexec/precmd function arrays.
  # This ensures we don't overwrite hooks set by other tools like Atuin.
  if ! declare -p preexec_functions >/dev/null 2>&1; then
    declare -a preexec_functions=()
  fi
  if ! declare -p precmd_functions >/dev/null 2>&1; then
    declare -a precmd_functions=()
  fi
  [[ " ${preexec_functions[*]} " != *" __timer_preexec "* ]] && preexec_functions+=(__timer_preexec)
  [[ " ${precmd_functions[*]} " != *" __timer_precmd "* ]]   && precmd_functions+=(__timer_precmd)

  # Helper function to format seconds into a human-readable string (ms, s, m s).
  __fmt_seconds() {
    awk -v s="$1" 'BEGIN{
      if (s == "") exit;
      if (s < 1)       printf("%.0fms", s*1000);
      else if (s < 60) printf("%.2fs", s);
      else             { m=int(s/60); s-=60*m; printf("%dm%02.0fs", m, s); }
    }'
  }
fi

# ---------------------------------------------------------------------
# 11) Prompt Builder (Cobalt2-inspired theme)
# ---------------------------------------------------------------------
if [ "$IS_MAIN_TERMINAL" = true ]; then
  # ------------------------------------------------------------
# 12) Prompt builder (Layout: Info on Top)
# ------------------------------------------------------------
  __prompt_command() {
    local EXIT=${__LAST_EXIT:-0}
    local dur=""
    if [[ -n "$__last_cmd_dur" ]]; then
      dur="$(__fmt_seconds "$__last_cmd_dur")"
    fi

    # Colors (sama seperti sebelumnya)
    if tput setaf 1 >/dev/null 2>&1; then
      local RESET=$(tput sgr0); local Y=$(tput setaf 3); local C=$(tput setaf 6); local P=$(tput setaf 5)
      local B=$(tput setaf 4); local G=$(tput setaf 2); local R=$(tput setaf 1)
    else
      local RESET='\[\e[0m\]'; local Y='\[\e[33m\]'; local C='\[\e[36m\]'; local P='\[\e[35m\]'
      local B='\[\e[34m\]'; local G='\[\e[32m\]'; local R='\[\e[31m\]'
    fi

    # --- Segments ---
    local hostpart="${B}\h${RESET}"
    local venvpart=""; [[ -n "$VIRTUAL_ENV" ]] && venvpart=" ${P}($(basename "$VIRTUAL_ENV"))${RESET}"
    local gitpart=""
    if declare -F __git_ps1 >/dev/null; then
      local branch_name; branch_name="$(__git_ps1 '%s')"
      [[ -n "$branch_name" ]] && gitpart=" ${Y} ${branch_name}${RESET}"
    fi

    local statuspart=$([[ $EXIT -eq 0 ]] && echo "${G}✓${RESET}" || echo "${R}✗${EXIT}${RESET}")
    local durpart=""; [[ -n "$dur" ]] && durpart=" ${C}${dur}${RESET}"
    local dirpart="${B}\w${RESET}"
    local userpart="${Y}\u${RESET}"

    # --- Assemble the Prompt (Logika Baru) ---
    # Baris 1: Path direktori, lalu info git.
    PS1="${dirpart}${gitpart}\n"
    # Baris 2: Status, Durasi, Host, Venv, User, dan prompt.
    PS1+="${statuspart}${durpart}${venvpart} ${userpart}@${hostpart} ${C}❯${RESET} "
  }
else
  __prompt_command() {
    PS1='\[\e[32m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\$ '
  }
fi

# ---------------------------------------------------------------------
# 12) PROMPT_COMMAND Execution
#     Safely merge our prompt builder with other tools' hooks (like Atuin).
# ---------------------------------------------------------------------
if [[ -n "${PROMPT_COMMAND}" ]]; then
  # If PROMPT_COMMAND is already set, append our function before it.
  PROMPT_COMMAND="__LAST_EXIT=\$?; __prompt_command; ${PROMPT_COMMAND}"
else
  # Otherwise, just set it.
  PROMPT_COMMAND="__LAST_EXIT=\$?; __prompt_command"
fi

# =====================================================================
#                         A L I A S E S
# =====================================================================

# ---------------------------------------------------------------------
# 13) Docker Aliases
# ---------------------------------------------------------------------
alias d='docker'
alias dc='docker compose'
alias dps='docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
alias dim='docker images'
alias drm='docker rm'
alias drmi='docker rmi'
alias dlog='docker logs -f --tail=200'

# ---------------------------------------------------------------------
# 14) Git Aliases
# ---------------------------------------------------------------------
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gca='git commit --amend --no-edit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -n 20'
alias gco='git checkout'
alias gb='git branch -vv'

# ---------------------------------------------------------------------
# 15) Go / Python Helpers
# ---------------------------------------------------------------------
alias gob='go build ./...'
alias got='go test ./...'
alias gor='go run'
alias pipu='python -m pip install --upgrade pip'
alias venv='python -m venv .venv && source .venv/bin/activate'

# ---------------------------------------------------------------------
# 16) Miscellaneous
# ---------------------------------------------------------------------
alias reboot-windows='sudo grub-reboot "Windows Boot Manager (on /dev/nvme0n1p1)" && sudo reboot'

# Unset the annoying "command not found" handler from Mint/Ubuntu.
unset -f command_not_found_handle 2>/dev/null || true