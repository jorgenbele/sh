.PHONY: install uninstall

install: marks.sh
	echo "WARNING: THIS IS PROBABLY NOT WHAT YOU WANT! READ the comment in marks.sh" 1>&2
	install -m 755 marks.sh ~/bin/marks
uninstall: ~/bin/marks
	rm ~/bin/marks

