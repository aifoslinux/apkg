#!/bin/bash
# Copyright (c) 2015-2017 Ali H. Caliskan <ali.h.caliskan@gmail.com>

. /etc/apkg.conf
. /lib/apkg/libapkg

a_del_run_hooks() {
    package_setup A_DEL
    if [ -f $ROOTDIR/$PKG_RUN_DIR/$PKG/P_DEL ]; then
        cp $ROOTDIR/$PKG_RUN_DIR/$PKG/P_DEL{,.bak}
        cp $ROOTDIR/$PKG_INF_DIR/$PKG{,.bak}
        cp $ROOTDIR/$PKG_LST_DIR/$PKG{,.bak}
    fi
    unset PKG VER
}

p_del_run_hooks() {
    mv $ROOTDIR/$PKG_RUN_DIR/$PKG/{P_DEL.bak,P_DEL}
    package_setup P_DEL; rm -r $ROOTDIR/$PKG_RUN_DIR/$PKG
    find $ROOTDIR/$PKG_DIR -depth -type d -empty -delete

    package_hooks
    rm $ROOTDIR/$PKG_INF_DIR/$PKG $ROOTDIR/$PKG_LST_DIR/$PKG
    unset PKG VER
}

remove_packages() {
    if [ -f "$ROOTDIR/$INF_FILE" ]; then
        . $ROOTDIR/$INF_FILE
    else
        printf_red "error" "$i: no such package"
    fi
    if [ -f "$ROOTDIR/$PKG_LST_DIR/$PKG" ]; then
        printf_green "removing" "$PKG-$VER"
        PKG_FILE_LST=$(tac $ROOTDIR$PKG_LST_DIR/$PKG)

        for L in $PKG_FILE_LST; do
            if [ -L $ROOTDIR/$L ]; then unlink $ROOTDIR/$L
            elif [ -f $ROOTDIR/$L ]; then rm -f $ROOTDIR/$L
            elif [ "$L" = "/" ]; then continue
            elif [ -d $ROOTDIR/$L ]; then find $ROOTDIR/$L -maxdepth 0 -type d -empty -delete
            fi
        done

        package_log DEL
        unset PKG VER
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
    esac
done

if [ -n "$GRP_LST" ]; then
    GRP_LST=$(for i in $GRP_LST; do echo $i; done | sort)
    arguments+=('grp_pkgs')
fi

for i in ${arguments[@]}; do
    case "$i" in
        grp_pkgs)
            for _pkg in $GRP_LST; do
                . $ROOTDIR/$PKG_INF_DIR/$(basename ${_pkg%/RECIPE})
                a_del_run_hooks
            done
            ;;
        *)
            if [ -f "$ROOTDIR/$PKG_INF_DIR/$i" ]; then
                . $ROOTDIR/$PKG_INF_DIR/$i
                a_del_run_hooks
            fi
            ;;
    esac
done
for i in ${arguments[@]}; do
    case "$i" in
        grp_pkgs)
            for _pkg in $GRP_LST; do
                INF_FILE=$PKG_INF_DIR/$(basename ${_pkg%/RECIPE})
                remove_packages
            done
            ;;
        *)
            INF_FILE=$PKG_INF_DIR/$i
            remove_packages
            ;;
    esac
done
for i in ${arguments[@]}; do
    case "$i" in
        grp_pkgs)
            for _pkg in $GRP_LST; do
                if [ -f $ROOTDIR/$PKG_INF_DIR/$(basename ${_pkg%/RECIPE}).bak ]; then
                    rename .bak '' $ROOTDIR/$PKG_INF_DIR/$(basename ${_pkg%/RECIPE}).bak
                    rename .bak '' $ROOTDIR/$PKG_LST_DIR/$(basename ${_pkg%/RECIPE}).bak
                    . $ROOTDIR/$PKG_INF_DIR/$(basename ${_pkg%/RECIPE})
                    p_del_run_hooks
                fi
            done
            ;;
        *)
            if [ -f $ROOTDIR/$PKG_INF_DIR/${i}.bak ]; then
                rename .bak '' $ROOTDIR/$PKG_INF_DIR/${i}.bak
                rename .bak '' $ROOTDIR/$PKG_LST_DIR/${i}.bak
                . $ROOTDIR/$PKG_INF_DIR/$i
                p_del_run_hooks
            fi
            ;;
    esac
done
