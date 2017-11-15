#!/bin/bash
# Copyright (c) 2015-2017 Ali H. Caliskan <ali.h.caliskan@gmail.com>

. /lib/apkg/libapkg

show_pkg_list() {
    if [ -f $PKG_LST_DIR/$_PKG ]; then
        for ln in $(cat $PKG_LST_DIR/$_PKG); do
            printf_green "$_PKG" "$ln"
        done
    else
        printf_red "error" "$i: no such package"
    fi
}

if [ $# -eq 0 ]; then echo "try $(basename $0) <package>"; exit 1; fi

_PKG=$1

show_pkg_list
