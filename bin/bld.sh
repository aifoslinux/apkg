#!/bin/bash -e
# Copyright (c) 2015-2017 Ali H. Caliskan <ali.h.caliskan@gmail.com>

. /etc/bld.conf
. /etc/apkg.conf
. /lib/apkg/libapkg

gitclone_source() {
    GIT_REF=
    if [[ $SRC_URL == *"#commit="* ]]; then
        GIT_URL=${SRC_URL%#commit=*}
        GIT_REF=${SRC_URL#*commit=}
    fi
    printf_green "cloning" "$PKG"
    if [ ! -z $GIT_REF ]; then
        git clone $GIT_URL $SRC_DIR
        (cd $SRC_DIR; git checkout $GIT_REF)
    else
        git clone $SRC_URL $SRC_DIR
    fi
}

download_source() {
    if [ ! -f $SRC_ARC_DIR/$FILE ]; then
        printf_green "downloading" "$FILE"
        curl -L -o $SRC_ARC_DIR/$FILE $SRC_URL
    fi
}

extract_source() {
    opt="--strip-components=1"
    printf_green "extracting" "$FILE"
    case $FILE in
        *.tar.bz2)
            tar -C $SRC_DIR -jxpf $SRC_ARC_DIR/$FILE $opt;;
        *.tar.xz|*.tar.lz|*.tar.gz|*.tgz|*.tar)
            tar -C $SRC_DIR -xpf $SRC_ARC_DIR/$FILE $opt;;
        *.bz2|*.zip)
            bsdtar -C $SRC_DIR -xpf $SRC_ARC_DIR/$FILE $opt;;
        *.gz)
            gunzip -c $SRC_ARC_DIR/$FILE > $SRC_DIR/${FILE%.*};;
    esac
}

strip_symbols() {
    printf_green "stripping" "$PKG_DIR"
    find . -type f 2>/dev/null | while read PKG_FILE; do
        case "$(file -bi "$PKG_FILE")" in
            *application/x-sharedlib*)
                strip --strip-unneeded $PKG_FILE
                ;;
            *application/x-archive*)
                strip --strip-debug $PKG_FILE
                ;;
            *application/x-executable*)
                strip --strip-all $PKG_FILE
                ;;
        esac
    done
}

create_archive() {
    _PKG_INF_DIR=$PKG_INF_DIR
    _PKG_LST_DIR=$PKG_LST_DIR
    PKG_INF_DIR="$PKG_DIR$PKG_INF_DIR"
    PKG_LST_DIR="$PKG_DIR$PKG_LST_DIR"
    PKG_FILE_EXT=$PKG-${VER}-${PKG_EXT}

    mkdir -p $PKG_LST_DIR $PKG_INF_DIR

    printf "PKG=$PKG\n" > $PKG_INF_DIR/$PKG
    printf "VER=$VER\n" >> $PKG_INF_DIR/$PKG

    cd $PKG_DIR

    if [ "$STRIP" = true ]; then strip_symbols; fi

    find ./ | sed 's/.\//\//' | sort > $PKG_LST_DIR/$PKG

    MEM=$(du -bs $PKG_DIR | cut -f1)
    printf "MEM=$MEM\n" >> $PKG_INF_DIR/$PKG

    if [ ! -f "$PKG_INF_DIR/$PKG" ]; then
        printf_red "missing $PKG_INF_DIR/$PKG file"
        exit 1
    fi

    if [ ! -f "$PKG_LST_DIR/$PKG" ]; then
        printf_red "missing $PKG_LST_DIR/$PKG file"
        exit 1
    fi

    printf_green "compressing" "$PKG_FILE_EXT"
    tar -cpJf $PKG_ARC_DIR/$PKG_FILE_EXT ./

    PKG_INF_DIR=$_PKG_INF_DIR
    PKG_LST_DIR=$_PKG_LST_DIR
}

