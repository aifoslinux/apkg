#!/bin/bash
# Copyright (c) 2015-2017 Ali H. Caliskan <ali.h.caliskan@gmail.com>

. /lib/apkg/libapkg

check_owners() {
    if [ -n "$PKG_FILE" ]; then
        owners=$(grep "$PKG_FILE" $PKG_LST_DIR/*)
        for owner in $owners; do
            if [ "$PKG_FILE" = "${owner#*:}" ]; then
                _owner=${owner#$PKG_LST_DIR/}
                printf_green "  ${_owner%:*}  " "${owner#*:}"
            fi
        done
    fi
}

if [ $# -eq 0 ]; then echo "try $(basename $0) <file>"; exit 1; fi

PKG_FILE=$1

check_owners
