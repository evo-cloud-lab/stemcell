#!/bin/sh

TAG=BOOT_TAG_HERE

. /etc/functions.sh

init_setup

if [ -n "$opt_shell" ]; then
    echo "Starting initrd shell, exit will panic"
    exec /bin/sh
fi

test -n "$opt_tag" && TAG="$opt_tag"

init_detect_hw
init_modprobe squashfs

case "$INIT_BOOT_PROTO" in
    cdrom)
        init_ensure init_setup_boot_cdrom
        ;;
    net)
        init_ensure init_setup_boot_net
        ;;
    virtfs)
        init_ensure init_setup_boot_virtfs
        ;;
    *)
        echo "Unknown how to boot"
        init_fail
        ;;
esac

init_boot
