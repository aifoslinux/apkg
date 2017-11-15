#!/bin/bash
# Copyright (c) 2015-2017 Ali H. Caliskan <ali.h.caliskan@gmail.com>

. /etc/apkg.conf
. /lib/apkg/libapkg

update_packages() {
    if [ -f "$ROOTDIR/$INF_FILE" ] && [ -f "$RCP_FILE" ]; then
        . $ROOTDIR/$INF_FILE; INF_VER=$VER; unset VER
        . $RCP_FILE; RCP_VER=$VER; unset VER

        VER=$(echo -e "$RCP_VER\n$INF_VER" | sort -V | tail -n1)

        if [ "$RCP_VER" != "$INF_VER" ]; then
            if [ "$RCP_VER" = "$VER" ]; then
                package_setup A_UPD

                if [ ! -z "$BAK" ]; then backup_files ${BAK[@]}; unset BAK; fi

                printf_green "updating" "$PKG ($INF_VER -> $RCP_VER)"
                RN=$ROOTDIR/$PKG_LST_DIR/$PKG; cp $RN $RN.bak
                if [ -f "$PKG_ARC_DIR/$PKG-$RCP_VER-$PKG_EXT" ]; then
                    tar -C $ROOTDIR -xpf $PKG_ARC_DIR/$PKG-$RCP_VER-$PKG_EXT

                    TMP_FILE=$(mktemp $ROOTDIR/tmp/apkg.XXXXXXXXXX)
                    PKG_FILE_LST=$(comm -23 <(sort $RN.bak) <(sort $RN))
                    for L in $PKG_FILE_LST; do
                        echo $L >> $TMP_FILE
                    done
                    PKG_FILE_LST=$(tac $TMP_FILE)

                    for L in $PKG_FILE_LST; do
                        if [ -L $ROOTDIR/$L ]; then unlink $ROOTDIR/$L
                        elif [ -f $ROOTDIR/$L ]; then rm -f $ROOTDIR/$L
                        elif [ "$L" = "/" ]; then continue
                        elif [ -d $ROOTDIR/$L ]; then find $ROOTDIR/$L -maxdepth 0 -type d -empty -delete
                        fi
                    done

                    rm $RN.bak $TMP_FILE

                    package_setup P_UPD
                    package_hooks
                    package_log UPD
                    unset PKG VER
                else
                    printf_red "error" "$PKG-$RCP_VER-$PKG_EXT: no such file"
                fi
            fi
        fi
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
                INF_FILE=$PKG_INF_DIR/$(basename ${_pkg%/RECIPE})
                RCP_FILE=$_pkg
                update_packages
            done
            ;;
        *)
            INF_FILE=$PKG_INF_DIR/$i
            RCP_FILE=$(find $SRC_RCP_DIR/ -maxdepth 2 -name $i)/RECIPE
            update_packages
            ;;
    esac
done

if [[ "$ROOTDIR" != "/" && -d $ROOTDIR ]]; then
    package_no_mount
fi
