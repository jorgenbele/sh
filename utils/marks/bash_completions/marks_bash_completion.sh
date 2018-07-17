# File: marks_bash_completion.sh
# Date: 17.07.2018 [dd.mm.yyyy]
# Author: Jørgen Bele Reinfjell
# Description: Bash shell completion for 'marks.sh'.

_marks() {
        local cur opts
        COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"
        opts="$(env | grep 'mark' | grep "${cur}" | awk -F '=' '{print $1}' | cut -b 6-)"
        COMPREPLY=($(compgen -W "${opts}" -- ${cur}))

}

complete -F _marks marks
