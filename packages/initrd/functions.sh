INIT_TAG_FILE=boot/tag
INIT_ROOTFS_FILE=boot/rootfs.sfs
INIT_KMODFS_FILE=boot/modules.sfs
INIT_KFMWFS_FILE=boot/firmware.sfs

# failure handler
init_fail() {
    while /bin/true ; do
        if [ -n "$opt_diag" ]; then
                echo "Starting diagnostic shell ..."
                /bin/sh
        else
            echo "Rebooting ..."
            /sbin/reboot
            sleep 1
        fi
    done
}

# ensure successful execution
init_ensure() {
	"$@"
    test $? -eq 0 || init_fail
}

# simple wrapper over modprobe
init_modprobe() {
	for mod in $@ ; do
		modprobe $mod >/dev/null 2>&1
	done
}

# detecting hardware and probe modules
init_detect_hw() {
	local mods=''
	while /bin/true ; do
		local loaded=0
		for a in $(find /sys/devices/ -name modalias -exec cat {} \;) ; do
			local found=0
			for m in $mods; do
				test "$m" == "$a" && found=1 && break
			done
			if [ $found -eq 0 ]; then
				modprobe -q "$a" 2>/dev/null
				if [ $? -eq 0 ]; then
					loaded=1
					mods="$mods $a"
				fi
			fi
		done
		test $loaded -eq 0 && break
	done
	mdev -s
}

# mount root file system
init_mount_root() {
    mount -t squashfs /mnt/boot/$INIT_ROOTFS_FILE /mnt/root || return 1
    test -n "$opt_no_kmodfs" || mount -t squashfs /mnt/boot/$INIT_KMODFS_FILE /mnt/root/lib/modules || return 1
    test -n "$opt_no_kfmwfs" || mount -t squashfs /mnt/boot/$INIT_KFMWFS_FILE /mnt/root/lib/firmware || return 1
    # ensure /dev on rootfs is writable
    mountpoint /mnt/dev >/dev/null 2>&1 && umount /mnt/dev
    mount -t tmpfs none /mnt/dev
    cp -a /mnt/root/dev/* /mnt/dev/
    mount --move /mnt/dev /mnt/root/dev
}

# umount root file system
init_umount_root() {
    local mnt
    for mnt in /mnt/root/dev /mnt/root/lib/firmware /mnt/root/lib/modules /mnt/root ; do
        mountpoint "$mnt" >/dev/null 2>&1 && umount "$mnt"
    done
}

# find and mount boot device
init_mount_boot() {
    local boot_dev
    for boot_dev in $@ ; do
        mount $boot_dev /mnt/boot -o ro || continue
        local tag=$(cat /mnt/boot/$INIT_TAG_FILE 2>/dev/null)
        test "$tag" == "$TAG" && init_mount_root && return 0
        init_umount_root
        umount /mnt/boot
    done
    return 1
}

# boot mounted root
init_boot() {
    umount /sys
    umount /proc

    #[ -x "/mnt/root/init" ] && init_ensure exec switch_root /mnt/root /init
    #[ -x "/mnt/root/linuxrc" ] && init_ensure exec switch_root /mnt/root /linuxrc
    #[ -x "/mnt/root/sbin/init" ] && init_ensure exec switch_root /mnt/root /sbin/init
    init_ensure exec switch_root /mnt/root /sbin/init
    echo "No init found in root file system!"
    init_fail
}

# setup network
init_setup_network() {
    local interfaces=$(grep -E '^[[:space:]]*eth[[:digit:]]+\:' /proc/net/dev | sed -r 's/^[[:space:]]*(eth[[:digit:]]+)\:.+$/\1/')
    for interface in $interfaces ; do
        ifconfig $interface up
        udhcpc -i $interface -q -s /etc/udhcpc-script.sh -t 5 -f -n
    done
}

# setup for booting from cdrom
init_setup_boot_cdrom() {
    init_modprobe isofs
    init_mount_boot /dev/sr0
}

# setup for booting from net
init_setup_boot_net() {
    local url="$INIT_BOOT_VALUE"
    mount -t tmpfs none /mnt/boot || return 1
    for f in $INIT_KMODFS_FILE $INIT_KFMWFS_FILE $INIT_ROOTFS_FILE ; do
        mkdir -p /mnt/boot/$(dirname $f)
        if ! wget "$url/$f" -O /mnt/boot/$f ; then
            umount /mnt/boot
            return 1
        fi
    done
    init_mount_root
}

# setup for booting from virtfs
init_setup_boot_virtfs() {
    init_modprobe 9p
    mount -t 9p -o ro,trans=virtio "$INIT_BOOT_VALUE" /mnt/boot || return 1
    init_mount_root
}

# parse options
init_parse_options() {
    for opt in $(cat /proc/cmdline) ; do
        test "${opt#init-}" == "$opt" && continue
        local name="${opt%%=*}" val="${opt#*=}"
        name="${name#init-}"
        name="${name//-/_}"
        test -z "$val" && val=1
        eval "opt_$name=$val"
    done
}

# init boot protocol
init_boot_protocol() {
    INIT_BOOT_PROTO="$1"
    if [ -n "$opt_boot" ]; then
        INIT_BOOT_PROTO="${opt_boot%%:*}"
        INIT_BOOT_VALUE="${opt_boot#*:}"
    fi
}

# basic setup
init_setup() {
    # mount default file systems
    mount -t proc none  /proc
    mount -t sysfs none /sys

    init_parse_options
    test -n "$opt_file_tag"    && INIT_TAG_FILE="$opt_file_tag"
    test -n "$opt_file_rootfs" && INIT_ROOTFS_FILE="$opt_file_rootfs"
    test -n "$opt_file_kmodfs" && INIT_KMODFS_FILE="$opt_file_kmodfs"
    test -n "$opt_file_kfmwfs" && INIT_KFMWFS_FILE="$opt_file_kfmwfs"

    init_boot_protocol cdrom
}
