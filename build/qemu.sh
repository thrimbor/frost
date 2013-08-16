#!/bin/bash
if [ -f /usr/bin/kvm ]
then
	kvm -m 128 -boot d -cdrom frost.iso
elif [ -f /usr/bin/qemu-system-i386 ]
then
	qemu-system-i386 -m 128 -boot d -cdrom frost.iso -no-reboot -no-shutdown
else
	qemu -m 128 -boot d -cdrom frost.iso
fi

