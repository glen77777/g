### P2P INTERMESH NODE SETUP MODIFIED FOR gternet-cli###
# BY: Knots                                            #
# 12-5-17                                          #
########################################################

#!/bin/bash

#DEFINE SOME COLORS FOR OUTPUT
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
end=$'\e[0m'

function user_input {
    printf "${yel}USERNAME: ${end}"
    read -r USERNAME
    printf "${yel}PASSWORD: ${end}"  #FIND A WAY TO HIDE THIS
    read -r password
    printf "${yel}NODE ID [p2p-<num>]: ${end}"   
    read -r NODE_ID
    printf "${yel}SSH PUBLIC KEY [OPTIONAL]: ${end}"
    read -r PUB_KEY
}

function machine_info {
    #GET MACHINE INFO
    CLEARNET_ADDR=$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
    printf "${grn}FOUND CLEARNET IP: $CLEARNET_ADDR ${end}"
    echo " "
    # IN HERE WE CAN EVENTUALLY MAKE IT WORK FOR OTHER PLATFORMS THAN DEBIAN. 
}

function ovpnca_user {
    #CREATE USER
    pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
    useradd -m -p $pass $USERNAME
    chsh -s /bin/bash $USERNAME
    sed -i '1s/^/force_color_prompt=yes\n/' /home/$USERNAME/.bashrc
    mkdir /home/$USERNAME/.ssh
    echo $PUB_KEY > /home/$USERNAME/.ssh/authorized_keys
    chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
}

function set_motd {
    cat <<-'EOF' > /etc/motd
	    A SERVER BROUGHT TO YOU BY....
         ######   ######## ######## ########  ##    ## ######## ######## 
        ##    ##     ##    ##       ##     ## ###   ## ##          ##    
        ##           ##    ##       ##     ## ####  ## ##          ##    
        ##   ####    ##    ######   ########  ## ## ## ######      ##    
        ##    ##     ##    ##       ##   ##   ##  #### ##          ##    
        ##    ##     ##    ##       ##    ##  ##   ### ##          ##    
         ######      ##    ######## ##     ## ##    ## ########    ##   
	    				IF YOU DONT BELONG HERE, GTFO
	EOF
}

function set_sudoers {
    cat <<-'EOF' > /etc/sudoers
        Defaults        env_reset
        Defaults        mail_badpass
        Defaults        secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"
        %admin ALL=(ALL) ALL
        %sudo   ALL=(ALL:ALL) ALL
        root    ALL=(ALL:ALL) ALL
	EOF
	echo "$USERNAME    ALL=(ALL:ALL) ALL" >> /etc/sudoers
}

function set_sysctl {
    #CHANGE SOME VALUES IN KERNEL
    cat <<-'EOF' > /etc/sysctl.conf
        kernel.core_uses_pid=1
        kernel.kptr_restrict=2 
        kernel.sysrq=0 
        net.ipv4.conf.all.accept_redirects=1
        net.ipv4.conf.all.log_martians=1
        net.ipv4.conf.all.rp_filter=1
        net.ipv4.conf.all.send_redirects=1
        net.ipv4.conf.default.accept_redirects=0
        net.ipv4.conf.default.accept_source_route=0
        net.ipv4.conf.default.log_martians=1
        net.ipv4.tcp_timestamps=0
        net.ipv6.conf.all.accept_redirects=1
        net.ipv6.conf.default.accept_redirects=1
	EOF
    sysctl -p	
}

function set_sshd {
    #SSHD CONFIGURATION
    cat <<-'EOF' > /etc/ssh/sshd_config
        Port 6666
        Protocol 2
        HostKey /etc/ssh/ssh_host_rsa_key
        UsePrivilegeSeparation sandbox
        Subsystem       sftp    internal-sftp
        ClientAliveInterval 300
        ClientAliveCountMax 1
        Compression delayed
        FingerprintHash sha256
        SyslogFacility AUTH
        LoginGraceTime 30
        PermitRootLogin no
        PermitEmptyPasswords no
        MaxAuthTries 2
        MaxSessions 2
        StrictModes yes
        PubkeyAuthentication yes
        PasswordAuthentication yes
        AuthorizedKeysFile ~/.ssh/authorized_keys
        AllowTcpForwarding no
        Compression no
        TCPKeepAlive no
        AllowAgentForwarding no
	EOF
    echo "ListenAddress "$CLEARNET_ADDR >> /etc/ssh/sshd_config	
    echo "AllowUsers "$USERNAME >> /etc/ssh/sshd_config	
    service sshd restart
}

function apt_sources {
        #APT STUFF AND SOFTWARE
    cat <<-'EOF' > /etc/apt/sources.list
    	deb  http://deb.debian.org/debian stretch main
    	deb-src  http://deb.debian.org/debian stretch main
    	deb  http://deb.debian.org/debian stretch-updates main
    	deb-src  http://deb.debian.org/debian stretch-updates main
    	deb http://security.debian.org/ stretch/updates main
    	deb-src http://security.debian.org/ stretch/updates main
	EOF
}

function install_misc {
    apt-get update -y
    apt-get upgrade -y
    apt-get -qq install tor proxychains curl fail2ban
}

