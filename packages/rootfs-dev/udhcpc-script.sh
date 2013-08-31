#!/bin/sh

do_deconfig() {
    ifconfig $interface 0.0.0.0
    ifconfig $interface up
}

do_bound() {
    ifconfig $interface $ip netmask $subnet
}

case $1 in
    deconfig) do_deconfig ;;
    bound) do_bound ;;
esac