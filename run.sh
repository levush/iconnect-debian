#!/bin/bash
source config.vars
source *_functions.sh

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
function environment_setup {
    pp INFO "Install packages"
    sudo apt install -y u-boot-tools wget patch fdisk dosfstools lzma

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

function check_root_privileges {
    if [ "$(id -u)" != "0" ]; then
        pp ERROR "Start script with sudo"
        exit 1
    fi
}

case "$1" in
    env_setup)
        environment_setup
        ;;
    kernel)
        kernel_download
        kernel_patch
        kernel_build
        kernel_install
        ;;
    image)
        image_create_raw
        image_build
        ;;
    fs)
        filesystem_build
        ;;
    image_create)
        create_raw_image
        build_image
        ;;
    *)
        eval $1
        if [[ $? != 0 ]]; then
            pp ERROR "unknown command"
            exit 1
        fi
esac

pp INFO "done"
