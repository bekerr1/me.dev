# Prompt. Shape is unchanged from the old config -- [host] path $ -- with a git
# segment and a failure indicator added. Colors track the kanagawa-dragon
# palette used by nvim and tmux so the whole terminal reads as one theme.

# \[ \] wrap non-printing bytes so readline computes the line width correctly;
# without them, long commands wrap in the wrong column.
_p_host='\[\033[38;5;167m\]'   # dragonRed
_p_dim='\[\033[38;5;242m\]'    # brackets, separators
_p_path='\[\033[38;5;109m\]'   # dragonBlue2
_p_git='\[\033[38;5;108m\]'    # dragonGreen
_p_dirty='\[\033[38;5;180m\]'  # dragonYellow
_p_err='\[\033[38;5;167m\]'
_p_off='\[\033[0m\]'

# Set ME_PROMPT_GIT_DIRTY=0 on machines with huge repos where the working-tree
# scan makes the prompt lag.
: "${ME_PROMPT_GIT_DIRTY:=1}"

_prompt_git() {
  local branch
  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) \
    || branch=$(git rev-parse --short HEAD 2>/dev/null) \
    || return 0

  local mark=
  if [ "$ME_PROMPT_GIT_DIRTY" = 1 ]; then
    # Index-only checks; much cheaper than `git status --porcelain`.
    git diff --quiet --ignore-submodules HEAD 2>/dev/null || mark='*'
  fi

  if [ -n "$mark" ]; then
    printf ' %s(%s%s%s)%s' "$_p_dim" "$_p_dirty" "$branch$mark" "$_p_dim" "$_p_off"
  else
    printf ' %s(%s%s%s)%s' "$_p_dim" "$_p_git" "$branch" "$_p_dim" "$_p_off"
  fi
}

# Terminal/tmux window title: user@host: cwd. Empty on terminals that would
# print the escape sequence literally.
case "$TERM" in
  xterm*|rxvt*|screen*|tmux*|alacritty|ghostty|kitty*)
    _p_title='\[\033]0;\u@\h: \w\007\]' ;;
  *) _p_title='' ;;
esac

_prompt_set() {
  local rc=$?   # must be the very first statement
  local fail=
  [ $rc -ne 0 ] && fail="${_p_err}${rc}${_p_off} "

  PS1="${_p_title}${_p_dim}[${_p_host}\h${_p_dim}]${_p_off} ${_p_path}\w${_p_off}$(_prompt_git) ${fail}${_p_host}\$${_p_off} "
}

# Append rather than assign: conda, direnv and friends also use PROMPT_COMMAND.
case "$PROMPT_COMMAND" in
  *_prompt_set*) ;;
  '') PROMPT_COMMAND='_prompt_set' ;;
  *)  PROMPT_COMMAND="_prompt_set; $PROMPT_COMMAND" ;;
esac

