#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
    source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...
#
alias vimdiff='nvim -d'
export EDITOR='nvim'
export HOMEBREW_CASK_OPTS="--appdir=/Applications"
# export TERM=xterm-256color
[[ $TMUX = "" ]] && export TERM="xterm-256color"

export CFLAGS=-Qunused-arguments
export CPPFLAGS=-Qunused-arguments

export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Applications/Server.app/Contents/ServerRoot/usr/bin:/Applications/Server.app/Contents/ServerRoot/usr/sbin:/usr/local/sbin:$PATH"
export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

export GOPATH="${HOME}/Workspace/go"
export GOBIN="${HOME}/Workspace/go/bin"
export PATH="$PATH:$GOBIN"
export PATH="$PATH:/usr/local/opt/go/libexec/bin"
export PATH="$PATH:${HOME}/Library/Android/sdk/platform-tools"
export PATH=/Library/Developer/Toolchains/swift-latest.xctoolchain/usr/bin:"${PATH}"
export JAVA_HOME=$(/usr/libexec/java_home)

alias subl="open -a 'Sublime Text'"
alias git=hub
alias fuck='$(thefuck $(fc -ln -1))'
alias FUCK='fuck'
alias mux=tmuxinator
alias tml="tmux list-sessions"
alias tma="tmux -2 attach -t $1"
alias tmk="tmux kill-session -t $1"
alias phs="iex -S mix phoenix.server"
alias vl='v -l'
alias timeout='gtimeout'

[[ -s "${HOME}/.gvm/scripts/gvm" ]] && source "${HOME}/.gvm/scripts/gvm"
[[ -s $HOME/.nvm/nvm.sh ]] && . $HOME/.nvm/nvm.sh  # This loads NVM
. `brew --prefix`/etc/profile.d/z.sh
[[ -s "$HOME/.kiex/scripts/kiex" ]] && source "$HOME/.kiex/scripts/kiex"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
source dnvm.sh

if type vim >/dev/null 2>/dev/null; then
    alias vi=vim
    alias vim=nvim
fi

# ==================

source "${HOME}/.zplugin/common-aliases.plugin.zsh"
source "${HOME}/.zplugin/elixir.plugin.zsh"

# Android
export ANDROID_NDK="${HOME}/Library/Android/sdk/ndk-bundle"
export ANDROID_SDK="${HOME}/Library/Android/sdk"
export ANDROID_HOME=$ANDROID_SDK

set-window-title() {
    window_title="\033]0;${PWD##*/}\007"
    echo -ne "$window_title"
}

PR_TITLEBAR=''
set-window-title
add-zsh-hook precmd set-window-title

# --------------------------------------------------------------------
# Setup cdg function
# --------------------------------------------------------------------
unalias cdg 2> /dev/null
cdg() {
    local dest_dir=$(cdscuts_glob_echo | fzf )
    if [[ $dest_dir != '' ]]; then
        cd "$dest_dir"
    fi
}
export cdg > /dev/null

# Elm

alias em='elm make'
alias er='elm repl'
alias epi='elm package install'

# Go alias
alias gt='gometalinter --concurrency=4 --disable-all --enable=gofmt --enable=vet --enable=vetshadow --enable=errcheck --enable=golint --vendor --deadline=5m --sort=path --exclude=request/ --exclude=response/ ./...'

# --------------------------------------------------------------------
# todo.sh
# --------------------------------------------------------------------

# alias t='todo.sh'

export TODOTXT_DEFAULT_ACTION=ls
alias t='todo.sh -d ~/.todo.cfg'

export PINK='\\033[38;5;211m'
export ORANGE='\\033[38;5;203m'
export SKYBLUE='\\033[38;5;111m'
export MEDIUMGREY='\\033[38;5;246m'
export LAVENDER='\\033[38;5;183m'
export TAN='\\033[38;5;179m'
export FOREST='\\033[38;5;22m'
export MAROON='\\033[38;5;52m'
export HOTPINK='\\033[38;5;198m'
export MINTGREEN='\\033[38;5;121m'
export LIGHTORANGE='\\033[38;5;215m'
export LIGHTRED='\\033[38;5;203m'
export JADE='\\033[38;5;35m'
export LIME='\\033[38;5;154m'

### background colors
export PINK_BG='\\033[48;5;211m'
export ORANGE_BG='\\033[48;5;203m'
export SKYBLUE_BG='\\033[48;5;111m'
export MEDIUMGREY_BG='\\033[48;5;246m'
export LAVENDER_BG='\\033[48;5;183m'
export TAN_BG='\\033[48;5;179m'
export FOREST_BG='\\033[48;5;22m'
export MAROON_BG='\\033[48;5;52m'
export HOTPINK_BG='\\033[48;5;198m'
export MINTGREEN_BG='\\033[48;5;121m'
export LIGHTORANGE_BG='\\033[48;5;215m'
export LIGHTRED_BG='\\033[48;5;203m'
export JADE_BG='\\033[48;5;35m'
export LIME_BG='\\033[48;5;154m'

### extra attributes
export UNDERLINE='\\033[4m'

# ------------------
export MYVIMRC=~/.config/nvim/init.vim
export ELIXIR_SERVER='/usr/local/share/src/alchemist-server'
export FZF_DEFAULT_OPTS='--bind alt-j:down,alt-k:up'

# export SSL_CERT_FILE=/usr/local/etc/openssl/cert.pem
export HOMEBREW_GITHUB_API_TOKEN="84aae8d4f6e53eea7b0cc1eea93d40698d141304"
