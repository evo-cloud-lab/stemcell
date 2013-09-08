#!/bin/sh

# bring up lo interface
ifconfig lo 127.0.0.1 up

interfaces=$(grep -E '^[[:space:]]*eth[[:digit:]]+\:' /proc/net/dev | sed -r 's/^[[:space:]]*(eth[[:digit:]]+)\:.+$/\1/')
for interface in $interfaces ; do
    initctl emit net-device-added INTERFACE=$interface
done
