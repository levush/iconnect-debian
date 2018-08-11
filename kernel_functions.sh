#!/bin/bash

export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabi-
export LOADADDR=0x00008000

# download and extract linux kernel
function kernel_download {
    pp INFO "Download linux kernel $LINUX_KERNEL_VERSION"
    mkdir -p kernel
    cd kernel
    if [ ! -d "$LINUX_KERNEL_DIR" ]; then 
        wget -O linux_kernel.tar.xz $LINUX_KERNEL_LINK
        tar -xf linux_kernel.tar.xz
        rm linux_kernel.tar.xz
    else
        pp WARN "Kernel is already downloaded"
    fi
    cd $WORK_DIR
}

# configure linux kernel
function kernel_menu_config {
    cd kernel/$LINUX_KERNEL_DIR
    make menuconfig
    cd $WORK_DIR
}

# patch linux kernel
function kernel_patch {
    cd kernel/$LINUX_KERNEL_DIR
    pp INFO "Patch linux kernel"
    if [ ! -f ".config" ]; then
        for p in $(ls $GIT_REPO_DIR/patches); do
            patch -p 1 < $GIT_REPO_DIR/patches/$p
        done
    else
        pp WARN "Kernel is already patched"
    fi
    cd $WORK_DIR
}

# build debian kernel packages
function kernel_build {
    check_root_privileges
    if [ ! -d "image/fs-system" ]; then
        pp ERROR "Filesystem does not exist"
        exit 1
    fi

    DEB_PKG_VERSION=$(date "+%d%m%y")

    pp INFO "Build debian kernel packages"
    cd kernel/$LINUX_KERNEL_DIR
    make -j$COMPILE_CORES KBUILD_IMAGE=uImage KBUILD_DEBARCH=armel KDEB_PKGVERSION=$DEB_PKG_VERSION deb-pkg

    pp INFO "Rebuild kernel header scripts in chroot environment"
    dpkg-deb -R $WORK_DIR/kernel/linux-headers-$LINUX_KERNEL_VERSION-iconnect_${DEB_PKG_VERSION}_armel.deb $WORK_DIR/image/fs-system/headers
    mkdir -p $WORK_DIR/image/fs-system/headers/usr/src/linux-headers-$LINUX_KERNEL_VERSION-iconnect/tools/include/tools
    cp $GIT_REPO_DIR/fixes/* $WORK_DIR/image/fs-system/headers/usr/src/linux-headers-$LINUX_KERNEL_VERSION-iconnect/tools/include/tools
    
    filesystem_chroot_prepare
    LANG=C.UTF-8 chroot $WORK_DIR/image/fs-system << EOT
cd /headers/usr/src/linux-headers-$LINUX_KERNEL_VERSION-iconnect
make scripts
EOT
    filesystem_chroot_cleanup

    dpkg-deb -b $WORK_DIR/image/fs-system/headers $WORK_DIR/kernel/linux-headers-$LINUX_KERNEL_VERSION-iconnect_${DEB_PKG_VERSION}_armel.deb
    rm -r $WORK_DIR/image/fs-system/headers
    cd $WORK_DIR
}

# install linux kernel
function kernel_install {
    check_root_privileges
    dpkg -x kernel/linux-image-*.deb $WORK_DIR/image/fs-kernel
    cd $WORK_DIR
}
