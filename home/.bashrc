# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
# /etc/omarchy.conf is written by omarchy-dev-link. When absent, force the
# package default instead of preserving a stale inherited dev-link value before
# we decide which rc file to source.
if [[ -f /etc/omarchy.conf ]]; then
  source /etc/omarchy.conf
  export OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
else
  export OMARCHY_PATH=/usr/share/omarchy
fi
source "$OMARCHY_PATH/default/bash/rc"

# Add your own exports, aliases, and functions here.

export MANPAGER='nvim +Man!'
export PATH="$HOME/.config/emacs/bin:$PATH"
export MOZ_ENABLE_WAYLAND=1
BROWSER=firefox

alias new_3.4_Waybar='git clone https://github.com/HANCORE-linux/waybar-themes.git /tmp/repo && cp -rf /tmp/repo/config/V3.4/. ~/.config/waybar && rm -rf /tmp/repo && omarchy-restart-waybar'
alias new_2.0_Waybar='git clone https://github.com/HANCORE-linux/waybar-themes.git /tmp/repo && cp -rf /tmp/repo/config/V2.3/. ~/.config/waybar && rm -rf /tmp/repo && omarchy-restart-waybar'
alias old_Waybar='git clone https://github.com/basecamp/omarchy.git /tmp/repo && cp -rf /tmp/repo/config/waybar/. ~/.config/waybar && rm -rf /tmp/repo && omarchy-restart-waybar'
alias weather='$HOME/Scripts/weather.sh'
alias cls='clear'
alias lit='lazygit'
alias git-pull-all='cd "$HOME/Scripts/" && ./repoPull.sh'
alias vim='nvim'
alias wayload='pkill waybar && waybar &'
alias flash-iso='"$HOME/Documents/scripts/flash-iso.sh"'
alias doom='doom emacs'
alias kali='VBoxManage startvm kali-chaos --type separate'
# Make an alias for invoking commands you use constantly


# alias p='python'
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

# SSH
eval "$(keychain --eval --quiet id_ed25519)"
