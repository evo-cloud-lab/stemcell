#!/bin/sh

# setup network
setup_network() {
    local interfaces=$(grep -E '^[[:space:]]*eth[[:digit:]]+\:' /proc/net/dev | sed -r 's/^[[:space:]]*(eth[[:digit:]]+)\:.+$/\1/')
    for interface in $interfaces ; do
        ifconfig $interface up
        udhcpc -i $interface -q -s /etc/scripts/udhcpc-script.sh -t 5 -f -n
    done
}

# bring up lo interface
ifconfig lo 127.0.0.1 up

setup_network