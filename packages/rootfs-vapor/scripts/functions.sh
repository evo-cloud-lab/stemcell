run_hook() {
    local base="/etc/scripts/hooks/$1"
    shift
    test -d "$base" || return 0
    for hook in $(find "$base" -mindepth 1 -maxdepth 1 -follow -perm +555 -exec basename {} \; | sort); do
        "$base/$hook" "$@"
    done
}

net_if_reset() {
    local interface=$1 method=$2
    ifconfig $interface 0.0.0.0
    ifconfig $interface up
    run_hook net if-reset $interface $method
}

net_if_config() {
    local interface=$1 method=$2
    local ip=$3 netmask=$4 gateway=$5 dns="$6"
    ifconfig $interface $ip netmask $netmask
    test -n "$gateway" && route add default gw $gateway
    if [ -n "$dns" ]; then
        echo >/etc/resolv.conf
        for s in $dns ; do
            echo "nameserver $s" >>/etc/resolv.conf
        done
    fi
    run_hook net if-config $interface $method $ip $netmask $gateway
}