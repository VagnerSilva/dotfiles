# fzf-marks: bookmark integration for the Zinit-managed plugin.
_fzf_marks_plugin="${ZINIT[PLUGINS_DIR]}/urbainvaes---fzf-marks/fzf-marks.plugin.zsh"
if [ -f "$_fzf_marks_plugin" ]; then
	FZF_MARKS_COMMAND="fzf --exact --select-1 --nth=1 --delimiter=' : '"
	FZF_MARKS_DELETE=ctrl-r
	source "$_fzf_marks_plugin"
fi
unset _fzf_marks_plugin
