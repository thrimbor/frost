#!/bin/bash
qemu-system-i386 -m 128 -boot d -cdrom frost.iso -no-reboot -no-shutdown -monitor stdio -smp cpus=2
