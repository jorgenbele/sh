.PHONY: install uninstall

install: marks_bash_completion.sh
	install marks_bash_completion.sh `pkg-config --variable=completionsdir bash-completion`/marks
uninstall: `pkg-config --variable=completionsdir bash-completion`/marks