package_source() {
    STRIP=true
    MAKE_FLAGS=true
    BUILD_FLAGS=true

    for option in ${OPT[@]}; do
        if [ "$option" = "!strip" ]; then
            STRIP=false
        elif [ "$option" = "!makeflags" ]; then
            MAKE_FLAGS=false
        elif [ "$option" = "!buildflags" ]; then
            BUILD_FLAGS=false
        fi 
    done

    _PKG_DIR=$PKG_DIR
    _SRC_DIR=$SRC_DIR
    BLD_DIR=$SRC_DIR/.$PKG-$VER
    RCP_DIR=$SRC_RCP_DIR/*/$PKG
    SRC_DIR=$_SRC_DIR/$PKG-$VER
    PKG_DIR=$_PKG_DIR/$PKG-$VER
    BIN_DIR=$PKG_DIR$bindir
    CFG_DIR=$PKG_DIR$cfgdir
    DAT_DIR=$PKG_DIR$datdir
    INC_DIR=$PKG_DIR$incdir
    LIB_DIR=$PKG_DIR$libdir
    RUN_DIR=$PKG_DIR$rundir
    VAR_DIR=$PKG_DIR$vardir

    if [ ! -d $BLD_DIR ]; then mkdir $BLD_DIR; fi
    if [ ! -d $SRC_DIR ]; then mkdir $SRC_DIR; fi

    if [ ! -z $SRC ]; then
        if [[ $SRC == git+* ]]; then
            SRC_URL=${SRC#git+}
            gitclone_source
        else
            case $SRC in
                *::*)
                    SRC_URL=${SRC#*::}
                    FILE=${SRC%::*}
                    ;;
                *)
                    SRC_URL=$SRC
                    FILE=$(basename $SRC)
                    ;;
            esac
            download_source
            extract_source
        fi
    fi

    printf_green "building" $PKG-$VER

    PATCH="patch -Np1 -i $RCP_DIR"

    if [ ! -z $SRC ]; then cd $SRC_DIR; fi

    if [ "$MAKE_FLAGS" = false ]; then unset MAKEFLAGS; fi

    if [ "$BUILD_FLAGS" = false ]; then
        unset CPPFLAGS CFLAGS CXXFLAGS LDFLAGS
    fi

    export CPPFLAGS CFLAGS CXXFLAGS LDFLAGS MAKEFLAGS \
           CARCH CBUILD CHOST CTARGET BLD_DIR RCP_DIR \
           SRC_DIR PKG_DIR BIN_DIR CFG_DIR DAT_DIR INC_DIR \
           LIB_DIR RUN_DIR VAR_DIR PKG VER prefix cfgdir \
           bindir libdir datadir incdir rundir vardir

    if [ -d $PKG_DIR ]; then rm -r $PKG_DIR; fi
    mkdir $PKG_DIR
    build
    rc=$?; if [ ! $rc -eq 0 ] ; then exit 1; fi

    bld_remove_files
    bld_insert_files

    create_archive

    rm -rf $BLD_DIR $PKG_DIR $SRC_DIR
    PKG_DIR=$_PKG_DIR
    SRC_DIR=$_SRC_DIR
    cd $CUR_DIR

    unset -f build
    unset PKG VER SRC RCP_DIR
}

if [ $# -eq 0 ]; then echo "try $(basename $0) <package>"; exit 1; fi

arguments=$@
CUR_DIR=$(pwd)

for i in ${arguments[@]}; do
    if [ -d $SRC_RCP_DIR/$i ]; then
        GRP_LST+="$(find $SRC_RCP_DIR/$i -maxdepth 2 -name RECIPE) "
        arguments=${arguments[@]/$i}
    fi
done

if [ -n "$GRP_LST" ]; then
    GRP_LST=$(for i in $GRP_LST; do echo $i; done | sort)
    arguments+=('grp_pkgs')
fi

for i in ${arguments[@]}; do
    case "$i" in
        grp_pkgs)
            for _pkg in $GRP_LST; do
                RCP_FILE=$_pkg
                . $RCP_FILE
                package_source
            done
            ;;
        *)
            RCP_FILE=$(find $SRC_RCP_DIR/ -maxdepth 2 -name $i)/RECIPE
            if [ -f $RCP_FILE ]; then
                . $RCP_FILE
            else
                printf_red "error" "$i: no such recipe"
                exit 1
            fi
            package_source
            ;;
    esac
done
