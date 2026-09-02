# 1. Environment & Directories
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export DOTNET_CLI_HOME="$XDG_DATA_HOME/dotnet"
export GTK2_RC_FILES="$XDG_CONFIG_HOME/gtk-2.0/gtkrc"

export PATH="$HOME/.local/bin:$HOME/.spicetify:$PATH"

# 2. History Configuration
export HISTFILE="$XDG_STATE_HOME/zsh/history"
mkdir -p "$XDG_STATE_HOME/zsh" "$XDG_DATA_HOME/gnupg" 2>/dev/null
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory sharehistory hist_ignore_all_dups
setopt inc_append_history hist_ignore_space hist_find_no_dups

# 3. Shell Options
setopt autocd auto_pushd extended_glob

# 4. Aliases
alias c='clear'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fastfetch='fastfetch --logo-type kitty'
alias config='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'
alias mkdir='mkdir -p'

# Environment & UI Aliases
alias hconf='$EDITOR ~/.config/hypr/hyprland.conf'
alias qs-reload='killall quickshell; quickshell &'
alias wall='awww'

# 5. Auto-completion
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select

# 6. Plugins
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=245"
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

# Bind Up/Down arrows to substring search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# 7. Fastfetch
if command -v fastfetch >/dev/null; then
    fastfetch --logo-type kitty
fi

# 8. Starship Prompt
eval "$(starship init zsh)"