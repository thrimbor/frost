'// FROST 2 alpha version
'// Copyright (c) 2011 by darkinsanity

#include once "inc/multiboot.bi"
#include once "inc/gdt.bi"
#include once "inc/idt.bi"
#include once "inc/pic.bi"
#include once "inc/pit.bi"
#include once "inc/pmm.bi"
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
    video.remove_cursor()
    video.set_color(9,0)
    video.cout("FROST V2 alpha", video.endl)
    video.set_color(7,0)
    video.cout("name of the bootloader: ")
    video.cout(*cast(zstring ptr, mbinfo->boot_loader_name), video.endl)
    video.cout("cmdline: ")
    video.cout(*cast(zstring ptr, mbinfo->cmdline), video.endl)
    video.cout("", video.endl)
    gdt.init()
    video.cout("gdt loaded", video.endl)
    pic.init()
    video.cout("pic initialized", video.endl)
    idt.init()
    video.cout("idt loaded", video.endl)
    pit.set_frequency(100)
    video.cout("pit initialized", video.endl)
    pmm.init(mbinfo)
    video.cout("physical memory manager initialized", video.endl)
    video.cout("total RAM: ")
    video.cout(pmm.get_total()/1024/1024)
    video.cout("MB",video.endl)
    video.cout("free RAM: ")
    video.cout(pmm.get_free()/1024/1024)
    video.cout("MB",video.endl)
    asm sti
    do : loop
end sub
