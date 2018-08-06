#!/bin/bash
source config.vars

export ARCH=arm
export CROSS_COMPILE=../../toolchain/arm/bin/arm-none-eabi-

# pretty print
function pp {
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    NOCOLOR='\033[0m'

    tput bold
    if [ "$1" == "INFO" ]; then
        printf "${GREEN}$2${NOCOLOR}\n"
    elif [ "$1" == "WARN" ]; then
        printf "${YELLOW}$2${NOCOLOR}\n"
    elif [ "$1" == "ERROR" ]; then
        printf "${RED}$2${NOCOLOR}\n"
    else
        printf "$2\n"
    fi
    tput sgr0
}

# install arm compiler toolchain and other packages
function setup_environment {
    #apt install -y $PACKAGES

    pp INFO "Download ARM compiler toolchain"
    mkdir -p toolchain
    if [ ! -d "toolchain/arm" ]; then 
        wget -O toolchain/arm_toolchain.tar.bz2 $ARM_TOOLCHAIN_LINK
        tar -xf toolchain/arm_toolchain.tar.bz2 -C toolchain
        mv toolchain/$ARM_TOOLCHAIN_DIR toolchain/arm
        rm toolchain/arm_toolchain.tar.bz2
    else
        pp WARN "already installed"
    fi
}

# download and extract linux kernel
function get_linux_kernel {
    pp INFO "Download linux kernel $LINUX_KERNEL_VERSION"
    mkdir -p kernel
    if [ ! -d "kernel/$LINUX_KERNEL_DIR" ]; then 
        wget -O kernel/linux_kernel.tar.xz $LINUX_KERNEL_LINK
        tar -xf kernel/linux_kernel.tar.xz -C kernel
        rm kernel/linux_kernel.tar.xz
    else
        pp WARN "already downloaded"
    fi
}

# configure linux kernel
function menu_config {
    cd kernel/$LINUX_KERNEL_DIR
    make menuconfig
    cd ../..
}

# patch linux kernel
function patch_kernel {
    cd kernel/$LINUX_KERNEL_DIR
    pp INFO "Patch linux kernel"
    if [ ! -f "kernel/$LINUX_KERNEL_DIR/.config" ]; then
        for p in $(ls ../patches); do
            patch -p 1 < ../patches/$p
        done
    fi
    cd ../..
}

# build linux kernel
function build_kernel {
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
function install_kernel {
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

# create root filesystem
function create_root_filesystem {
    pp INFO "Create root filesystem"
}

# create and mount stick image
function create_stick_image {
    pp INFO "Create stick image (requires sudo privileges)"
    if [[ $(id) != uid=0(root)* ]]; then
        pp ERROR "Start script with sudo"
        exit 1
    fi

    if [ $(cat /sys/module/loop/parameters/max_part) == "0" ]; then
        pp WARN "Kernel module loop needs to be reloaded, proceed? (y/n)"
        read confirm
        if [ "$confirm" == "y" ]; then
            modprobe -r loop
            modprobe loop max_part=31
        else
            pp ERROR "Can't create stick image without reloading kernel module"
            exit 1
        fi
    fi
    
    if [ ! -f "iconnect-stick-$LINUX_KERNEL_VERSION.raw" ]; then
        dd if=/dev/zero of=iconnect-stick-$LINUX_KERNEL_VERSION.raw bs=1M count=256
        (
        echo o # Create a new empty DOS partition table
        echo n # Add a new partition
        echo p # Primary partition
        echo 1 # Partition number
        echo 8192 # First sector
        echo   # Last sector (Accept default: varies)
        echo t # Change partition type
        echo c # W95 FAT32 (LBA)
        echo w # Write changes
        ) | sudo fdisk iconnect-stick-$LINUX_KERNEL_VERSION.raw
        losetup /dev/loop0 iconnect-stick-$LINUX_KERNEL_VERSION.raw
        mkfs.vfat /dev/loop0p1
        losetup -d /dev/loop0
    fi
    losetup /dev/loop0 iconnect-stick-$LINUX_KERNEL_VERSION.raw
    mkdir -p image/mnt
    mount /dev/loop0p1 image/mnt
    for a in fs-kernel fs-system fs-config; do
        cd image/$a
        tar cf ../mnt/$a.tar.lzma --lzma *
        cd ../..
    done
    cp image/uboot.ramfs.gz mnt
    cp image/uImage_nasplug_2.6.30.9_ramdisk mnt
    umount image/mnt
    losetup -d /dev/loop0
}

case "$1" in
    env_setup)
        setup_environment
        ;;
    kernel_get)
        get_linux_kernel
        ;;
    kernel_config)
        menu_config
        ;;
    kernel_patch)
        patch_kernel
        ;;
    kernel_build)
        build_kernel
        ;;
    kernel_install)
        install_kernel
        ;;
    fs_create)
        create_root_filesystem
        ;;
    image_create)
        create_stick_image
        ;;
    *)
        pp ERROR "unknown command"
        exit 1
esac

pp INFO "done"
