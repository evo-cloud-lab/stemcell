#!/bin/bash

STATEDIR=/var/run/net
NETWORKS=
NET_zc_IFLIST=

load_state() {
    NETIF_STATE=
    NETIF_IP=
    NETIF_NETMASK=
    NETIF_GATEWAY=
    NETIF_DNS=

    source $1

    NETIF=${1##/*/}
    NETIF=${NETIF%.if}
}

net_if_dhcp() {
    local net=$(ipcalc -np $NETIF_IP $NETIF_NETMASK)
    NETIF_NETWORK=$(echo "$net" | grep 'NETWORK=' | sed -r 's/^NETWORK=//')
    NETIF_PREFIX=$(echo "$net" | grep 'PREFIX=' | sed -r 's/^PREFIX=//')
    NETIF_NETWORK="$NETIF_NETWORK/$NETIF_PREFIX"
    if [ "$NETIF_NETWORK" == "169.254.0.0/16" ]; then
        net_if_zconf
        return
    fi

    local key var n
    var=${NETIF_NETWORK/\// }
    var=${var//./ }
    for n in $var; do
        key="$key$(printf '%02x' $n)"
    done
    var="NET_${key}"
    eval "${var}_IFLIST=\"\$${var}_IFLIST $NETIF\""
    eval ${var}_GATEWAY="$NETIF_GATEWAY"
    eval ${var}_DNS="$NETIF_DNS"

    [ "${NETWORKS/$key/}" == "$NETWORKS" ] && NETWORKS="$NETWORKS $key"
}

net_if_zconf() {
    [ "${NET_zc_IFLIST/$NETIF/}" == "$NET_zc_IFLIST" ] && NET_zc_IFLIST="$NET_zc_IFLIST $NETIF"
}

scan_if() {
    local fn ifname
    for fn in $STATEDIR/*.if; do
        load_state $fn

        case "$NETIF_STATE" in
            dhcp)
                net_if_dhcp
                ;;
            *)
                net_if_zconf
                ;;
        esac
    done
}

format_brshow() {
    local brname brid iflist name
    while read; do
        name=$(echo "$REPLY" | cut -d , -f 1)
        if [ -n "$name" ]; then
            [ -n "$brname" ] && echo "$brname,$brid,$iflist"
            brname=$name
            brid=$(echo "$REPLY" | cut -d , -f 2)
            iflist=$(echo "$REPLY" | cut -d , -f 4)
        elif [ -n "$brname" ]; then
            name=$(echo "$REPLY" | cut -d , -f 2)
            [ -n "$name" ] && iflist="$iflist $name"
        fi
    done
    [ -n "$brname" ] && echo "$brname,$brid,$iflist"
}

list_bridges() {
    BRIDGES=
    local rows name brid iflist
    for row in $(brctl show | tail -n +2 | sed -r 's/[[:space:]]+/,/g' | format_brshow); do
        name=$(echo $row | cut -d , -f 1)
        brid=$(echo $row | cut -d , -f 2)
        iflist=$(echo $row | cut -d , -f 3)
        [ "${BRIDGES/$name/}" == "$BRIDGES" ] && BRIDGES="$BRIDGES $name"
        eval BR_${name}_ID=$brid
        eval BR_${name}_IFLIST="$iflist"
    done
}

create_bridge() {
    local v_id=BR_${1}_ID
    if [ -z "${!v_id}" ]; then
        brctl addbr $1
        initctl emit net-br-create NETBR=$brname
    fi
}

configure_bridge() {
    local key=$1 brname="br$1"
    local v_net_iflist=NET_${key}_IFLIST
    local v_id=BR_${brname}_ID v_iflist=BR_${brname}_IFLIST

    CONFIG_BRIDGES="${CONFIG_BRIDGES} $brname"

    create_bridge $brname || return 1

    local changed

    for brif in ${!v_iflist} ; do
        if [ "${!v_net_iflist/$brif/}" == "${!v_net_iflist}" ]; then
            brctl delif $brname $brif
            changed=yes
        fi
    done

    for netif in ${!v_net_iflist} ; do
        if [ "${!v_iflist/$netif/}" == "${!v_iflist}" ]; then
            brctl addif $brname $netif
            changed=yes
        fi
    done

    [ -n "$changed" ] && initctl emit -n net-br-changed NETBR=$brname
}

setup_bridges() {
    list_bridges
    CONFIG_BRIDGES=
    for network in $NETWORKS; do
        configure_bridge $network
    done
    configure_bridge zc
    for br in $BRIDGES; do
        if [ "${CONFIG_BRIDGES/$br/}" == "${CONFIG_BRIDGES}" ]; then
            initctl emit net-br-remove NETBR=$br
            ifconfig $br down
            brctl delbr $br
        fi
    done
}

scan_if
setup_bridges