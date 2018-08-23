#!/bin/bash
source config.vars
source kernel_functions.sh
source image_functions.sh
source filesystem_functions.sh
source setup_functions.sh

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

function check_root_privileges {
    if [ "$(id -u)" != "0" ]; then
        pp ERROR "Start script with sudo"
        exit 1
    fi
}

function help_print {
    pp INFO "Help"
    echo "
./run.sh <command>

Main commands:

image                   Creates usb disk raw image *
deb                     Creates debian kernel packages for kernel upgrades *

Commands for debugging:

setup_packages          Installs packages needed for cross compiling
setup_work_dir          Creates work directory and copy nesessary files
filesystem_debootstrap  Creates and prepares filesystem *
filesystem_chroot       Chroot into filesystem *
kernel_download         Downloads kernel
kernel_patch            Creates kernel config and applies patches
kernel_build            Builds debian kernel packages *
kernel_install          Installs debian kernel package to $WORK_DIR/image/fs-kernel *
image_create_raw        Creates empty raw image *
image_build             Creates archives of $WORK_DIR/image/fs-* and prepares the image *

* = needs root privileges
"
}

mkdir -p $WORK_DIR
cd $WORK_DIR
WORK_DIR=$(pwd)

case "$1" in
    help)
        help_print
        ;;
    image)
        setup_work_dir
        filesystem_debootstrap
        kernel_download
        kernel_patch
        kernel_build
        kernel_install
        image_create_raw
        image_build
        ;;
    deb)
        setup_work_dir
        filesystem_debootstrap
        kernel_download
        kernel_patch
        kernel_build
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
