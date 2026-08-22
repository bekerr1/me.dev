# Git. Short aliases only for the commands typed dozens of times a day;
# everything else is a plain `git ...` so muscle memory stays portable.

alias gs='git status --short --branch'
alias gd='git diff'
alias gds='git diff --staged'
alias gb='git branch'
alias gp='git push'
alias gpl='git pull'
alias grc='git rebase --continue'
alias gpc='git cherry-pick --continue'
alias glo='git log --oneline --graph --decorate -20'
alias gls='git log --stat'

ga()  { git add "$@"; }
gap() { git add -p "$@"; }
gc()  { git commit -m "$*"; }
gch() { git checkout "$@"; }

# Rebase interactively onto the default branch (main or master, whichever exists).
gmreb() { git rebase -i "$(git_default_branch)"; }

git_default_branch() {
  local ref b
  ref=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
  if [ -n "$ref" ]; then
    printf '%s\n' "${ref#origin/}"
    return 0
  fi
  for b in main master; do
    if git show-ref --verify --quiet "refs/heads/$b"; then
      printf '%s\n' "$b"
      return 0
    fi
  done
  printf 'main\n'
}

# Pull the default branch without leaving the current one.
pullmain() {
  local cur def
  cur=$(git symbolic-ref --quiet --short HEAD) || return 1
  def=$(git_default_branch)
  git checkout "$def" && git pull --ff-only && git checkout "$cur"
}
