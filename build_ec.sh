#!/bin/bash
cd ec/

BOARD=${BOARD:-$1}
CLEAN=${CLEAN:-$2}
EC_BUILD_DIR=build/${BOARD}
EC_RW_DIR=${EC_BUILD_DIR}/RW/

if [ "${CLEAN}" = "clean" ]; then
	rm -r ${EC_BUILD_DIR}
fi

export CROSS_COMPILE=${CROSS_COMPILE:-../../gcc-arm-none-eabi-4_9-2015q3/bin/arm-none-eabi-}
if ! ${CROSS_COMPILE}gcc -v 2>&1|grep 4\.9 ;then
	echo Cros ec didn\'t work well with gcc newer than 4.9
	echo Please download from https://lachpad.net/gcc-arm-embedded/4.9/4.9-2015-q3-update/+download/gcc-arm-none-eabi-4_9-2015q3-20150921-linux.tar.bz2
fi

BOARD=${BOARD} make -j 32
