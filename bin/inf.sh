#!/bin/bash
# Copyright (c) 2015-2017 Ali H. Caliskan <ali.h.caliskan@gmail.com>

. /lib/apkg/libapkg

show_pkg_info() {
    if [ -f $PKG_INF_DIR/$_PKG ]; then
        . $PKG_INF_DIR/$_PKG

        printf_green "PKG" "$PKG"
        printf_green "VER" "$VER"
        printf_green "MEM" "$MEM"
    else
        printf_red "error" "$i: no such package"
    fi
}

if [ $# -eq 0 ]; then echo "try $(basename $0) <package>"; exit 1; fi

_PKG=$1

show_pkg_info
