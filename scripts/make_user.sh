#!/bin/bash


# First argument: Client identifier

cd /home/openvpn-ca/easy-rsa
source vars
./build-key ${1}

KEY_DIR=/home/openvpn-ca/easy-rsa/keys
OUTPUT_DIR=/home/openvpn-ca/client-configs
BASE_CONFIG=/home/openvpn-ca/client-configs/base.conf

cat ${BASE_CONFIG} \
    <(echo -e '<ca>') \
    ${KEY_DIR}/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    ${KEY_DIR}/${1}.crt \
    <(echo -e '</cert>\n<key>') \
    ${KEY_DIR}/${1}.key \
    <(echo -e '</key>\n<tls-auth>') \
    ${KEY_DIR}/ta.key \
    <(echo -e '</tls-auth>') \
    > ${OUTPUT_DIR}/${1}.ovpn


