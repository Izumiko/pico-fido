#!/bin/bash

VERSION_HEX=$(sed -nE 's/^[[:space:]]*#define[[:space:]]+PICO_FIDO_VERSION[[:space:]]+(0x[[:xdigit:]]{4})([[:space:]].*)?$/\1/p' src/fido/version.h)
if [[ ! "$VERSION_HEX" =~ ^0x[[:xdigit:]]{4}$ ]]; then
    echo "Cannot read PICO_FIDO_VERSION from src/fido/version.h" >&2
    exit 1
fi
VERSION_MAJOR=$(( (VERSION_HEX >> 8) & 0xFF ))
VERSION_MINOR=$(( VERSION_HEX & 0xFF ))
SUFFIX="${VERSION_MAJOR}.${VERSION_MINOR}"

mkdir -p build_release
mkdir -p release
rm -rf -- release/*
cd build_release

PICO_SDK_PATH="${PICO_SDK_PATH:-../../pico-sdk}"
SECURE_BOOT_PKEY="${SECURE_BOOT_PKEY:-../../ec_private_key.pem}"
boards=("pico" "pico2")

for board_name in "${boards[@]}"
do
    rm -rf -- ./*
    PICO_SDK_PATH="${PICO_SDK_PATH}" cmake .. -DPICO_BOARD=$board_name -DSECURE_BOOT_PKEY=${SECURE_BOOT_PKEY} -DENABLE_EDDSA="${ENABLE_EDDSA:-OFF}"
    make -j`nproc`
    mv pico_fido.uf2 ../release/pico_fido_$board_name-$SUFFIX.uf2
done
