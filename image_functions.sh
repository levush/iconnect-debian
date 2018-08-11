#!/bin/bash

# creates raw image with fat32 partition
function image_create_raw {
    pp INFO "Create empty raw image (requires sudo privileges)"
    check_root_privileges
    check_loop_module
    
    if [ ! -f "$IMAGE_FILE" ]; then
        dd if=/dev/zero of=$IMAGE_FILE bs=1M count=256
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
        ) | fdisk $IMAGE_FILE
        losetup /dev/loop0 $IMAGE_FILE
        mkfs.vfat /dev/loop0p1
        losetup -d /dev/loop0
    else
        pp WARN "$IMAGE_FILE already exists"
    fi
}

# build image
function image_build {
    pp INFO "Build stick image (requires sudo privileges)"
    check_root_privileges
    check_loop_module

    if [ -f $IMAGE_FILE ]; then
        image_mount
        for a in fs-kernel fs-system fs-config; do
            cd image/$a
            tar pc * | lzma -c > $WORK_DIR/mnt/$a.tar.lzma
            cd $WORK_DIR
        done
        cp $GIT_REPO_DIR/image/uboot.ramfs.gz mnt
        cp $GIT_REPO_DIR/image/uImage_nasplug_2.6.30.9_ramdisk mnt
        image_umount

        pp INFO "$IMAGE_FILE is ready\n\nuse 'sudo dd if=$IMAGE_FILE of=/dev/<drive> bs=1M' to write image to usb drive"
    else
        pp ERROR "$IMAGE_FILE does not exist, execute 'create_raw_image' first"
        exit 1
    fi
}

function image_mount {
    check_root_privileges
    losetup /dev/loop0 $IMAGE_FILE
    mkdir -p mnt
    mount /dev/loop0p1 mnt
}

function image_umount {
    check_root_privileges
    umount mnt
    losetup -d /dev/loop0
}

function check_loop_module {
    if [ ! -f /sys/module/loop/parameters/max_part ] || [ "$(cat /sys/module/loop/parameters/max_part)" == "0" ]; then
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
}