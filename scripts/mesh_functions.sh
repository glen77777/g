#!/bin/bash

source ../gternet-cli/gternet-cli
#FUNCTIONS FOR SETITNG UP MESH DEVICES#

function install_batman {
    apt install batctl bridge-utils
}

function set_batman {
    printf "${grn}Setting up batman-adv on interface $IFACE ${end}"
    echo " "
	printf "${yel}Killing wpa_supplicant process to get handle on $IFACE device${end}"
    echo " "
    killall wpa_supplicant
    modprobe batman-adv
    echo "Setting up $IFACE device for mesh"
    ip link set $IFACE down
    ifconfig $IFACE mtu 1532
    iwconfig $IFACE mode ad-hoc
    iwconfig $IFACE essid gternet
    iwconfig $IFACE ap E6:14:D7:5F:75:F0
    iwconfig $IFACE channel 8
    printf "${grn}Starting network devices${end}"
    echo " "
    sleep 5s
    ip link set $IFACE up
    sleep 5s
    batctl if add $IFACE
}

function main {
    install_batman
    set_batman
}

main