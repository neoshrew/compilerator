#!/usr/bin/env bash
set -eu
set -o pipefail

eval $( resize )

DICTFILE="/usr/share/dict/words"
echo -n "Populating words..."
WORDS=( $(grep -P '^[a-z]*$' $DICTFILE | sort -R) )
echo "Done. found ${#WORDS[@]}"

echo -n "Populating files..."
FILES=( $(for i in /{bin,home,lib,usr,var,opt}; do find -L $i -xdev -maxdepth 4 -type f ; done 2>/dev/null) )
echo "Done. found ${#FILES[@]}"

echo -n "Populating directories..."
DIRS=( $(for i in /{bin,home,lib,usr,var,opt}; do find -L $i -xdev -maxdepth 4 -type d ; done 2>/dev/null) )
echo "Done. found ${#DIRS[@]}"

rand() {
    local rand=$(od -A n -t u -N 1 /dev/urandom)
    local fac=${1:-100}
    echo "scale=3;($rand/256)*$fac" | bc
}
randint() {
    printf '%.0f' $(rand "$@")
}

DEFAULT_LIMIT=60
limitstr() {
    local limit=$[ ${2:-$DEFAULT_LIMIT} - 5 ]
    if [ ${#1} -gt $limit ]
    then
        echo -n "${1:0:$limit}..."
    else
        echo -n $1
    fi
}

randword() {
    limitstr ${WORDS[$(randint ${#WORDS[@]})]} ${1:-}
}
randfile() {
    limitstr ${FILES[$(randint ${#FILES[@]})]} ${1:-}
}
randdir() {
    limitstr ${DIRS[$(randint ${#DIRS[@]})]} ${1:-}
}

randcaption() {
    local sel=$( randint 100 )
    if [ $sel -lt 33 ];
    then
        randword
    elif [ $sel -lt 66 ];
    then
        randfile
    else
        randdir
    fi
}

randsleep() {
    sleep $(rand ${1:-0.1})
}

randprogbar() {
    local NSTEPS=${1:-20}
    local SLEEPFAC=${2:-0.1}
    local DIVISION=2 # bar gets 1/DIVISION of cols on left

    local ncols=$(tput cols)
    local ncells=$(printf '%.0f' $(echo "scale=2;${ncols}*(1/${DIVISION})" | bc) )

    local wordspace=$[ $ncols - $ncells - 2 ] #2 for the []s

    local curr_step
    local curr_cell
    local j
    for curr_step in $(seq 1 $NSTEPS);
    do
        curr_cell=$( printf '%.0f' $(echo "scale=2;($curr_step/$NSTEPS)*$ncells" | bc) )

        tput dl1
        echo -n '['
        for j in $(seq 1 $curr_cell); do echo -n '-'; done
        for j in $(seq $curr_cell $(( $ncells - 1 )) ); do echo -n ' '; done
        echo -n ']  '
        randfile $wordspace
        randsleep $SLEEPFAC
    done
}

randprogbar 50 0.05
echo
#tree $(randdir) -L 10
#cat /proc/$$/status | grep '^VmRSS' | grep -o '[0-9]* [a-z]B'