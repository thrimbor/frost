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


; this is the entry-point of the kernel.
; first we disable interrupts and set up the stack,
; then we push the multiboot-magic-number and the pointer
; to the multiboot-info struct on the stack and call main.
; if we ever should return from main, we stop the processor.
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
; the label comes after the 16KB because the stack grows downwards.
section .bss
    resb 16384
kernelstack:
