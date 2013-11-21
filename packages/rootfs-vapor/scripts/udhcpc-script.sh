#!/bin/sh

source /etc/scripts/functions.sh

case $1 in
    deconfig)
        net_if_reset $interface dhcp
        ;;
    bound|renew)
        net_if_config $interface dhcp "$ip" "$subnet" "$router" "$dns"
        ;;
esac
