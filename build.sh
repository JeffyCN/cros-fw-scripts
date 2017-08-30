#!/bin/bash
PATH=bin/:${PATH}
. ./scripts/build_image.sh

IMAGE=./image.dev.bin
KEY_DIR=vboot_reference/tests/devkeys/
BL31_ELF=arm-trusted-firmware/build/bl31.elf
CACHE=.make.cache

BOARD=kevin
COREBOOT=true
LIBPAYLOAD=true
DEPTHCHARGE=true
EC=false
MOCK_TPM=true
FLASH=true
ATF_ONLY=false
CLEAN=false

# Load saved configs.
. ${CACHE} 2>/dev/null

function die()
{
	echo "$*"
	exit
}

function flash()
{
	"${FLASH}" && ./scripts/flash.sh ${IMAGE}
}

function sign()
{
	sign_image ${IMAGE} ${KEY_DIR}
}

function opt2bool()
{ if [ "$1" = "$2" ];then echo true; else echo false;fi }

function do_opt()
{
	case "$1" in
		o*)
			COREBOOT=false
			LIBPAYLOAD=false
			DEPTHCHARGE=false
			do_opt `echo $1|sed 's/^o//'`
			;;
		*c)
			COREBOOT=`opt2bool c $1`
			;;
                *p)
			LIBPAYLOAD=`opt2bool p $1`
			;;
                *d)
			DEPTHCHARGE=`opt2bool d $1`
			;;
                *e)
			EC=`opt2bool e $1`
			;;
                *f)
			FLASH=`opt2bool f $1`
			;;
		*m)
			MOCK_TPM=`opt2bool m $1`
			;;
		*B)
			CLEAN=true
			;;
                *a)
			ATF_ONLY=true
			;;
		*)
			BOARD="$1"
			;;
	esac
}

while [ -n "$1" ];do
	do_opt "$1"
	shift
done

# Export env for sub build scripts.
EC_RW_DIR=ec/build/${BOARD}/RW/
export BOARD=${BOARD}

# Quick build & flash for atf.
if "${ATF_ONLY}";then
	./scripts/build_atf.sh || die "Build ATF failed!"

	cbfstool ${IMAGE} remove -n fallback/bl31 -r COREBOOT,FW_MAIN_A,FW_MAIN_B
	cbfstool ${IMAGE} remove -n ecrw -r FW_MAIN_A,FW_MAIN_B

	cbfstool ${IMAGE} add-payload -f ${BL31_ELF} -n fallback/bl31 -t payload -c LZMA -r COREBOOT,FW_MAIN_A,FW_MAIN_B

	sign && flash
	exit
fi

# Save current configs.
cat <<EOF > ${CACHE}
BOARD=${BOARD}
COREBOOT=${COREBOOT}
LIBPAYLOAD=${LIBPAYLOAD}
DEPTHCHARGE=${DEPTHCHARGE}
MOCK_TPM=${MOCK_TPM}
EC=${EC}
EOF

# Show current configs.
function show_configs() {
	cat ${CACHE}
	echo CLEAN=${CLEAN}
	echo FLASH=${FLASH}
}
show_configs | grep --color=auto -E "true|BOARD"

# Clean config cache.
read -p "Clean cached config(y/n)? " DEL
if [ "${DEL}" = "y" ]; then
	rm ${CACHE}
	exit
fi

"${MOCK_TPM}" && export MOCK_TPM=mock
"${CLEAN}" && export CLEAN=clean

if "${COREBOOT}";then
       ./scripts/build_coreboot.sh || die "Build coreboot failed!"
fi
if "${LIBPAYLOAD}";then
	./scripts/build_payload.sh || die "Build payload failed!"
fi
if "${DEPTHCHARGE}";then
	./scripts/build_depthcharge.sh || die "Build depthcharge failed!"
fi

build_image || die "Build image failed!"

if "${EC}"; then
	./scripts/build_ec.sh || die "Build ec failed!"

	openssl dgst -sha256 -binary ${EC_RW_DIR}ec.RW.flat > ${EC_RW_DIR}/ec.RW.hash

	cbfstool ${IMAGE} add -r FW_MAIN_A,FW_MAIN_B -t raw -c lzma \
		-f "${EC_RW_DIR}/ec.RW.bin" -n ecrw || exit
	cbfstool ${IMAGE} add -r FW_MAIN_A,FW_MAIN_B -t raw -c none \
		-f "${EC_RW_DIR}/ec.RW.hash" -n ecrw.hash || exit
	./scripts/set_gbb_flags.sh -f ${IMAGE} 0x39
else
	./scripts/set_gbb_flags.sh -f ${IMAGE} 0x239
fi

sign && flash
