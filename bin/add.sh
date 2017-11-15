#!/bin/bash
# Copyright (c) 2015-2017 Ali H. Caliskan <ali.h.caliskan@gmail.com>

. /etc/apkg.conf
. /lib/apkg/libapkg

install_packages() {
    if [ -f $RCP_FILE ]; then
        . $RCP_FILE
        if [ ! -z "$BAK" ]; then backup_files ${BAK[@]}; unset BAK; fi

        if [ -f "$PKG_ARC_DIR/$PKG-$VER-$PKG_EXT" ]; then
            printf_green "installing" "$PKG-$VER"
            tar -C $ROOTDIR -xpf $PKG_ARC_DIR/$PKG-$VER-$PKG_EXT
        else
            printf_red "error" "$PKG-$VER-$PKG_EXT: no such file"
        fi

        package_log ADD
        unset PKG VER
    else
        if [ -z "$GRP_LST" ]; then
            printf_red "error" "$i: no such recipe"
        fi
    fi
}

if [ $# -eq 0 ]; then echo "try $(basename $0) <package>"; exit 1; fi

arguments=$@

for i in ${arguments[@]}; do
    case "$i" in
        rootdir=*)
            ROOTDIR=${i#*=}
            arguments=${arguments[@]/$i}
            ;;
        *)
            if [ -d $SRC_RCP_DIR/$i ]; then
                GRP_LST+="$(find $SRC_RCP_DIR/$i -maxdepth 2 -name RECIPE) "
                arguments=${arguments[@]/$i}
            fi
            ;;
    esac
done

if [ -n "$GRP_LST" ]; then
    GRP_LST=$(for i in $GRP_LST; do echo $i; done | sort)
    arguments+=('grp_pkgs')
fi

if [[ "$ROOTDIR" != "/" && -d $ROOTDIR ]]; then
    package_do_mount
fi

for i in ${arguments[@]}; do
    case "$i" in
        grp_pkgs)
            for _pkg in $GRP_LST; do
                RCP_FILE=$_pkg
                install_packages
            done
            ;;
        *)
            RCP_FILE=$(find $SRC_RCP_DIR/ -maxdepth 2 -name $i)/RECIPE
            install_packages
            ;;
    esac
done
for i in ${arguments[@]}; do
    case "$i" in
        grp_pkgs)
            for _pkg in $GRP_LST; do
                . $_pkg
                package_setup P_ADD
                package_hooks
                unset PKG VER
            done
            ;;
        *)
            RCP_FILE=$(find $SRC_RCP_DIR/ -maxdepth 2 -name $i)/RECIPE
            if [ -f "$RCP_FILE" ]; then
                . $RCP_FILE
                package_setup P_ADD
                package_hooks
                unset PKG VER
            fi
            ;;
    esac
done

if [[ "$ROOTDIR" != "/" && -d $ROOTDIR ]]; then
    package_no_mount
fi
