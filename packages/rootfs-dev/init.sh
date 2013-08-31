#!/bin/sh

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

# setup network
setup_network() {
    local interfaces=$(grep -E '^[[:space:]]*eth[[:digit:]]+\:' /proc/net/dev | sed -r 's/^[[:space:]]*(eth[[:digit:]]+)\:.+$/\1/')
    for interface in $interfaces ; do
        ifconfig $interface up
        udhcpc -i $interface -q -s /etc/udhcpc-script.sh -t 5 -f -n
    done
}

[ -f /etc/banner ] && cat /etc/banner

# mount default file systems
mount -t proc none  /proc
mount -t sysfs none /sys

detect_hw
probe_mods btrfs

# re-generate /dev
mount -t tmpfs none /dev
mdev -s

# mount fstab
mount -a

setup_network

while /bin/true ; do
    /sbin/getty -n -l /bin/sh console 115200 vt100
done
