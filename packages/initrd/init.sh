#!/bin/sh

TAG=BOOT_TAG_HERE

TAG_FILE=boot/tag
ROOTFS_FILE=boot/rootfs.sfs
KMODFS_FILE=boot/modules.sfs
KFMWFS_FILE=boot/firmware.sfs
DIAG_SHELL=

# failure handler
failure() {
    while /bin/true; do
        if [ -n "$DIAG_SHELL" ]; then
                echo "Starting diagnostic shell ..."
                /bin/sh
        else
            echo "Rebooting ..."
            /sbin/reboot
            sleep 1
        fi
    done
}

# checked execution
ce() {
	"$@"
    [ $? -eq 0 ] || failure
}

# simple wrapper over modprobe
probe_mods() {
	for mod in $@ ; do
		modprobe $mod >/dev/null 2>&1
	done
}

# detecting hardware and probe modules
detect_hw() {
	local mods=''
	while /bin/true ; do
		local cnt=0
		for a in $(find /sys/devices/ -name modalias -exec cat \{\} \;); do
			local found=0
			for m in $mods; do
				[ "$m" == "$a" ] && found=1 && break
			done
			if [ $found == 0 ]; then
				modprobe -q "$a" 2>/dev/null
				if [ $? == 0 ]; then
					cnt=$((cnt+1))
					mods="$mods $a"
				fi
			fi
		done
		[ $cnt == 0 ] && break
	done
    probe_mods $@
	mdev -s
}

# mount root file system
mount_root() {
    mount -t squashfs /mnt/boot/$ROOTFS_FILE /mnt/root && \
    mount -t squashfs /mnt/boot/$KMODFS_FILE /mnt/root/lib/modules && \
    mount -t squashfs /mnt/boot/$KFMWFS_FILE /mnt/root/lib/firmware && \
    return 0
    return 1
}

# umount root file system
umount_root() {
    mountpoint /mnt/root/lib/firmware && umount /mnt/root/lib/firmware
    mountpoint /mnt/root/lib/modules && umount /mnt/root/lib/modules
    mountpoint /mnt/root && umount /mnt/root    
}

# find and mount boot device
mount_boot() {
    local boot_dev
    for boot_dev in $@ ; do
        mount $boot_dev /mnt/boot -o ro || continue
        local tag=$(cat /mnt/boot/$TAG_FILE 2>/dev/null)
        [ "$tag" == "$TAG" ] && mount_root && return 0
        umount_root
        umount /mnt/boot
    done
    return 1
}

# boot mounted root
boot() {
    umount /sys
    umount /proc
    
    [ -x "/mnt/root/init" ] && ce exec switch_root /mnt/root /init
    [ -x "/mnt/root/linuxrc" ] && ce exec switch_root /mnt/root /linuxrc
    [ -x "/mnt/root/sbin/init" ] && ce exec switch_root /mnt/root /sbin/init
    echo "No init found in root file system!"
    failure
}

# setup network
setup_network() {
    local interfaces=$(grep -E '^[[:space:]]*eth[[:digit:]]+\:' /proc/net/dev | sed -r 's/^[[:space:]]*(eth[[:digit:]]+)\:.+$/\1/')
    for interface in $interfaces ; do
        ifconfig $interface up
        udhcpc -i $interface -q -s /etc/udhcpc-script.sh -t 5 -f -n
    done
}

# mount default file systems
mount -t proc none  /proc
mount -t sysfs none /sys

detect_hw squashfs

BOOTFROM=cdrom
for opt in $(cat /proc/cmdline) ; do
    [ "${opt#bootsrc=}" != "$opt" ] && BOOTFROM=${opt#bootsrc=}
    [ "$opt" == "diagnose" ] && DIAG_SHELL=y
done

boot_from_cdrom() {
    probe_mods isofs
    ce mount_boot /dev/sr0
    boot
}

boot_from_net() {
    setup_network
    mount -t tmpfs none /mnt/boot
    for f in $KMODFS_FILE $KFMWFS_FILE $ROOTFS_FILE ; do
        mkdir -p /mnt/boot/$(dirname $f)
        ce wget $BOOTFROM/$f -O /mnt/boot/$f
    done
    ce mount_root
    boot
}

case $BOOTFROM in
    cdrom) boot_from_cdrom ;;
    *) boot_from_net
esac
