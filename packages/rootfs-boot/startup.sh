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

[ -f /etc/banner ] && cat /etc/banner

# mount default file systems
mountpoint /proc || mount -t proc  none /proc
mountpoint /sys  || mount -t sysfs none /sys
mountpoint /dev/shm || mount -t tmpfs none /dev/shm

detect_hw
probe_mods btrfs

# mount fstab
[ -f /etc/fstab ] && mount -a

# notify other services
initctl emit sys-boot
initctl emit sys-init
