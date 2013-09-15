#!/bin/bash

STATEDIR=/var/run/net
STATEFILE=$STATEDIR/${interface}.if

do_bound() {
    cat >$STATEFILE <<EOF
NETIF_STATE=dhcp
NETIF_IP=$ip
NETIF_NETMASK=$subnet
EOF
    test -n "$router" && echo "NETIF_GATEWAY=$router" >>$STATEFILE
    test -n "$dns" && echo "NETIF_DNS=$dns" >>$STATEFILE
}

case $1 in
    bound|renew) do_bound ;;
esac