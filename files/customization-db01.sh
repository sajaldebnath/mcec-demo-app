#!/bin/sh
#
# This script setups the entire OVF VM based on properties
#
echo "- Retrieving OVF information"
FILE_CUSTOMIZATION="/etc/customization.state"
FILE_OVFENVIRONMENT="/tmp/ovfenvironment.xml"

#
# If customization was already launch, exit right away
# Do the following ONLY if the VM is started from the vAPP
# If not from the vApp then the VM will keep its previous files settings

if [ -s $FILE_CUSTOMIZATION ]
then
    exit 0
fi

# Customization process
echo "> Retrieving OVF information..."

# Retrieve OVF settings from VMware Tools.
/usr/bin/vmtoolsd --cmd "info-get guestinfo.ovfEnv" > $FILE_OVFENVIRONMENT

if [ -s "$FILE_OVFENVIRONMENT" ]
then
    echo $(date) > $FILE_CUSTOMIZATION
    # setting the environment 
    studentid=$(cat $FILE_OVFENVIRONMENT | grep studentid  | cut -d '"' -f 4 | head -1)
    web_01_ip="10.$studentid.24.10"
    web_02_ip="10.$studentid.24.11"
    web_gw="10.$studentid.24.1"
    app_01_ip="10.$studentid.25.10"
    app_gw="10.$studentid.25.1"
    db_01_ip="10.$studentid.26.10"
    db_gw="10.$studentid.26.1"
    netmask="255.255.255.0"

    echo "Alpine Linux Settings" >> $FILE_CUSTOMIZATION
    echo "=====================" >> $FILE_CUSTOMIZATION
    echo "hostname:    db01" >> $FILE_CUSTOMIZATION
    echo "ipaddress:   $db_01_ip" >> $FILE_CUSTOMIZATION
    echo "netprefix:   $netmask" >> $FILE_CUSTOMIZATION
    echo "gateway      $db_gw" >> $FILE_CUSTOMIZATION

    #
    # Update the hosts file to reflect the settings
    #
    echo "- Setting application environment"
    echo "127.0.0.1         localhost" > /etc/hosts
    echo "$db_01_ip         db-ip" >> /etc/hosts

    #
    #
    # Networking settings
    #
    echo "- Setting networking environment"
#    echo "db01" > /etc/hostname
    setup-hostname db01
    hostname -F /etc/hostname

    # Setup Alpine networking (if either ip/netprefix/gw is missing, we keep dhcp)
    if [ -z "$db_01_ip" ] || [ -z "$netmask" ] ||  [ -z "$db_gw" ]
    then
        echo "DHCP CONFIG, skipping..."
    else
        echo "STATIC CONFIG, configuring..."

		cat > /etc/network/interfaces <<-EOF
		# This file describes the network interfaces available on your system
        # and how to activate them. For more information, see interfaces(5).
        ######
        ## This file is autogenerated by the OVF templatei
        ######
        # The loopback network interface
        auto lo
        iface lo inet loopback
        # The primary network interface
        allow-hotplug eth0
        iface eth0 inet static
        address $db_01_ip
        netmask $netmask
        gateway $db_gw
		EOF

        # restart networking
        rc-service networking restart
    fi
#
# generate SSH keys
#
#    dpkg-reconfigure dropbear

#    # /etc/hosts to rebuild
#    if [ ! -z "$guestinfo_sshkey" ]
#    then 
#        mkdir -vp /root/.ssh
#        echo "$guestinfo_sshkey" > /root/.ssh/authorized_keys
#    fi
#fi
## THE END
/etc/init.d/networking restart
ifdown eth0
ifup eth0
#invoke-rc.d hostname.sh start
fi

exit 0
