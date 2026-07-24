# RC: PowerLevel10k Theme Configuration
# PURPOSE
#   Loads and configures the PowerLevel10k theme.

# Load saved P10k configuration after the theme is registered by Zinit.
if [ -f "$HOME/.p10k.zsh" ] && (( $+functions[p10k] )); then
  source "$HOME/.p10k.zsh"
fi

# Keep a usable prompt when the theme is unavailable.
if (( ! $+functions[p10k] )); then
  PROMPT='%F{blue}%n@%m%f %F{green}%~%f %# '
fi
