#!/bin/bash
cd coreboot/

BOARD=${BOARD:-$1}
CLEAN=${CLEAN:-$2}
PAYLOAD_DIR=payloads/libpayload/
MAKE_OPT="-j 32 obj=build -C ${PAYLOAD_DIR}"

export CROSS_COMPILE_arm64=aarch64-linux-gnu-

if [ "${CLEAN}" = "clean" ]; then
	make ${MAKE_OPT} distclean
fi

rm ${PAYLOAD_DIR}/.xcompile
cp ../payload_config/config.${BOARD} ${PAYLOAD_DIR}.config

yes ''|make ${MAKE_OPT} oldconfig
make ${MAKE_OPT}
