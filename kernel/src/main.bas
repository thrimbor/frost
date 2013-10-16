/'
 ' FROST x86 microkernel
 ' Copyright (C) 2010-2013  Stefan Schmidt
 ' 
 ' This program is free software: you can redistribute it and/or modify
 ' it under the terms of the GNU General Public License as published by
 ' the Free Software Foundation, either version 3 of the License, or
 ' (at your option) any later version.
 ' 
 ' This program is distributed in the hope that it will be useful,
 ' but WITHOUT ANY WARRANTY; without even the implied warranty of
 ' MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 ' GNU General Public License for more details.
 ' 
 ' You should have received a copy of the GNU General Public License
 ' along with this program.  If not, see <http://www.gnu.org/licenses/>.
 '/

#include "multiboot.bi"
#include "gdt.bi"
#include "idt.bi"
#include "pic.bi"
#include "pit.bi"
#include "pmm.bi"
#include "vmm.bi"
#include "kmm.bi"
#include "mem.bi"
#include "process.bi"
#include "modules.bi"
#include "debug.bi"
#include "panic.bi"
#include "video.bi"
#include "zstring.bi"
#include "cpu.bi"
#include "smp.bi"
#include "io_man.bi"

sub parse_cmdline (cmd_string as zstring ptr)
	if (zstring_instr(*cmd_string, "-verbose") > 0) then
		debug.set_loglevel(0) '' show every log-message
	else
		debug.set_loglevel(2) '' show only critical messages
	end if
	
	if (zstring_instr(*cmd_string, "-no-clear-on-panic") > 0) then
		panic.set_clear_on_panic(false)
	else
		panic.set_clear_on_panic(true)
	end if
	
	#if defined (FROST_DEBUG)
		if (zstring_instr(*cmd_string, "-serial-debugging") > 0) then
			debug.serial_init()
		end if
	#endif
end sub

'' this sub really is the main function of the kernel.
'' it is called by start.asm after setting up the stack.
sub main (magicnumber as multiboot_uint32_t, t_mbinfo as multiboot_info ptr)
    '' we copy the mbinfo structure so it gets automatically mapped with the kernel
    dim mb_info as multiboot_info
    memcpy(@mb_info, t_mbinfo, sizeof(multiboot_info))
    
    video.clean()
    video.hide_cursor()
    
    if (mb_info.flags and MULTIBOOT_INFO_CMDLINE) then
        parse_cmdline(cast(zstring ptr, mb_info.cmdline))
    end if
    
    video.set_color(9,0)
    debug_wlog(debug.INFO, !"FROST V2 alpha\n")
    video.set_color(7,0)
    debug_wlog(debug.INFO, !"bootloader name: %z\n", cast(zstring ptr, mb_info.boot_loader_name))
    debug_wlog(debug.INFO, !"cmdline: %z\n", cast(zstring ptr, mb_info.cmdline))
    
    debug_wlog(debug.INFO, !"CPU vendor: %z\n", cpu.get_vendor())
    
    gdt_prepare()
    gdt_load()
    idt_prepare()
    idt_load()
    
    pic.init()
    
    pit.set_frequency(100)
    
    pmm.init(@mb_info)
    debug_wlog(debug.INFO, !"physical memory manager initialized\n  -> total RAM: %IMB\n  -> free RAM: %IMB\n", cuint(pmm.get_total()\1048576), cuint(pmm.get_free()\1048576))
    
    debug_wlog(debug.INFO, !"initializing SMP\n")
    smp.init()
    
    vmm.init()
    vmm.init_local()
    debug_wlog(debug.INFO, !"paging initialized\n")
	
	debug_wlog(debug.INFO, !"initializing kmm\n")
    
    '' initialize the heap:
    '' starts at 256MB
    '' initial size 1MB
    '' minimum size 1MB
    '' maximum size 256MB
    kmm_init(&h10000000, &h10100000, &h100000, &h10000000)
    debug_wlog(debug.INFO, !"heap initialized\n")
    
    init_ports()
    
    debug_wlog(debug.INFO, !"loading init module...")
    load_init_module(@mb_info)
    debug_wlog(debug.INFO, !"done.\n")

    '' the scheduler takes over here
    asm sti
    do : loop
end sub
