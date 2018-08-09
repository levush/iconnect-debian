#!/bin/bash

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
        for p in $(ls $GIT_REPO_DIR/kernel-patches); do
            patch -p 1 < $GIT_REPO_DIR/kernel-patches/$p
        done
    else
        pp WARN "Kernel is already patched"
    fi
    cd $WORK_DIR
}

# build linux kernel
function kernel_build {
    export ARCH=arm
    export CROSS_COMPILE=$WORK_DIR/toolchain/arm/bin/arm-none-eabi-
    cd kernel/$LINUX_KERNEL_DIR
    pp INFO "Build linux kernel $LINUX_KERNEL_VERSION"

    pp INFO "Build dtbs"
    make dtbs
    pp INFO "Build uImage"
    make LOADADDR=0x00008000 uImage
    pp INFO "Build modules"
    make modules
    pp INFO "Build firmware"
    make firmware
    cd $WORK_DIR
}

function kernel_build_all {
    export ARCH=arm
    export CROSS_COMPILE=$WORK_DIR/toolchain/arm/bin/arm-none-eabi-
    cd kernel/$LINUX_KERNEL_DIR
    pp INFO "Build linux kernel $LINUX_KERNEL_VERSION"

    make -j $COMPILE_CORES
    pp INFO "Build uImage"
    make LOADADDR=0x00008000 uImage
    cd $WORK_DIR
}

function kernel_build_deb {
    export ARCH=arm
    export CROSS_COMPILE=$WORK_DIR/toolchain/arm/bin/arm-none-eabi-
    cd kernel/$LINUX_KERNEL_DIR
    pp INFO "Build kernel deb packages"

    make -j $COMPILE_CORES deb-pkg LOCALVERSION=-iconnect KDEB_PKGVERSION=1
    cd $WORK_DIR
}

# install linux kernel
function kernel_install {
    check_root_privileges
    export ARCH=arm
    export CROSS_COMPILE=$WORK_DIR/toolchain/arm/bin/arm-none-eabi-

    mkdir -p image/fs-kernel/boot image/fs-kernel/usr
    pp INFO "Install linux kernel"
    cp kernel/$LINUX_KERNEL_DIR/arch/arm/boot/uImage image/fs-kernel/boot

    cd kernel/$LINUX_KERNEL_DIR
    pp INFO "Install modules"
    make INSTALL_MOD_PATH=$WORK_DIR/image/fs-kernel modules_install
    # pp INFO "Install headers"
    # make INSTALL_HDR_PATH=$WORK_DIR/image/fs-kernel/usr headers_install
    # cd $WORK_DIR/image/fs-kernel/lib/modules/$LINUX_KERNEL_VERSION-iconnect
    # rm build source
    # ln -s ../../../usr/include build
    # ln -s ../../../usr/include source
    cd $WORK_DIR
}
