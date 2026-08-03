# qlty: user-local CLI path and completion.
if [ -d "$HOME/.qlty" ]; then
	export QLTY_INSTALL="$HOME/.qlty"
	export PATH="$QLTY_INSTALL/bin:$PATH"
	[ -s "/usr/local/share/zsh/site-functions/_qlty" ] && source "/usr/local/share/zsh/site-functions/_qlty"
fi
