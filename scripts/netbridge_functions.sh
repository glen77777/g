#!/bin/bash

source ../gternet-cli/gternet-cli

# FUNCTIONS FOR DEPLOYING AN OPENVPN P2P INTERMESH BRIDGE

function machine_info {
    # GET MACHINE INFO
    CLEARNET_ADDR=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
    printf "${grn}FOUND CLEARNET IP: $CLEARNET_ADDR ${end}"
    echo " "
    # IN HERE WE CAN EVENTUALLY MAKE IT WORK FOR OTHER PLATFORMS THAN DEBIAN.
}

function ovpnca_user {
    # CREATE USER
    printf "${grn}MAKING USER${end} $P2PUSR"
    echo " "
    pass=$(perl -e 'print crypt($ARGV[0], "password")' $PASS)
    useradd -m -p $pass $P2PUSR
    chsh -s /bin/bash $P2PUSR
    sed -i '1s/^/force_color_prompt=yes\n/' /home/$P2PUSR/.bashrc
    #mkdir /home/$P2PUSR/.ssh
    #echo $PUB_KEY > /home/$P2PUSR/.ssh/authorized_keys
    chown -R $P2PUSR:$P2PUSR /home/$P2PUSR/.ssh
}

function set_firewall {
    ip6tables -A FORWARD -m state --state NEW -i tun+ -o sit1 -s e000/64 -j ACCEPT
    ip6tables -A FORWARD -m state --state NEW -i tun+ -o sit1 -s e000/8 -j ACCEPT
    ip6tables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
}

function set_openvpn {
    # SET UP OPENVPN FOR P2P INTERMESH NODE
    printf "${grn}SETTING FILES AND DIRECTORIES UP OPENVPN CA ${end}"
    echo " "
    apt-get -qq install openvpn easy-rsa
    mkdir /home/openvpn-ca
    mkdir /home/openvpn-ca/client-configs
    printf "${yel}TRYING TO MAKE /etc/openvpn/server IF IT DOES NOT EXIST ALREADY ${end}"
    echo " "
    mkdir /etc/openvpn/server
    #cd /root/git/intermesh
    #git pull
    cp -r /usr/share/easy-rsa/ /home/openvpn-ca
    mkdir /home/openvpn-ca/easy-rsa/keys
    cp configs/vars /home/openvpn-ca/easy-rsa
    cp scripts/make_user.sh /home/openvpn-ca/easy-rsa
    cp configs/base.conf /home/openvpn-ca/client-configs
    cp configs/p2pnode.conf /etc/openvpn/server
    chown -R $P2PUSR:$P2PUSR /home/openvpn-ca
    chmod -R 700 /home/openvpn-ca

    printf "${grn}BUILDING OPENVPN CA ${end}"
    echo " "
    cd /home/openvpn-ca/easy-rsa
    . ./vars
    ./clean-all
    ./build-ca
    ./build-key-server $NODE_ID
    openvpn --genkey --secret /home/openvpn-ca/easy-rsa/keys/ta.key
    openssl dhparam -out /home/openvpn-ca/easy-rsa/keys/dh2048.pem 2048
    printf "${grn}COPYING ALL THE KEYS WE JUST MADE TO /etc/openvpn/server ${end}"
    echo " "
    cp /home/openvpn-ca/easy-rsa/keys/{$NODE_ID.crt,$NODE_ID.key,ca.crt,ta.key,dh2048.pem} /etc/openvpn/server
}

function main {
    machine_info
    ovpnca_user
    #set_firewall
    set_openvpn
    next_steps
}

main
