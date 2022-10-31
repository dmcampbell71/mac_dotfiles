# Personal modifications for zsh
#
# CHANGELOG
#
# 26-Dec-2019   dave   - created

autoload -U colors && colors # enables colors in prompt

#
# Echos a username/host string when connected over SSH (empty otherwise)
#
ssh_info() {
	[[ "$SSH_CONNECTION" != '' ]] && echo '%(!.%{$fg[red]%}.%{$fg[yellow]%})%n%{$reset_color%}@%{$fg[green]%}%m%{$reset_color%}:' || echo ''
}

#
# Echos information about Git repository status when inside a Git repository
#
git_info() {

    # Exit if not inside a Git repository
    ! git rev-parse --is-inside-work-tree > /dev/null 2>&1 && return

    # Git branch/tag, or name-rev if on detached head
    local GIT_LOCATION=${$(git symbolic-ref -q HEAD || git name-rev --name-only --no-undefined --always HEAD)#(refs/heads/|tags/)}

    local AHEAD="%{$fg[red]%}⇡NUM%{$reset_color%}"
    local BEHIND="%{$fg[cyan]%}⇣NUM%{$reset_color%}"
    local MERGING="%{¡$fg[magenta]%}⚡︎%{$reset_color%}"
    local UNTRACKED="%{$fg[red]%}●%{$reset_color%}"
    local MODIFIED="%{$fg[yellow]%}●%{$reset_color%}"
    local STAGED="%{$fg[green]%}●%{$reset_color%}"

    local -a DIVERGENCES
    local -a FLAGS

    local NUM_AHEAD="$(git log --oneline @{u}.. 2> /dev/null | wc -l | tr -d ' ')"
    if [ "$NUM_AHEAD" -gt 0 ]; then
        DIVERGENCES+=( "${AHEAD//NUM/$NUM_AHEAD}" )
    fi

    local NUM_BEHIND="$(git log --oneline ..@{u} 2> /dev/null | wc -l | tr -d ' ')"
    if [ "$NUM_BEHIND" -gt 0 ]; then
        DIVERGENCES+=( "${BEHIND//NUM/$NUM_BEHIND}" )
    fi

    local GIT_DIR="$(git rev-parse --git-dir 2> /dev/null)"
    if [ -n $GIT_DIR ] && test -r $GIT_DIR/MERGE_HEAD; then
        FLAGS+=( "$MERGING" )
    fi

    if [[ -n $(git ls-files --other --exclude-standard 2> /dev/null) ]]; then
        FLAGS+=( "$UNTRACKED" )
    fi

    if ! git diff --quiet 2> /dev/null; then
        FLAGS+=( "$MODIFIED" )
    fi

    if ! git diff --cached --quiet 2> /dev/null; then
        FLAGS+=( "$STAGED" )
    fi

    local -a GIT_INFO
    GIT_INFO+=( "±" )
    [ -n "$GIT_STATUS" ] && GIT_INFO+=( "$GIT_STATUS" )
    [[ ${#DIVERGENCES[@]} -ne 0 ]] && GIT_INFO+=( "${(j::)DIVERGENCES}" )
    [[ ${#FLAGS[@]} -ne 0 ]] && GIT_INFO+=( "${(j::)FLAGS}" )
    GIT_INFO+=( "$GIT_LOCATION%{$reset_color%}" )
    echo "${(j: :)GIT_INFO}"

}

#
# PROMPT
#
setopt prompt_subst          # allow funky stuff in prompt
  #color="blue"
  #if [ "$USER" = "root" ]; then
  #	color="red"              # root is red, user is blue
  #fi
PS1='$(ssh_info)%(?.%F{green}√.%F{red}?%?)%f %F{cyan}%2~%f %# '
RPS1='$(git_info)'

#
# HISTORY
#
HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
HISTSIZE=2000
SAVEHIST=1000

setopt EXTENDED_HISTORY
# share history across multiple zsh sessions
setopt SHARE_HISTORY
# append to history
setopt APPEND_HISTORY
# adds commands as they are typed, not at shell exit
setopt INC_APPEND_HISTORY

# expire duplicates first
setopt HIST_EXPIRE_DUPS_FIRST
# do not store duplicates
setopt HIST_IGNORE_DUPS
# ignore duplicates when searching
setopt HIST_FIND_NO_DUPS
# removes blank lines from history
setopt HIST_REDUCE_BLANKS

#
# ALIASES
#

alias ls='ls -aG'
alias ll='\ls -lG'
alias tree='tree -aCF'

#
#
#

export PATH=$HOME/bin:$PATH
bindkey -v

if [ -f ~/.zsh_custom ]; then
    source ~/.zsh_custom
fi

exec ssh-agent zsh
