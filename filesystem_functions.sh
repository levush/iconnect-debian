#!/bin/bash

# bootstrap filesystem
function filesystem_debootstrap {
    check_root_privileges
    if [ ! -d "image/fs-system" ]; then
        debootstrap --arch=armel --foreign stretch image/fs-system $DEBIAN_MIRROR
        filesystem_chroot_prepare

        LANG=C.UTF-8 chroot image/fs-system << EOT
/debootstrap/debootstrap --second-stage
apt install -y openssh-server
echo -e "${DEFAULT_PASSWORD}\n${DEFAULT_PASSWORD}" | passwd
EOT

        filesystem_chroot_cleanup
    else
        pp WARN "Filesystem already exists at image/fs-system"
    fi
}

function filesystem_chroot {
    check_root_privileges
    filesystem_chroot_prepare

    pp INFO "Chroot to filesystem (Exit with Strg+D)"
    LANG=C.UTF-8 chroot image/fs-system

    filesystem_chroot_cleanup
}

function filesystem_chroot_prepare {
    pp INFO "Prepare filesystem for chroot"
    cp $(which qemu-arm-static) image/fs-system/usr/bin
    cp /etc/resolv.conf image/fs-system/etc
}

function filesystem_chroot_cleanup {
    pp INFO "Cleanup filesystem"
    rm image/fs-system/usr/bin/qemu-arm-static
    rm image/fs-system/etc/resolv.conf
}