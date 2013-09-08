#!/bin/sh

do_deconfig() {
    ifconfig $interface 0.0.0.0
    ifconfig $interface up
}

do_bound() {
    ifconfig $interface $ip netmask $subnet
    [ -n "$router" ] && route add default gw $router
    if [ -n "$dns" ]; then
        echo >/etc/resolv.conf
        for s in $dns ; do
            echo "nameserver $s" >>/etc/resolv.conf
        done
    fi
}

case $1 in
    deconfig) do_deconfig ;;
    bound|renew) do_bound ;;
esac