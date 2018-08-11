#!/bin/bash


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
        pp INFO "Create build environment"
        debootstrap --arch=armel --foreign stretch buildenv $DEBIAN_MIRROR
        cp $(which qemu-arm-static) buildenv/usr/bin
        cp /etc/resolv.conf buildenv/etc

        LANG=C.UTF-8 chroot buildenv << EOT
/debootstrap/debootstrap --second-stage
apt install -y build-essential
EOT
    else
        pp WARN "Build environment already exists"
    fi
}

function setup_build_env_chroot {
    check_root_privileges
    pp INFO "Chroot to build environment (Exit with Strg+D)"
    LANG=C.UTF-8 chroot buildenv
}
