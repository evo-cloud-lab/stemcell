#!/bin/sh

INTERFACE=$1

# try dhcp first
udhcpc -f -i $INTERFACE -s /etc/scripts/udhcpc-script.sh -t 20 -T 3 -n

# fallback to autoip
zcip -f $INTERFACE /etc/scripts/zcip-script.sh
