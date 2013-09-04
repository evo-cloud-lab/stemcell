#!/bin/bash

set -e
set -x

ROOTDIR=$_BLDDIR/initrd
mkdir -p $ROOTDIR/etc
mkdir -p $ROOTDIR/initrd
mkdir -p $ROOTDIR/mnt/boot
mkdir -p $ROOTDIR/mnt/root

tar -C $ROOTDIR -xf $_RELBASE/$_DEP_ROOTFS_BASE/rootfs.tar

cp -a $_RELBASE/$_DEP_BUSYBOX_INITRD/rel/* $ROOTDIR/

cp $_PKGDIR/udhcpc-script.sh $ROOTDIR/etc/
chmod a+rx $ROOTDIR/etc/udhcpc-script.sh

TAG=$(date '+%Y%m%d%H%M%S')
cp $_PKGDIR/init.sh $ROOTDIR/init
sed -i -r "s/^(TAG=).+\$/\\1$TAG/" $ROOTDIR/init
chmod a+rx $ROOTDIR/init

KVER=$(basename $(find $_RELBASE/$_DEP_KERNEL/lib/modules -mindepth 1 -maxdepth 1 -type d))
MODSRC=$_RELBASE/$_DEP_KERNEL/stripped/lib/modules/$KVER/kernel
MODDST=$ROOTDIR/lib/modules/$KVER/kernel
MODULES='
    drivers/ata
    drivers/net/ethernet
    drivers/net/usb
    drivers/hid/usbhid
    drivers/usb/class
    drivers/usb/host
    drivers/usb/storage
    fs/isofs
    fs/squashfs
    fs/binfmt_misc.ko
    fs/nls/nls_ascii.ko
    fs/nls/nls_iso8859-1.ko
    fs/nls/nls_utf8.ko
'

for m in $MODULES ; do
    basedir=$(dirname $m)
    mkdir -p $MODDST/$basedir
    cp -a $MODSRC/$m $MODDST/$basedir/
done
depmod -b $ROOTDIR $KVER

cd $ROOTDIR
find . | cpio -o -H newc >$_RELDIR/initrd
echo -n "$TAG" >$_RELDIR/tag
$_RELBASE/$_DEP_TC_XZ/bin/xz -c -9 -e -C crc32 $_RELDIR/initrd >$_RELDIR/initrd.xz