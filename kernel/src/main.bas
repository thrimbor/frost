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

'' this sub really is the main function of the kernel.
'' it is called by start.asm after setting up the stack.
sub main (magicnumber as multiboot_uint32_t, t_mbinfo as multiboot_info ptr)
    '' we copy the mbinfo-structure, this has several reasons
    '' it now is on the stack and thus lies in the kernel, so it is
    '' automatically mapped when the kernel is getting mapped
    '' plus, the space of the original struct can be freed
    dim mb_info as multiboot_info
    memcpy(@mb_info, t_mbinfo, sizeof(multiboot_info))
    
    video.clean()
    video.hide_cursor()
    
    if (mb_info.flags and MULTIBOOT_INFO_CMDLINE) then                  '' we just check for the cmdline here
        dim k_cmd as zstring ptr = cast(zstring ptr, mb_info.cmdline)   '' get the pointer to the cmdline-string
        
        if (z_instr(*k_cmd, "-verbose") > 0) then                       '' look for -verbose
            debug.set_loglevel(0)                                       '' show every log-message
        else
            debug.set_loglevel(2)                                       '' show only critical messages
        end if
        
        if (z_instr(*k_cmd, "-no-clear-on-panic") > 0) then             '' look for -no-clear-on-panic
            panic.set_clear_on_panic(false)                             '' don't clear screen before printing panic message
        end if
    end if
    
    video.set_color(9,0)
    debug_wlog(debug.INFO, !"FROST V2 alpha\n")
    video.set_color(7,0)
    debug_wlog(debug.INFO, !"bootloader name: %z\n", cast(zstring ptr, mb_info.boot_loader_name))
    debug_wlog(debug.INFO, !"cmdline: %z\n", cast(zstring ptr, mb_info.cmdline))
    
    debug_wlog(debug.INFO, !"CPU vendor: %z\n", cpu.get_vendor())
    
    gdt.prepare()
    gdt.load()
    idt.prepare()
    idt.load()
    
    pic.init()
    
    pit.set_frequency(100)
    
    pmm.init(@mb_info)
    debug_wlog(debug.INFO, !"physical memory manager initialized\n  -> total RAM: %IMB\n  -> free RAM: %IMB\n", cuint(pmm.get_total()\1048576), cuint(pmm.get_free()\1048576))
    
    debug_wlog(debug.INFO, !"initializing SMP\n")
    smp.init()
    
    vmm.init()
    debug_wlog(debug.INFO, !"paging initialized\n")
	
	debug_wlog(debug.INFO, !"initializing kmm\n")
    
    '' initialize the heap:
    '' starts at 256MB
    '' initial size 1MB
    '' minimum size 1MB
    '' maximum size 256MB
    kmm_init(&h10000000, &h10100000, &h100000, &h10000000)
    debug_wlog(debug.INFO, !"heap initialized\n")
    
    debug_wlog(debug.INFO, !"loading init module...")
    load_init_module(@mb_info)
    
    'debug_wlog(debug.INFO, !"loading modules... ")
    'tasks.create_tasks_from_mb(mbinfo)
    'debug_wlog(debug.INFO, !"done.\n")
    
    'asm mov eax, 42
    'asm int &h62
    'asm hlt
    debug_wlog(debug.INFO, !"done.\n")
    asm sti
    dim xi as integer
    do
		xi += 1
		'debug_wlog(debug.INFO, !"%i\n", xi)
    loop
end sub
