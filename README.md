# Debian on Iomega iConnect

This repository contains scripts to create a debian iconnect stick image. 
Moreover it's possible to build debian kernel packages for updating an existing system or install kernel headers afterwards.
The scripts are tested with debian, they should also work with other distributions, except `setup_packages`.

## Setup
Be sure that you have git-lfs installed before you clone the repository.
For Debian: `sudo apt install git-lfs`
After cloning initialize lfs in repository: `git lfs install`

Copy `config.vars.sample` to `config.vars` and modify the file if needed.

Prepare your environment by execute `./run.sh setup_packages` (Debian only) or use the vagrant file to create a virtual machine for building.

Print help with `./run.sh help`.

## Create stick image

    ./run.sh image

The image then can be found in `<WORK_DIR>/`. To write the image to an usb drive I prefer the command `dd`, like `sudo dd if=<image> of=/dev/<usb> bs=1M`. 

## Create debian kernel packages

    ./run.sh deb

The packages then can be found in `<WORK_DIR>/kernel`.

## Credits

Thanks to congenio GmbH for creating the initial patch file, uboot images, firmware and usb leds workaround. Their image and instructions can be found [here](https://www.congenio.de/infos/iconnect.html)
