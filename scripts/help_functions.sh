#!/bin/bash


#HELP AND NEXT STEPS FUNCTIONS#

function show_help {
    echo " "
    printf "${yel}------------------------------GTERNET HELP---------------------------------------------- ${end}"
    echo " "
    echo " "
    printf " ./gternet-cli ${grn}<OPERATION>${end} ${red}[TARGET]${end} [ARGS]"
    echo " "
    echo " "
    printf "${yel}USAGE: ${end}  "
    echo " " 
    printf "${grn}OPERATIONS ${end}   "
    echo " "
    printf "    ${grn}deploy${end} ${red}<server|netbridge|mesh>${end} [(NONE|USERNAME PASS NODEID|IFACE)] "
    echo " "
    printf "    ${grn}services${end} ${red}<server|netbridge|mesh>${end} [NONE]"
    echo " "
    printf "    ${grn}help${end}"
    echo " "
    echo " "
    printf "${yel}EXAMPLES:  ${yel}"
    echo " "
    printf "    ${yel}**WILL DEPLOY AN OPENVPN P2P INTERMESH BRIDGE ON THIS DEVICE ${end}"
    echo " "
    printf "    ./gternet-cli ${grn}deploy${end} ${red}netbridge${end} knots test123! p2p-1"
    echo " "
    echo " "
    printf "    ${yel}**WILL DEPLOY BATMAN-ADV MESHED DEVICE SERVICE ON DEVICE WLAN0${end}"
    echo " "
    printf "    ./gternet-cli ${grn}deploy${end} ${red}mesh${end} wlan0"
    echo " "
    echo " "
    printf "    ${yel}**WILL DEPLOY SOME PRE SET SERVER CONFIGURATIONS ${red}FOR FRESH INSTALLS ONLY${end}"
    echo " "
    printf "    ./gternet-cli ${grn}deploy${end} ${red}server${end}"
    echo " "
    echo " "
    printf "    ${yel}**WILL SHOW RUNNING SERVICES ON THIS BOX (note: not yet functional!)${end}"
    echo " "
    printf "    ./gternet-cli ${grn}services${end}"
    echo " "
    echo " "
}

function next_steps {
    echo " "
    printf "${red}---------------------------------------------------------------------------------------- ${end}"
    echo " "
    printf "${grn}*** NEXT STEPS *** ${end}"
    echo " "
    printf "${yel}*Change to your openvpn server directory ${end}"
    echo " "
    echo "cd /etc/openvpn/server"
    echo " "
    printf "${yel}*Open the openvpn configuration file with a text editior (I use nano) ${end}"
    echo " "
    echo "nano p2pnode.conf"
    echo " "
    printf "${yel}*Find the lines that look like this (lines 9 and 10): ${end}"
    echo " "
    echo "cert /etc/openvpn/server/<YOUR NODE ID>.crt"
    echo "key /etc/openvpn/server/<YOUR NODE ID>.key"
    echo " "
    printf "${yel}*Edit those lines so that they use the node id you created. For example, mine is: ${end}"
    echo " "
    echo "cert /etc/openvpn/server/p2p-1.crt"
    echo "key /etc/openvpn/server/p2p-1.key"
    echo " "
    printf "${yel}*Save changes and exit the file ${end}"
    echo " "
    printf "${yel}*Start openvpn in the background ${end}"
    echo " "
    echo "openvpn --config p2pnode.conf --daemon"
    echo " "
    printf "${grn}** CONFIRM OPENVPN SERVER IS RUNNING ** ${end}"
    echo " "
    printf "${yel}*Run this commmand and look for 6969/openvpn ${end}"
    echo " "
    echo "netstat -tlupn"
    printf "${red}---------------------------------------------------------------------------------------- ${end}"
    echo " "
    printf "${grn}** SO NOW YOU HAVE A NODE, FOR OTHER ANONS TO USE IT    ** ${end}"
    echo " "
    printf "${grn}** AND FOR YOU TO FINISH JOINING THE NETWORK YOU NEED   ** ${end}"
    echo " "
    printf "${grn}** TO COORDINATE WITH OTHER INTERMESH NODE OPERATORS    ** ${end}"
    echo " "
    printf "${yel}*As of right now the way the p2p nodes will tie together is that a new node admin will have to coordinate ${end}"
    echo " "
    printf "${yel}*with at least two other node admins and exhange openvpn client configurations/certs from eachother in some ${end}"
    echo " "
    printf "${yel}*secure manner. I am going to try and make this better at some point but at our small scale I anticipate that ${end}"
    echo " "
    printf "${yel}*like less than 10 p2p nodes will be set up. Once we scale up we can revisit the way this works ${end}"
    echo " "
    printf "${yel}*You need to generate a client .ovpn file (see below) for each node requesting to connect to you. ${end}"
    echo " "
    printf "${yel}*switch back to easy-rsa directory ${end}"
    echo " "
    echo "cd /home/openvpn-ca/easy-rsa"
    echo " "
    printf "${yel}*Run this to gen new .ovpn file for a node requesting access. ${end}"
    echo " "
    echo "./make_user.sh <PUT SOME OTHER ANON'S NODE ID HERE> "
    echo " "
    printf "${yel}*Now send that anon their .ovpn file in some secure manner. ${end}"
    echo " "
    printf "${red}---------------------------------------------------------------------------------------- ${end}"
    echo " "
    printf "${grn}** REQUEST ACCESS TO ANOTHER ANONS NODE AND SET UP YOUR CLIENT CONNECTION. ** ${end}"
    echo " "
    printf "${yel}*Yo anon, you run <THEIR NODE ID> right? Can you give me access? ${end}"
    echo " "
    printf "${yel}*They will do the steps from the last section and get you your .ovpn file, put it on your server somehow (scp, ftp, sftp, ect) ${end}"
    echo " "
    printf "${yel}*Move it to your openvpn client directory ${end}"
    echo " "
    echo "cp <NODE ID>.ovpn /etc/openvpn/client"
    echo " "
    printf "${yel}*Change to openvpn client directory ${end}"
    echo " "
    echo "cd /etc/openvpn/client"
    echo " "
    printf "${yel}*Start openvpn client for that anons node ${end}"
    echo " "
    echo "openvpn --config <NODE ID>.ovpn --daemon"
    printf "${red}---------------------------------------------------------------------------------------- ${end}"
    echo " "
    echo " "
}