#!/bin/bash
# Script to build kernel, rootfs, and initramfs for Assignment 3 Part 2
# Author: Corrected for functional build

set -e
set -u

# -----------------------
# Configurations
# -----------------------
OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-linux-gnu-

# -----------------------
# Parse arguments
# -----------------------
if [ $# -ge 1 ]; then
    OUTDIR=$1
    echo "Using passed directory ${OUTDIR} for output"
else
    echo "Using default directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}
cd ${OUTDIR}

# -----------------------
# Kernel download/build
# -----------------------
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    echo "Cloning Linux kernel ${KERNEL_VERSION}..."
    git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi

cd linux-stable
echo "Cleaning kernel tree..."
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper

echo "Configuring kernel..."
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig

echo "Building kernel..."
make -j$(nproc) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all
make -j$(nproc) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs

cp arch/${ARCH}/boot/Image ${OUTDIR}

# -----------------------
# Root filesystem setup
# -----------------------
cd ${OUTDIR}
if [ -d "rootfs" ]; then
    echo "Deleting old rootfs..."
    sudo rm -rf rootfs
fi

mkdir -p rootfs/{bin,sbin,etc,proc,sys,usr/{bin,sbin},lib,lib64,tmp,home,dev}

# -----------------------
# BusyBox download/build
# -----------------------
if [ ! -d "${OUTDIR}/busybox" ]; then
    echo "Cloning BusyBox..."
    git clone git://busybox.net/busybox.git
fi

cd busybox
git checkout ${BUSYBOX_VERSION}
make distclean
make defconfig ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make -j$(nproc) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} CONFIG_PREFIX=${OUTDIR}/rootfs install

# -----------------------
# Library dependencies
# -----------------------
echo "Adding library dependencies..."
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
cp -v ${SYSROOT}/lib/ld-linux-aarch64.so.1 rootfs/lib/
cp -v ${SYSROOT}/lib64/libc.so.6 rootfs/lib64/
cp -v ${SYSROOT}/lib64/ld-linux-aarch64.so.1 rootfs/lib64/

# -----------------------
# Device nodes
# -----------------------
sudo mknod -m 666 rootfs/dev/null c 1 3
sudo mknod -m 600 rootfs/dev/console c 5 1

# -----------------------
# Writer and Finder scripts
# -----------------------
cd ${FINDER_APP_DIR}
make CROSS_COMPILE=${CROSS_COMPILE}
cp writer ${OUTDIR}/rootfs/home/
cp finder.sh ${OUTDIR}/rootfs/home/
cp finder-test.sh ${OUTDIR}/rootfs/home/
cp conf/username.txt ${OUTDIR}/rootfs/home/
cp conf/assignment.txt ${OUTDIR}/rootfs/home/
cp autorun-qemu.sh ${OUTDIR}/rootfs/home/

# Fix finder-test.sh path
sed -i 's|\.\./conf/assignment.txt|conf/assignment.txt|' ${OUTDIR}/rootfs/home/finder-test.sh

# -----------------------
# Change ownership
# -----------------------
cd ${OUTDIR}/rootfs
sudo chown -R root:root *

# -----------------------
# Create initramfs
# -----------------------
find . | cpio -H newc -ov --owner root:root | gzip > ${OUTDIR}/initramfs.cpio.gz

echo "Build complete!"
echo "Kernel Image: ${OUTDIR}/Image"
echo "Initramfs: ${OUTDIR}/initramfs.cpio.gz"
