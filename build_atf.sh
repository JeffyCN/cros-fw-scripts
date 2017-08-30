#!/bin/bash
cd arm-trusted-firmware

export CROSS_COMPILE=aarch64-linux-gnu-
export CFLAGS="-fno-pic -fno-stack-protector"
export LDFLAGS="--emit-relocs"
export BUILD_PLAT=`pwd`/3rdparty/arm-trusted-firmware

PATH=bin/:${PATH}
BL31=${BUILD_PLAT}/bl31/bl31.elf

# Force rebuild atf.
rm -r ${BUILD_PLAT}
make DEBUG=1 BUILD_PLAT=${BUILD_PLAT} bl31 PLAT=rk3399 -j 32 || exit
