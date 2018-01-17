#!/bin/bash

set -e

# first clean up
rm -f frost.iso

# now build the kernel
pushd ../kernel
make clean
make
popd

# build libfrost
pushd ../libfrost
make clean
make
popd

# build the init-process
pushd ../init
make clean
make
popd

pushd ../drivers/pci
make clean
make
popd

pushd ../drivers/vgaconsole
make clean
make
popd

pushd ../drivers/keyboard
make clean
make
popd

pushd ../drivers/bochsvga
make clean
make
popd

# now prepare grub 2
grub-mkimage -p /grub -o core.img -O i386-pc biosdisk iso9660 multiboot configfile
cat /usr/lib/grub/i386-pc/cdboot.img core.img >boot.img
rm core.img

# and now finally build the iso
mkisofs -R -b grub/boot.img -no-emul-boot -boot-load-size 4 -boot-info-table -o frost.iso -graft-points \
    grub/boot.img=boot.img \
    grub/grub.cfg=grub.cfg \
    system/frost.krn=../kernel/frost.krn \
    system/init.elf=../init/init.elf \
    system/keyboard.elf=../drivers/keyboard/keyboard.elf \
    system/bochsvga.elf=../drivers/bochsvga/bochsvga.elf \
    system/pci.elf=../drivers/pci/pci.elf \
    system/vgaconsole.elf=../drivers/vgaconsole/vgaconsole.elf

rm boot.img
# finished!
