#!/bin/bash
# Reset the apply log at the start of each chezmoi apply.

mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}"
: > "${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles-apply.log"
