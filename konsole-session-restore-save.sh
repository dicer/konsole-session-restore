#!/bin/bash

# Obtains Konsole session states through qdubs and saves them so they can be restored easily
# https://docs.kde.org/trunk5/en/applications/konsole/command-line-options.html
#
# Adapted from https://unix.stackexchange.com/a/593779/41618

COMMAND='' # Default command if there is no command for the tab
XDG_DATA_HOME=${XDG_DATA_HOME:="$HOME/.local/share"}
SAVE_PATH="$XDG_DATA_HOME"/konsole-session-restore
mkdir -p $SAVE_PATH

rm -f "$SAVE_PATH"/*

if [[ "$XDG_SESSION_TYPE" == "wayland" || "$1" == "force" ]] ; then
    pids=$(pgrep 'konsole' -f -u $USER)

    while IFS= read -r pid; do
        if [[ $(readlink -f /proc/$pid/exe) == "/usr/bin/konsole" ]]; then
            WINDOWS=$(qdbus org.kde.konsole-$pid | grep /Windows/ | grep -Eo '[0-9]+')
            if ! [[ ${WINDOWS} ]] ; then
                continue
            fi

            for w in ${WINDOWS}; do
                SESSIONS=$(qdbus org.kde.konsole-$pid /Windows/$w sessionList)
                if ! [[ ${SESSIONS} ]] ; then
                    continue
                fi
                for i in ${SESSIONS}; do
                    FORMAT=$(qdbus org.kde.konsole-$pid /Sessions/$i tabTitleFormat 0)
                    PROCESSID=$(qdbus org.kde.konsole-$pid /Sessions/$i processId)
                    CWD=$(pwdx ${PROCESSID} | sed -e "s/^[0-9]*: //")
                    # Do not record command. Re-running a command automatically looks dangerous to me.
                    #if [[ $(pgrep --parent ${PROCESSID}) ]] ; then
                    #    CHILDPID=$(pgrep --parent ${PROCESSID})
                    #    COMMAND=$(ps -p ${CHILDPID} -o args=)
                    #fi 
                    echo "workdir: ${CWD};; title: ${FORMAT};; command:${COMMAND}" >> "${SAVE_PATH}/${pid}_${w}"
                    COMMAND=''
                done
            done
        fi
    done <<< "$pids"
fi
