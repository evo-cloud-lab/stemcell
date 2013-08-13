#!/bin/bash

set -e
set -x

ROOTFS_FILE=$1

ROOTDIR=$_BLDDIR/isoroot
mkdir -p $ROOTDIR/boot
mkdir -p $ROOTDIR/isolinux

KERNEL_DIR=$_RELBASE/$_DEP_KERNEL
INITRD_DIR=$_RELBASE/$_DEP_INITRD
ISOLNX_DIR=$_RELBASE/$_DEP_SYSLINUX/usr/share/syslinux

cp $KERNEL_DIR/bzImage              $ROOTDIR/boot/vmlinuz
cp $KERNEL_DIR/modules.squashfs     $ROOTDIR/boot/modules.sfs
cp $KERNEL_DIR/firmware.squashfs    $ROOTDIR/boot/firmware.sfs
cp $INITRD_DIR/initrd.xz            $ROOTDIR/boot/initrd
cp $INITRD_DIR/tag                  $ROOTDIR/boot/tag
cp $ROOTFS_FILE                     $ROOTDIR/boot/rootfs.sfs

cp $ISOLNX_DIR/isolinux.bin $ROOTDIR/isolinux/
cp $ISOLNX_DIR/ldlinux.c32  $ROOTDIR/isolinux/
cp $_PKGDIR/isolinux.cfg    $ROOTDIR/isolinux/

mkisofs -o $_RELDIR/install.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table $ROOTDIR