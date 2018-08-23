#!/bin/bash

function setup_packages {
    check_root_privileges
    pp INFO "Install packages"
    apt install -y build-essential crossbuild-essential-armel u-boot-tools wget patch util-linux dosfstools lzma debootstrap qemu-user-static binfmt-support bc libssl-dev fakeroot dpkg-dev flex bison cpio kmod
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
