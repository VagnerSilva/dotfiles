# Environment: SDKMAN
# Modeline {{
#	vi: foldmarker={{,}} filetype=zsh foldmethod=marker foldlevel=0 tabstop=4 shiftwidth=4:
# }}

# Documentation {{
# PURPOSE
#   Initializes SDKMAN for managing multiple versions of Java and other JVM-based tools.
#
# RESPONSIBILITIES
#   ✔ Source SDKMAN initialization script
#   ✔ Set SDKMAN_DIR to XDG-compliant location
#
# LOADED FROM
#   .zprofile (login shells)
# }}

export SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"

if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
  source "$SDKMAN_DIR/bin/sdkman-init.sh"
fi
