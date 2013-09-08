#!/bin/sh

do_init() {
    ifconfig $interface 0.0.0.0
    ifconfig $interface up
}

do_config() {
    ifconfig $interface $ip
}

case $1 in
    init) do_init ;;
    config) do_config ;;
esac