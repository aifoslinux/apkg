. /etc/apkg.conf

prefix=/
bindir=/bin
cfgdir=/etc
datdir=/share
incdir=/include
libdir=/lib
rundir=/run
vardir=/var

PKG_DIR=/pkg
PKG_ARC_DIR=$PKG_DIR/arc
PKG_INF_DIR=$PKG_DIR/inf
PKG_LST_DIR=$PKG_DIR/lst
PKG_RUN_DIR=$PKG_DIR/run
SRC_DIR=/src
SRC_ARC_DIR=$SRC_DIR/arc
SRC_RCP_DIR=$SRC_DIR/rcp

printf_green() {
    printf "\033[32;1m  $1 \033[0m $2\n" 
}

printf_red() {
    printf "\033[31;1m  $1 \033[0m $2\n"
}

backup_files() {
    for f in "$@"; do
        if [ -f "$ROOTDIR/$f" ]; then
            cp $ROOTDIR/$f $ROOTDIR/${f}.apkg
        fi
    done
}

bld_remove_files() {
    rm -f $DAT_DIR/info/dir
    rm -f $LIB_DIR/charset.alias
}

bld_insert_files() {
    for f in P_ADD A_DEL P_DEL A_UPD P_UPD; do
        if [ -f $RCP_DIR/$f ]; then
            install -Dm755 $RCP_DIR/$f $PKG_DIR/$PKG_RUN_DIR/$PKG/$f
        fi
    done
}

package_do_mount() {
    for d in /dev /proc /sys; do
        if [ ! -d $ROOTDIR/$d ]; then mkdir -p $ROOTDIR/$d; fi
        mount -o bind $d ${ROOTDIR}${d}
    done
}

package_no_mount() {
    for d in /dev /proc /sys; do
        umount ${ROOTDIR}${d}
    done
}

package_log() {
    if [[ "$1" = "ADD" && ! -d $ROOTDIR/$vardir/log ]]; then mkdir -p $ROOTDIR/$vardir/log; fi
    echo "[$(date +%Y-%m-%d) $(date +%H:%M)] [$1] $PKG ($VER)" >> $ROOTDIR/$vardir/log/apkg.log
}

package_setup() {
    if [ "$ROOTDIR" != "/" ]; then
        if [ -f $ROOTDIR/$PKG_RUN_DIR/$PKG/$1 ]; then
            chroot $ROOTDIR /bin/sh -c "$PKG_RUN_DIR/$PKG/$1"
        fi
    else
        if [ -f $PKG_RUN_DIR/$PKG/$1 ]; then
            $PKG_RUN_DIR/$PKG/$1
        fi
    fi
}

package_hooks() {
    if [ -d $ROOTDIR/$datdir/apkg/hooks ]; then
        for hook in $(ls $ROOTDIR/$datdir/apkg/hooks); do
            if [ -f $ROOTDIR/$datdir/apkg/hooks/$hook ]; then
                . $ROOTDIR/$datdir/apkg/hooks/$hook
                PKG_LST=$(grep "$TARGET" $ROOTDIR/$PKG_LST_DIR/$PKG)
                if [ ! -z "$PKG_LST" ]; then
                    if [ "$ROOTDIR" != "/" ]; then
                        chroot $ROOTDIR /bin/sh -c "$RUNCMD"
                    else
                        $RUNCMD
                    fi
                fi
            fi
        done
    fi
}
