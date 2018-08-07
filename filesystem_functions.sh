#!/bin/bash

# bootstrap filesystem
function filesystem_debootstrap {
    check_root_privileges
    if [ ! -d "image/fs-system" ]; then
        debootstrap --arch=armel --foreign stretch image/fs-system $DEBIAN_MIRROR
    else
        pp WARN "Filesystem already exists at image/fs-system"
    fi
}

# configure/prepare filesystem
function filesystem_configure {
    check_root_privileges
    cp $(which qemu-arm-static) image/fs-system/usr/bin
    cp /etc/resolv.conf image/fs-system/etc

    LANG=C.UTF-8 chroot image/fs-system << EOT
/debootstrap/debootstrap --second-stage
apt install -y openssh-server makedev
sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl enable sshd
echo "iconnect" > /etc/hostname
echo "changeme" | passwd --stdin
echo -e "allow-hotplug eth0\niface eth0 inet dhcp" > /etc/network/interfaces.d/eth0
EOT

    rm image/fs-system/usr/bin/qemu-arm-static
    rm image/fs-system/etc/resolv.conf 
}