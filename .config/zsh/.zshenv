# Compatibility loader for sessions that still export the previous ZDOTDIR.
if [ -f "$HOME/.zshenv" ]; then
  . "$HOME/.zshenv"
fi