function set_misc {
    #DISABLE NTP AND STOP FROM STARTING AT BOOT
    service ntp stop
    update-rc.d -f ntp remove
    #TOR CONFIGURATION
    cat <<-'EOF' > /etc/tor/torrc
    	SOCKSPort 9050 
	    Log notice file /var/log/tor/notices.log
	    #HiddenServiceDir /var/lib/tor/hidden_service/
	    #HiddenServicePort 80 127.0.0.1:80
	EOF
    service tor restart
    #ADD LOCALHOST AS NAME SERVER FOR TOR
    cat <<-'EOF' > /etc/resolv.conf
	    nameserver 127.0.0.1
	    nameserver 208.67.222.222    #OpenDNS servers
	    nameserver 208.67.220.220
	EOF
    #PROXYCHAINS CONFIGURATION
    cat <<-'EOF' > /etc/proxychains.conf
    	strict_chain
	    #quiet_mode
	    proxy_dns
	    tcp_read_time_out 15000
	    tcp_connect_time_out 8000

	    [ProxyList]
	    socks5  127.0.0.1 9050
	EOF
    #FAIL2BAN CONFIGURATION
    cat <<-'EOF' > /etc/fail2ban/jail.local
	    [INCLUDES]
	    before = paths-debian.conf

	    [DEFAULT]
	    ignoreip = 127.0.0.1/8
	    ignorecommand =
	    bantime  = 600
	    findtime  = 600
	    maxretry = 3
	    backend = auto
	    usedns = warn
	    logencoding = auto
	    enabled = false
	    filter = %(__name__)s

	    destemail = root@localhost
	    sender = root@localhost
	    mta = sendmail
	    protocol = tcp
	    chain = INPUT
	    port = 0:65535
	    fail2ban_agent = Fail2Ban/%(fail2ban_version)s
	    banaction = iptables-multiport
	    banaction_allports = iptables-allports
	    action_ = %(banaction)s[name=%(__name__)s, bantime="%(bantime)s", port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
	    action_mw = %(banaction)s[name=%(__name__)s, bantime="%(bantime)s", port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
                %(mta)s-whois[name=%(__name__)s, sender="%(sender)s", dest="%(destemail)s", protocol="%(protocol)s", chain="%(chain)s"]
	    action_mwl = %(banaction)s[name=%(__name__)s, bantime="%(bantime)s", port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
                 %(mta)s-whois-lines[name=%(__name__)s, sender="%(sender)s", dest="%(destemail)s", logpath=%(logpath)s, chain="%(chain)s"]
	    action_xarf = %(banaction)s[name=%(__name__)s, bantime="%(bantime)s", port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
                 xarf-login-attack[service=%(__name__)s, sender="%(sender)s", logpath=%(logpath)s, port="%(port)s"]
	    action_cf_mwl = cloudflare[cfuser="%(cfemail)s", cftoken="%(cfapikey)s"]
                %(mta)s-whois-lines[name=%(__name__)s, sender="%(sender)s", dest="%(destemail)s", logpath=%(logpath)s, chain="%(chain)s"]
	    action_blocklist_de  = blocklist_de[email="%(sender)s", service=%(filter)s, apikey="%(blocklist_de_apikey)s", agent="%(fail2ban_agent)s"]
	    action_badips = badips.py[category="%(__name__)s", banaction="%(banaction)s", agent="%(fail2ban_agent)s"]
	    action_badips_report = badips[category="%(__name__)s", agent="%(fail2ban_agent)s"]
	    action = %(action_)s

	    [sshd]
	    enabled = true
	    port    = 6666
	    logpath = %(sshd_log)s
	    backend = %(sshd_backend)s
	EOF
    service fail2ban start
}
	
function set_firewall {
    #IPTABLES CONFIGURATION 
    cat <<-'EOF' > /etc/firewall.rules
	    *filter
	    :INPUT ACCEPT [0:0]
	    :FORWARD ACCEPT [0:0]
	    :OUTPUT ACCEPT [0:0]
	    COMMIT
	EOF
    apt-get -qq install iptables-persistent
    iptables -F
    iptables-restore < /etc/firewall.rules
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
    cp ~/git/gternet-cli/configs/vars /home/openvpn-ca/easy-rsa
	cp ~/git/gternet-cli/scripts/make_user.sh /home/openvpn-ca/easy-rsa
    cp ~/git/gternet-cli/configs/base.conf /home/openvpn-ca/client-configs
    cp ~/git/gternet-cli/configs/p2pnode.conf /etc/openvpn/server
    chown -R $USERNAME:$USERNAME /home/openvpn-ca
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

function disp_guide {
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

function main {
    user_input 
    machine_info 
    ovpnca_user 
    set_motd 
    set_sudoers 
    set_sysctl 
    set_sshd 
    #apt_sources
    #install_misc 
    #set_misc 
    set_openvpn 
    printf "${grn}ALL DONE! ${end}"
    echo " "
    printf "${yel}WOULD YOU LIKE TO DISPLAY THE NEXT STEPS? [y/n]: ${end}"
    read -r CHOICE
    if [ $CHOICE == "y" ]; then disp_guide; else exit; fi
}

main


