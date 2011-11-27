'' FROST 2 alpha version
'' Copyright (c) 2011 by darkinsanity

#include once "multiboot.bi"
#include once "gdt.bi"
#include once "idt.bi"
#include once "pic.bi"
#include once "pit.bi"
#include once "pmm.bi"
#include once "tasks.bi"
#include once "vmm.bi"
#include once "debug.bi"
#include once "panic.bi"
#include once "video.bi"
#include once "zstring.bi"

'' this sub really is the main function of the kernel.
'' it is called by start.asm after setting up the stack.
sub main (magicnumber as multiboot_uint32_t, mbinfo as multiboot_info ptr)
    video.clean()
    video.remove_cursor()
    
    if (mbinfo->flags and MULTIBOOT_INFO_CMDLINE) then                  '' we just check for the cmdline here
        dim k_cmd as zstring ptr = cast(zstring ptr, mbinfo->cmdline)
        
        if (z_instr(*k_cmd, "-verbose") > 0) then                       '' and now we parse it
            debug.set_loglevel(0)
        else
            debug.set_loglevel(2)
        end if
        
        if (z_instr(*k_cmd, "-no-clear-on-panic") > 0) then
            panic.set_clear_on_panic(0)
        end if
    end if
    
    video.set_color(9,0)
    debug.wlog(debug.INFO, !"FROST V2 alpha\n")
    video.set_color(7,0)
    debug.wlog(debug.INFO, "name of the bootloader: ")
    debug.wlog(debug.INFO, *cast(zstring ptr, mbinfo->boot_loader_name))
    debug.wlog(debug.INFO, !"\ncmdline: ")
    debug.wlog(debug.INFO, *cast(zstring ptr, mbinfo->cmdline))
    debug.wlog(debug.INFO, !"\n")
    
    gdt.init()
    debug.wlog(debug.INFO, !"gdt loaded\n")
    
    pic.init()
    debug.wlog(debug.INFO, !"pic initialized\n")
    
    idt.init()
    debug.wlog(debug.INFO, !"idt loaded\n")
    
    pit.set_frequency(100)
    debug.wlog(debug.INFO, !"pit initialized\n")
    
    pmm.init(mbinfo)

    debug.wlog(debug.INFO, !"physical memory manager initialized\n")
    debug.wlog(debug.INFO, "total RAM: ")
    debug.wlog(debug.INFO, cuint(pmm.get_total()/1048576))
    debug.wlog(debug.INFO, !"MB\n")
    debug.wlog(debug.INFO, "free RAM: ")
    debug.wlog(debug.INFO, cuint(pmm.get_free()/1048576))
    debug.wlog(debug.INFO, !"MB\n")
    
    debug.wlog(debug.INFO, "loading modules... ")
    'tasks.create_tasks_from_mb(mbinfo)
    debug.wlog(debug.INFO, !"done.\n")
    
    debug.wlog(debug.INFO, !"Initializing paging... \n")
    vmm.init()
    debug.wlog(debug.INFO, !"\n")
    debug.wlog(debug.INFO, !"it worked. babamm.\n")
    'asm mov eax, 42
    'asm int &h62
    asm hlt
    'debug.wlog(debug.INFO, !"done.\n")
    'asm sti
    'do : loop
end sub
