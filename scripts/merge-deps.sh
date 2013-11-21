#!bin/bash
set -e
set -x

REL=$1
mkdir -p root/lib64

for dep in $_PKGDEPS ; do
    [ "${dep#tc-}" == "$dep" ] || continue
    [ "${dep#rootfs-}" == "$dep" ] || continue
    cp -a $_RELBASE/$dep/$REL/* root/
done
