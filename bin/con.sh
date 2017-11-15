#!/bin/bash
# Copyright (c) 2015-2017 Ali H. Caliskan <ali.h.caliskan@gmail.com>

. /lib/apkg/libapkg

check_conflicts() {
    tmpfile=$(mktemp /tmp/pm.XXXXXXXXXX)

    cat $PKG_LST_DIR/* | sort -n | uniq -d > $tmpfile
    for i in $(cat $tmpfile); do
        if [ ! -d "$i" ]; then
            if [ ! -f "$i" ]; then continue; fi
            _con=$(grep "$i" $PKG_LST_DIR/*)
            for ln in $_con; do
                __con=${ln#$PKG_LST_DIR/}
                printf_red "  ${__con%:*}  " "${__con#*:}"
            done
        fi
    done

    rm $tmpfile
}

check_conflicts
