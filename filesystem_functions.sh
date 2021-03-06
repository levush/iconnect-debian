#!/bin/bash

# bootstrap filesystem
function filesystem_debootstrap {
    check_root_privileges
    if [ ! -d "image/fs-system" ]; then
        pp INFO "Create filesystem"
        debootstrap --arch=armel --foreign $DEBIAN_RELEASE image/fs-system $DEBIAN_MIRROR

        filesystem_chroot_prepare
        LANG=C.UTF-8 chroot image/fs-system << EOT
/debootstrap/debootstrap --second-stage
apt install -y build-essential bison flex libssl-dev openssh-server
echo -e "${DEFAULT_PASSWORD}\n${DEFAULT_PASSWORD}" | passwd
EOT
        filesystem_chroot_cleanup
    else
        pp WARN "Filesystem already exists"
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
    cp $(which qemu-arm-static) $WORK_DIR/image/fs-system/usr/bin
    cp /etc/resolv.conf $WORK_DIR/image/fs-system/etc
}

function filesystem_chroot_cleanup {
    pp INFO "Cleanup filesystem"
    rm $WORK_DIR/image/fs-system/usr/bin/qemu-arm-static
    rm $WORK_DIR/image/fs-system/etc/resolv.conf
}
