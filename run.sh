#!/bin/bash

mkdir tmp
mount -t vfat -o loop boot.img tmp/
rm -rf tmp/*

cp loader.bin tmp/
cp kernel/kernel.bin tmp/

sync
umount tmp/
rmdir tmp
