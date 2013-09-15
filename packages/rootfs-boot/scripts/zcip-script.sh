#!/bin/sh

source /etc/cloud.env

do_init() {
    ifconfig $interface 0.0.0.0
    ifconfig $interface up
    rm /var/run/net/connector.conf
    evo-cloud svc:reload connector
}

do_config() {
    ifconfig $interface $ip
    cat >/var/run/net/connector.conf <<EOF
---
connector:
    address: $ip
    port: 1860
    broadcast: $(ipcalc -b $ip | sed 's/BROADCAST=//')
EOF
    evo-cloud svc:reload connector
}

case $1 in
    init) do_init ;;
    config) do_config ;;
esac