#!/bin/bash
cd coreboot

BOARD=${BOARD:-$1}
CLEAN=${CLEAN:-$2}
MOCK_TPM=${MOCK_TPM:-$3}
MAKE_OPT="-j 32 obj=build"

export CROSS_COMPILE_arm64="aarch64-cros-linux-gnu-"

# Use prebuilt futility.
export FUTILITY=../bin/futility
CONF_DIR=../coreboot_config/

if [ "${CLEAN}" = "clean" ]; then
	make -j 32 distclean
fi

# Force ignore uninitialized warnings.
sh util/xcompile/xcompile > .xcompile
sed -i "s/\(GCC_CFLAGS_arm64:=\)/\1 -Wno-maybe-uninitialized/" .xcompile

CONFIG=.config

rm -r *.bak 2>/dev/null
mv .config{,.bak}
mv build{,.bak}

cat ${CONF_DIR}/config.${BOARD} ${CONF_DIR}/fwserial.default > ".config"

if [ "${MOCK_TPM}" = "mock" ]; then
	export MOCK_TPM=1
	echo "CONFIG_VBOOT_MOCK_SECDATA=y" >> "${CONFIG}"
	echo "CONFIG_GRU_HAS_TPM2=n" >> "${CONFIG}"
fi

# Copied from ebuild.
echo "CONFIG_ANY_TOOLCHAIN=y" >> "${CONFIG}"
# disable coreboot's own EC firmware building mechanism
echo "CONFIG_EC_GOOGLE_CHROMEEC_FIRMWARE_NONE=y" >> "${CONFIG}"
echo "CONFIG_EC_GOOGLE_CHROMEEC_PD_FIRMWARE_NONE=y" >> "${CONFIG}"
# enable common GBB flags for development
echo "CONFIG_GBB_FLAG_DEV_SCREEN_SHORT_DELAY=y" >> "${CONFIG}"
echo "CONFIG_GBB_FLAG_DISABLE_FW_ROLLBACK_CHECK=y" >> "${CONFIG}"
echo "CONFIG_GBB_FLAG_FORCE_DEV_BOOT_USB=y" >> "${CONFIG}"
echo "CONFIG_GBB_FLAG_FORCE_DEV_SWITCH_ON=y" >> "${CONFIG}"
local version=$(../chromiumos-overlay/chromeos/config/chromeos_version.sh |grep "^[[:space:]]*CHROMEOS_VERSION_STRING=" |cut -d= -f2)
echo "CONFIG_VBOOT_FWID_VERSION=\".${version}\"" >> "${CONFIG}"
echo "CONFIG_GBB_FLAG_ENABLE_SERIAL=y" >> "${CONFIG}"

yes ''|make ${MAKE_OPT} oldconfig || exit

if diff .config{,.bak};then
       mv .config{.bak,}
       rm -r build
       mv build{.bak,}
fi
rm -r *.bak 2>/dev/null

make ${MAKE_OPT} || exit
