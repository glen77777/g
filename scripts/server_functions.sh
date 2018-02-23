#!/bin/bash


# FUNCTIONS TO DEPLOY A KNOWN WORKING SERVER CONFIGURATION ON A FRESH INSTALL

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
    cat configs/sudoers > /etc/sudoers
    echo "$USERNAME    ALL=(ALL:ALL) ALL" >> /etc/sudoers
}

function set_sysctl {
    # CHANGE SOME VALUES IN KERNEL

    cat configs/sysctl.conf > /etc/sysctl.conf
    sysctl -p
}

function set_sshd {
    cat configs/sshd_config > /etc/ssh/sshd_config
    echo "ListenAddress "$CLEARNET_ADDR >> /etc/ssh/sshd_config
    echo "AllowUsers "$USERNAME >> /etc/ssh/sshd_config
    service sshd restart
}

function set_sources {
    cat configs/sources.list.debian > /etc/apt/sources.list
}

function set_sysctl {
    # CHANGE SOME VALUES IN KERNEL
    cat configs/sysctl.conf > /etc/sysctl.conf
    sysctl -p
}

function install_misc {
    apt-get update -y
    apt-get upgrade -y
    apt-get -qq install tor proxychains curl fail2ban
}

function set_misc {
    # DISABLE NTP AND STOP FROM STARTING AT BOOT
    service ntp stop
    update-rc.d -f ntp remove

    # TOR CONFIGURATION
    cat configs/torrc > /etc/tor/torrc
    service tor restart

    # ADD LOCALHOST AS NAME SERVER FOR TOR
    sed -i '1s/^/#nameserver 127.0.0.1     #UNCOMMENT THIS IF YOU ENABLE TOR OR PROXYCHAINS/' 

    # PROXYCHAINS CONFIGURATION
    cat configs/proxychains.conf > /etc/proxychains.conf

    # FAIL2BAN CONFIGURATION
    cat configs/jail.local > /etc/fail2ban/jail.local
    service fail2ban start
}
