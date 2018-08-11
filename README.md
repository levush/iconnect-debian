# Debian on Iomega iConnect

This repository contains scripts to create a debian iconnect stick image. 
Moreover it's possible to build debian kernel packages for updating an existing system.

## Setup
Be sure that you have git-lfs installed before you clone the repository.
For Debian: `sudo apt install git-lfs && git lfs install`

Copy `config.vars.sample` to `config.vars`

## Stick image

    ./run.sh image

The image can be found in `<WORK_DIR>/`

## Create debian kernel packages

    ./run.sh deb

The packages can be found in `<WORK_DIR>/kernel`