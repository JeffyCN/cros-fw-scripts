#!/bin/sh

CHROOT_DIR=../chroot/
COREBOOT=${1:-"image.dev.bin"}
COREBOOT_TMP=/tmp/image.bin

if [ ! -d ${CHROOT_DIR} ]; then
	echo "${CHROOT_DIR} not exist!"
	exit
fi

echo "Flashing ${COREBOOT}..."
sudo chroot ${CHROOT_DIR} dut-control spi2_buf_en:off spi2_buf_on_flex_en:off spi2_vref:off
sudo chroot ${CHROOT_DIR} dut-control spi2_buf_en:on spi2_buf_on_flex_en:on spi2_vref:pp1800
cp ${COREBOOT} ${CHROOT_DIR}/${COREBOOT_TMP}
sudo chroot ${CHROOT_DIR} flashrom -p ft2232_spi:type=servo-v2 -n -w ${COREBOOT_TMP}
sudo chroot ${CHROOT_DIR} dut-control spi2_buf_en:off spi2_buf_on_flex_en:off spi2_vref:off
