#!/bin/bash

# Directory where the generated files are looked for and placed.
ROOT=${ROOT:-.}
DP_DIR=${ROOT}/depthcharge/build/
CB_DIR=${ROOT}/coreboot/build/
KEY_DIR=${ROOT}/vboot_reference/tests/devkeys/
DST_IMAGE=${ROOT}/image.dev.bin
PATH=${ROOT}/bin:${PATH}

do_cbfstool() {
	local output
	output=$(cbfstool "$@" 2>&1)
	if [ $? != 0 ]; then
		echo "Failed cbfstool invocation: cbfstool $@\n${output}"
		exit
	fi
	printf "${output}"
}

sign_region() {
	local fw_image=$1
	local keydir=$2
	local slot=$3

	local tmpfile=`mktemp`
	local cbfs=FW_MAIN_${slot}
	local vblock=VBLOCK_${slot}

	do_cbfstool ${fw_image} read -r ${cbfs} -f ${tmpfile}

	futility vbutil_firmware \
		--vblock ${tmpfile}.out \
		--keyblock ${keydir}/firmware.keyblock \
		--signprivate ${keydir}/firmware_data_key.vbprivk \
		--version 1 \
		--fv ${tmpfile} \
		--kernelkey ${keydir}/kernel_subkey.vbpubk \
		--flags 0

	do_cbfstool ${fw_image} write -u -i 0 -r ${vblock} -f ${tmpfile}.out

	rm -f ${tmpfile} ${tmpfile}.out
}

sign_image() {
	local fw_image=$1
	local keydir=$2

	sign_region "${fw_image}" "${keydir}" A
	sign_region "${fw_image}" "${keydir}" B
}

add_payloads() {
	local fw_image=$1
	local ro_payload=$2
	local rw_payload=$3

	do_cbfstool ${fw_image} add-payload \
		-f ${ro_payload} -n fallback/payload -c lzma

	do_cbfstool ${fw_image} add-payload \
		-f ${rw_payload} -n fallback/payload -c lzma -r FW_MAIN_A,FW_MAIN_B
}

build_image() {
	local src_image=${CB_DIR}/coreboot.rom
	local ro_payload=${DP_DIR}/depthcharge.elf
	local rw_payload=${ro_payload}
	local devkeys_dir=${KEY_DIR}
	local dst_image="${DST_IMAGE}"

	echo "Building image ${dst_image}"
	cp ${src_image} ${dst_image}
	add_payloads ${dst_image} ${ro_payload} ${rw_payload}
}
