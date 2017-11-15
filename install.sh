#!/bin/bash

arguments=$@
for i in ${arguments[@]}; do
    case "$i" in
        rootdir=*)
            ROOTDIR=${i#*=}
            ;;
    esac
done

for i in arc inf lst; do
    if [ ! -d $ROOTDIR/pkg/$i ]; then
        mkdir -p $ROOTDIR/pkg/$i
    fi
done

for i in arc rcp; do
    if [ ! -d $ROOTDIR/src/$i ]; then
        mkdir -p $ROOTDIR/src/$i
    fi
done

install -Dm644 cfg/bld $ROOTDIR/etc/bld.conf
install -Dm644 cfg/apkg $ROOTDIR/etc/apkg.conf
install -Dm644 lib/libapkg.sh $ROOTDIR/lib/apkg/libapkg

for f in $(ls bin); do
    install -Dm755 bin/$f $ROOTDIR/bin/${f//.sh}
done

install -d $ROOTDIR/share/apkg/hooks
install -t $ROOTDIR/share/apkg/proto/ -Dm755 proto/*_*
install -Dm644 proto/RECIPE $ROOTDIR/share/apkg/proto/RECIPE

