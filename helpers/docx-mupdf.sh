
#!/bin/sh
# Author: Jørgen Bele Reinfjell
# Date: 20.11.2017 [dd.mm.yyyy]
# File: docx-mupdf.sh
# Description: 
#   Converts docx files to pdf using the 'docx2pdf' script, ands opens in mupdf.
# Dependencies: docx2pdf, mupdf

run() {
    of="$(docx2pdf -l - "$1")"
    if [ "$?" -eq 0 ]; then
        printf "Opening: %s" "$of\n"
        mupdf "$of"
    else
        printf "Conversion of \"%s\" failed!\n" "$of"
    fi
}


if [ "$#" -gt 1 ]; then
    # iterate over all arguments, and run in 
    # seperate processes in the background
    while [ -n "$1" ]; do
        run "$1" &
    done
else
    # only run one instance, in the foreground
    run "$1" &
fi
