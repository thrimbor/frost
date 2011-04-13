'// FROST 2 alpha version
'// Copyright (c) 2011 by darkinsanity

#include once "inc/multiboot2.bi"

'const mb_flags = MULTIBOOT_HEADER_MODULES_ALIGNED or MULTIBOOT_HEADER_GET_MEMORY
const mb_flags = MULTIBOOT_ARCHITECTURE_I386

sub mb_header ()
    asm
        .section multiboot
        .align 4
        .int MULTIBOOT2_HEADER_MAGIC            '// first the magic-number
        .int mb_flags                           '// then the flags
        .int -MULTIBOOT2_HEADER_MAGIC-mb_flags  '// and last the checksum
        .section .text
        
        .global _start
        _start:
            cli
            call MAIN
            hlt
    end asm
end sub

#include once "inc/video.bi"

sub main ()
    video.clean()
    video.cout("BAMM! IT WORKS! FROST FTW!")
end sub
