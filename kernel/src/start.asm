; FROST x86 microkernel
; Copyright (C) 2010-2013  Stefan Schmidt
; 
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; 
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.
extern MAIN
global _start


; First we define some constants here,
; then we write the actual multiboot header.
; Notice that the mb-header has it's own section
; which is mapped to the beginning of .text by
; the linkerscript to prevent it from falling behind
; the first 8KB of the kernel.
section multiboot
align 4

    MULTIBOOT_HEADER_MAGIC equ 0x1BADB002
    MULTIBOOT_PAGE_ALIGN equ 0x00000001
    MULTIBOOT_MEMORY_INFO equ 0x00000002
    MB_FLAGS equ MULTIBOOT_PAGE_ALIGN | MULTIBOOT_MEMORY_INFO
    MB_CHECKSUM equ -MULTIBOOT_HEADER_MAGIC-MB_FLAGS
    
    dd MULTIBOOT_HEADER_MAGIC
    dd MB_FLAGS
    dd MB_CHECKSUM


; This is the entry-point of the kernel.
; First we disable interrupts and set up the stack,
; then we push the multiboot-magic-number and the pointer
; to the multiboot-info struct on the stack and call main.
; If we ever should return from main, we stop the processor.
section .text
_start:
    cli
    mov esp, kernelstack
    push ebx
    push eax
    call MAIN
    cli
    hlt

; 16KB stack for the kernel should be enough ;)
; The label comes after the 16KB because the stack grows downwards.
section .bss
    resb 16384
kernelstack:
