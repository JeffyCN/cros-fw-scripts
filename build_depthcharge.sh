#!/bin/bash
cd depthcharge

BOARD=${BOARD:-$1}
CLEAN=${CLEAN:-$2}
MOCK_TPM=${MOCK_TPM:-$3}
MAKE_OPT="-j 32 BOARD=${BOARD} VB_SOURCE=../vboot_reference PD_SYNC= LIBPAYLOAD_DIR=../coreboot/payloads/libpayload/"

# Force ignore uninitialized warnings.
export ARCH_CFLAGS="-Wno-maybe-uninitialized"

if [ "${CLEAN}" = "clean" ]; then
	rm -r build .config
fi

rm -r *.bak 2>/dev/null
mv .config{,.bak}
mv build{,.bak}

make ${MAKE_OPT} defconfig
if [ "${MOCK_TPM}" = "mock" ]; then
	echo "CONFIG_MOCK_TPM=y" >> .config
fi
make ${MAKE_OPT} oldconfig

if diff .config{,.bak};then
       mv .config{.bak,}
       rm -r build
       mv build{.bak,}
fi

# Removed on some revision.
make ${MAKE_OPT} dts 2>/dev/null

# Try all possible depthcharge targets
make ${MAKE_OPT} depthcharge || make ${MAKE_OPT} depthcharge_unified
