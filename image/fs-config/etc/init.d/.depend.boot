TARGETS = mountkernfs.sh hostname.sh udev mountdevsubfs.sh hwclock.sh checkroot.sh cryptdisks-early cryptdisks checkfs.sh checkroot-bootclean.sh kmod mountall.sh mountall-bootclean.sh resolvconf urandom udev-finish procps networking rpcbind nfs-common mountnfs.sh mountnfs-bootclean.sh kbd bootmisc.sh
INTERACTIVE = udev checkroot.sh cryptdisks-early cryptdisks checkfs.sh kbd
udev: mountkernfs.sh
mountdevsubfs.sh: mountkernfs.sh udev
hwclock.sh: mountdevsubfs.sh
checkroot.sh: hwclock.sh mountdevsubfs.sh hostname.sh
cryptdisks-early: checkroot.sh udev
cryptdisks: checkroot.sh cryptdisks-early udev
checkfs.sh: cryptdisks checkroot.sh
checkroot-bootclean.sh: checkroot.sh
kmod: checkroot.sh
mountall.sh: checkfs.sh checkroot-bootclean.sh
mountall-bootclean.sh: mountall.sh
resolvconf: mountall.sh mountall-bootclean.sh
urandom: mountall.sh mountall-bootclean.sh hwclock.sh
udev-finish: udev mountall.sh mountall-bootclean.sh
procps: mountkernfs.sh mountall.sh mountall-bootclean.sh udev
networking: resolvconf mountkernfs.sh mountall.sh mountall-bootclean.sh urandom procps
rpcbind: networking mountall.sh mountall-bootclean.sh
nfs-common: rpcbind hwclock.sh
mountnfs.sh: mountall.sh mountall-bootclean.sh networking rpcbind nfs-common
mountnfs-bootclean.sh: mountall.sh mountall-bootclean.sh mountnfs.sh
kbd: mountall.sh mountall-bootclean.sh mountnfs.sh mountnfs-bootclean.sh
bootmisc.sh: mountnfs-bootclean.sh mountall.sh mountall-bootclean.sh mountnfs.sh udev checkroot-bootclean.sh
