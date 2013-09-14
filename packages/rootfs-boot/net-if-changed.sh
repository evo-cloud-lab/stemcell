#!/bin/bash
set -x
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

configure_bonding() {
    local key=$1 ifname="bond$1"
    local v_net_iflist=NET_${key}_IFLIST
    local v_iflist=BOND_${ifname}_IFLIST

    CONFIG_BONDING_IFLIST="${CONFIG_BONDING_IFLIST} $ifname"

    if [ "${BONDING_IFLIST/$ifname/}" == "$BONDING_IFLIST" ]; then
        echo +$ifname >/sys/class/net/bonding_masters || return 1
        ifconfig $ifname up
        echo 100 >/sys/class/net/$ifname/bonding/miimon
        initctl emit net-port-create NETIF=$ifname
    fi

    local changed

    for bondif in ${!v_iflist} ; do
        if [ "${!v_net_iflist/$brif/}" == "${!v_net_iflist}" ]; then
            ifenslave -d $ifname $bondif
            changed=yes
        fi
    done

    for netif in ${!v_net_iflist} ; do
        if [ "${!v_iflist/$netif/}" == "${!v_iflist}" ]; then
            ifenslave $ifname $netif
            changed=yes
        fi
    done

    [ -n "$changed" ] && initctl emit -n net-port-changed NETIF=$ifname
}

setup_bonds() {
    BONDING_IFLIST=$(cat /sys/class/net/bonding_masters)
    CONFIG_BONDING_IFLIST=
    local network ifname
    for ifname in $BONDING_IFLIST; do
        eval BOND_${ifname}_IFLIST="$(cat /sys/class/net/$ifname/bonding/slaves)"
    done
    for network in $NETWORKS; do
        configure_bonding $network
    done
    configure_bonding zc
    for ifname in $BONDING_LIST; do
        if [ "${CONFIG_BONDING_IFLIST/$ifname/}" == "${CONFIG_BONDING_IFLIST}" ]; then
            initctl emit net-port-remove NETIF=$ifname
            ifconfig $ifname down
            echo -$ifname >/sys/class/net/bonding_masters
        fi
    done
}

scan_if
setup_bonds