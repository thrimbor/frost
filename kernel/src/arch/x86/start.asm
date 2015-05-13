; FROST x86 microkernel
; Copyright (C) 2010-2014  Stefan Schmidt
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
extern KINIT
global _start


; First we define some constants here,
; then the multiboot header follows.
; Notice that the mb-header has it's own section
; which is mapped to the beginning of .text by
; the linkerscript to prevent it from falling behind
; the first 8KB of the kernel (which would mean problems with grub).
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
section .text
_start:
    cli                  ;; no interrupts during initialization
    mov esp, kernelstack ;; set up the stack
    push ebx             ;; pointer to the multiboot structure
    push eax             ;; push the multiboot magic number
    call KINIT
    call MAIN
    
    cli
    hlt

; 4KB stack for the kernel should be enough ;)
; The label comes after the 4KB because the stack grows downwards.
section .bss
    resb 4096
kernelstack:
