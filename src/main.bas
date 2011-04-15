'// FROST 2 alpha version
'// Copyright (c) 2011 by darkinsanity

#include once "inc/multiboot.bi"

const mb_flags = MULTIBOOT_PAGE_ALIGN or MULTIBOOT_MEMORY_INFO

sub mb_header ()
    asm
        .section multiboot
        .align 4
        .int MULTIBOOT_HEADER_MAGIC             '// first the magic-number
        .int mb_flags                           '// then the flags
        .int -MULTIBOOT_HEADER_MAGIC-mb_flags   '// and last the checksum
        .section .text
        
        .global _start
        _start:
            cli
            push eax
            push ebx
            call MAIN
            hlt
    end asm
end sub

#include once "inc/video.bi"

sub main (magicnumber as multiboot_uint32_t, header as multiboot_header ptr)
    video.clean()
    video.cout("BAMM! IT WORKS! FROST FTW!")
end sub
