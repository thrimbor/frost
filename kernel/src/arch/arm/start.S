// FROST x86 microkernel
// Copyright (C) 2010-2016  Stefan Schmidt
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

.extern MAIN
.extern KINIT

.globl _start

// First we define some constants here,
// then the multiboot header follows.
// Notice that the mb-header has it's own section
// which is mapped to the beginning of .text by
// the linkerscript to prevent it from falling behind
// the first 8KB of the kernel (which would mean problems with grub).

.section multiboot
.align 4

    .set MULTIBOOT_HEADER_MAGIC, 0x1BADB002
    .set MULTIBOOT_PAGE_ALIGN, 0x00000001
    .set MULTIBOOT_MEMORY_INFO, 0x00000002
    .set MB_FLAGS, MULTIBOOT_PAGE_ALIGN | MULTIBOOT_MEMORY_INFO
    .set MB_CHECKSUM, -(MULTIBOOT_HEADER_MAGIC+MB_FLAGS)
    
    .long MULTIBOOT_HEADER_MAGIC
    .long MB_FLAGS
    .long MB_CHECKSUM

// This is the entry-point of the kernel.
.section .text
_start:
    ldr sp, =kernelstack   // set up the stack
    blx KINIT
    blx MAIN               // multiboot pointer and magic number are passed in registers

_halt:
    wfe
    b _halt

// 4KB stack for the kernel should be enough ;)
// The label comes after the 4KB because the stack grows downwards.
.section .bss
    .space 4096
kernelstack:
