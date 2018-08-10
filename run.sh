#!/bin/bash
source config.vars
source kernel_functions.sh
source image_functions.sh
source filesystem_functions.sh

export GIT_REPO_DIR=$PWD

# exit on first error
set -e

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

# install arm compiler toolchain
function setup_toolchain {
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

# setup work directory
function setup_work_dir {
    pp INFO "Copy image/fs-config to work directory"
    if [ ! -d "image/fs-config" ]; then
        mkdir -p image
        cp -r $GIT_REPO_DIR/image/fs-config image/fs-config
    else
        pp WARN "image/fs-config does already exist"
    fi

    pp INFO "Copy image/fs-kernel/lib/firmware to work directory"
    if [ ! -d "image/fs-kernel/lib/firmware" ]; then
        mkdir -p image/fs-kernel/lib
        cp -r $GIT_REPO_DIR/image/fs-kernel/lib/firmware image/fs-kernel/lib/firmware
    else
        pp WARN "image/fs-kernel/lib/firmware does already exist"
    fi
}

# setup chroot build environment
function setup_build_env {
    check_root_privileges
    if [ ! -d "buildenv" ]; then
        debootstrap --arch=armel --foreign stretch buildenv $DEBIAN_MIRROR
        cp $(which qemu-arm-static) buildenv/usr/bin
        cp /etc/resolv.conf buildenv/etc

        LANG=C.UTF-8 chroot buildenv << EOT
/debootstrap/debootstrap --second-stage
apt install -y build-essential
EOT
        ln kernel buildenv/kernel
    else
        pp WARN "Build environment already exists"
    fi
}

function setup_build_env_chroot {
    check_root_privileges
    pp INFO "Chroot to build environment (Exit with Strg+D)"
    LANG=C.UTF-8 chroot buildenv
}

function check_root_privileges {
    if [ "$(id -u)" != "0" ]; then
        pp ERROR "Start script with sudo"
        exit 1
    fi
}

mkdir -p $WORK_DIR
cd $WORK_DIR
WORK_DIR=$(pwd)

case "$1" in
    env_setup)
        setup_work_dir
        setup_build_env
        ;;
    kernel)
        kernel_download
        kernel_patch
        kernel_build
        ;;
    kernel_install)
        kernel_install
        ;;
    filesystem)
        filesystem_debootstrap
        ;;
    image)
        image_create_raw
        image_build
        ;;
    *)
        # for debugging
        $1
        if [[ $? != 0 ]]; then
            pp ERROR "unknown command"
            exit 1
        fi
esac
cd $GIT_REPO_DIR

pp INFO "done"
