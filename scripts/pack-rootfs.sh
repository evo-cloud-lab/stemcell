#!/bin/bash
set -e
set -x

# fix /lib as 64-bit system uses /lib64
if ! [ -h root/lib ] ; then
    for d in root/lib/* ; do
        name=$(basename "$d")
        if [ -d "root/lib64/$name" ] ; then
            mv -f "$d"/* "root/lib64/$name/"
            rmdir "$d"
        else
            mv -f "$d" "root/lib64/"
        fi
    done
    rmdir root/lib
    ln -sf lib64 root/lib
fi

# make a /usr link
test -h root/usr || ln -sf / root/usr

$_RELBASE/$_DEP_TC_SQUASHFS/mksquashfs root $_RELDIR/rootfs.squashfs \
    -comp xz -no-xattrs -all-root -noappend -no-progress
