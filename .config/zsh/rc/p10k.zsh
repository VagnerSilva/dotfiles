# RC: PowerLevel10k Theme Configuration
# PURPOSE
#   Loads and configures the PowerLevel10k theme.

# Load PowerLevel10k theme
if [ -f "$HOME/.zsh/themes/powerlevel10k/powerlevel10k.zsh-theme" ]; then
  source "$HOME/.zsh/themes/powerlevel10k/powerlevel10k.zsh-theme"
fi

# Load saved P10k configuration
if [ -f "$HOME/.p10k.zsh" ]; then
  source "$HOME/.p10k.zsh"
fi

# Fallback prompt if P10k theme not loaded
PROMPT='%F{blue}%n@%m%f %F{green}%~%f %# '
