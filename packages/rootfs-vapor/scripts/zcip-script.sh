#!/bin/sh

source /etc/scripts/functions.sh

case $1 in
    init)
        net_if_reset $interface zc
        ;;
    config)
        net_if_config $interface zc "$ip" 255.255.0.0
        ;;
esac