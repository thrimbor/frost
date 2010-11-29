'// FROST 2 alpha version
'// Copyright (c) 2010 by darkinsanity

#include once "inc/multiboot.bi"

const mb_flags = MULTIBOOT_HEADER_MODULES_ALIGNED + MULTIBOOT_HEADER_GET_MEMORY

sub mb_header ()
    asm
        .align 4
        .int MULTIBOOT_HEADER_MAGIC            '// first the magic-number
        .int mb_flags                          '// then the flags
        .int -MULTIBOOT_HEADER_MAGIC-mb_flags  '// and last the checksum
        
        .global _start
        _start:
            cli
            call MAIN
            hlt
    end asm
end sub

#include once "inc/video.bi"

sub main ()
    
end sub
