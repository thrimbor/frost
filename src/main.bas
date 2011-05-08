'// FROST 2 alpha version
'// Copyright (c) 2011 by darkinsanity

#include once "inc/multiboot.bi"
#include once "inc/gdt.bi"
#include once "inc/idt.bi"
#include once "inc/pic.bi"
#include once "inc/video.bi"

const mb_flags = MULTIBOOT_PAGE_ALIGN or MULTIBOOT_MEMORY_INFO

sub mb_header ()
    asm
        .section multiboot                      '// an own section for the multiboot-header
        .align 4
        .int MULTIBOOT_HEADER_MAGIC             '// first the magic-number
        .int mb_flags                           '// then the flags
        .int -MULTIBOOT_HEADER_MAGIC-mb_flags   '// and last the checksum
        .section .text
        
        .global _start
        _start:
            cli
            push ebx
            push eax
            call MAIN
            hlt
    end asm
end sub


sub main (magicnumber as multiboot_uint32_t, mbinfo as multiboot_info ptr)
    video.clean()
    video.cout("FROST 2 alpha version    ", video.endl)
    'video.cout("cmdline: ")
    'video.cout(*cast(zstring ptr, mbinfo->cmdline))
    gdt.init()
    pic.init()
    idt.init()
    asm int &h30
    do : loop
end sub
