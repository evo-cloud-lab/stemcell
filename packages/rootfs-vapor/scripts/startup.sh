#!/bin/sh

. /etc/scripts/start-funcs.sh

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
}

# mount if not mounted
if_not_mounted() {
    local mnt="$1"
    shift;
    mountpoint "$mnt" >/dev/null 2>&1 || mount "$@" "$mnt"
}

# normal startup flow (not in container)
normal_startup() {
    start_parse_kernel_cmdline
    detect_hw
    mdev -s
    mkdir -p /dev/shm
    mount -t tmpfs none /dev/shm
    [ -f /sys/class/net/bonding_masters ] || probe_mods bonding max_bonds=0
}

# startup flow in a container
contained_startup() {
    if_not_mounted /dev/shm -t tmpfs none
}

# mount extra file systems
mount_extra_fs() {
    [ -n "$opt_configmnt" ] && mount "$opt_configmnt" /etc/config
    [ -f /etc/config/fstab ] && mount -a

    # ensure /tmp and /var are writable
    local mnt
    for mnt in /tmp /var ; do
        if touch $mnt/.writable >/dev/null 2>&1 ; then
            rm -f $mnt/.writable >/dev/null 2>&1
        else
            mount -t tmpfs none $mnt
        fi
    done
}

[ -f /etc/banner ] && cat /etc/banner

# mount default file systems
if_not_mounted /proc -t proc none
if_not_mounted /sys -t sysfs none

if start_in_container ; then
    contained_startup
else
    normal_startup
fi

mount_extra_fs

# prepare required file system directories
mkdir -p /var/log/upstart /var/run /var/lib
