#!/bin/sh
IP=${1:-172.16.22.92}

ssh ${IP} flashrom -w - < image.dev.bin
