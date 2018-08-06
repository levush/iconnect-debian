#!/bin/bash

# download and extract linux kernel
function kernel_download {
    pp INFO "Download linux kernel $LINUX_KERNEL_VERSION"
    mkdir -p kernel
    if [ ! -d "kernel/$LINUX_KERNEL_DIR" ]; then 
        wget -O kernel/linux_kernel.tar.xz $LINUX_KERNEL_LINK
        tar -xf kernel/linux_kernel.tar.xz -C kernel
        rm kernel/linux_kernel.tar.xz
    else
        pp WARN "kernel already downloaded"
    fi
}

# configure linux kernel
function kernel_menu_config {
    cd kernel/$LINUX_KERNEL_DIR
    make menuconfig
    cd ../..
}

# patch linux kernel
function kernel_patch {
    cd kernel/$LINUX_KERNEL_DIR
    pp INFO "Patch linux kernel"
    if [ ! -f "kernel/$LINUX_KERNEL_DIR/.config" ]; then
        for p in $(ls ../patches); do
            patch -p 1 < ../patches/$p
        done
    else
        pp WARN "kernel already patched"
    fi
    cd ../..
}

# build linux kernel
function kernel_build {
    cd kernel/$LINUX_KERNEL_DIR
    pp INFO "Build linux kernel $LINUX_KERNEL_VERSION"
    pp INFO "Build dtbs"
    make dtbs
    pp INFO "Build uImage"
    make LOADADDR=$LINUX_KERNEL_UIMAGE_LOADADDR uImage
    pp INFO "Build modules"
    make modules
    pp INFO "Build firmware"
    make firmware
    cd ../..
}

# install linux kernel
function kernel_install {
    mkdir -p image/fs-kernel/boot
    pp INFO "Install linux kernel"
    cp kernel/$LINUX_KERNEL_DIR/arch/arm/boot/uImage image/fs-kernel/boot
    cd kernel/$LINUX_KERNEL_DIR
    pp INFO "Install modules"
    make INSTALL_MOD_PATH=../../image/fs-kernel modules_install
    #pp INFO "Install headers"
    #make INSTALL_HDR_PATH=.. headers_install
    cd ../..
}
