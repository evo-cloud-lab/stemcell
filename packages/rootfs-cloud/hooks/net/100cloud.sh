#!/bin/sh

ACTION=$1
INTERFACE=$2
METHOD=$3
IP=$4
NETMASK=$5
GATEWAY=$6

source /etc/cloud.env

if [ "$METHOD" == "zc" ]; then
    case "$ACTION" in
        if-reset)
            rm /var/run/net/connector.conf
            evo-cloud svc:reload connector
            ;;
        if-config)
            cat >/var/run/net/connector.conf <<EOF
---
connector:
    address: $IP
    port: 1860
    broadcast: "*$(ipcalc -b $IP | sed 's/BROADCAST=//')"
EOF
            evo-cloud svc:reload connector
            ;;
    esac
fi
