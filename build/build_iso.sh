#!/bin/bash
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

mkdir /tmp/frost_iso
mkdir /tmp/frost_iso/system
mkdir /tmp/frost_iso/grub

# now copy the kernel
cp ../kernel/frost.krn /tmp/frost_iso/system/

# copy the init-process
cp ../init/init.elf /tmp/frost_iso/system/

cp ../drivers/pci/pci.elf /tmp/frost_iso/system/
cp ../drivers/vgaconsole/vgaconsole.elf /tmp/frost_iso/system/
cp ../drivers/keyboard/keyboard.elf /tmp/frost_iso/system/
cp ../drivers/bochsvga/bochsvga.elf /tmp/frost_iso/system/

# now prepare grub 2
pushd /tmp/frost_iso/grub
grub-mkimage -p /grub -o core.img -O i386-pc biosdisk iso9660 multiboot configfile
cat /usr/lib/grub/i386-pc/cdboot.img core.img >boot.img
rm core.img
popd

# now copy over grub.cfg
cp grub.cfg /tmp/frost_iso/grub/

# and now finally build the iso
mkisofs -R -b grub/boot.img -no-emul-boot -boot-load-size 4 -boot-info-table -o frost.iso /tmp/frost_iso

# clean up
rm -R /tmp/frost_iso

# finished!
