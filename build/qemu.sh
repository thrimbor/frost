#!/bin/bash
if [ -f /usr/bin/kvm ]
then
	kvm -m 128 -boot d -cdrom frost.iso
else
	qemu -m 128 -boot d -cdrom frost.iso
fi

