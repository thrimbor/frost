/'
 ' FROST x86 microkernel
 ' Copyright (C) 2010-2017  Stefan Schmidt
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
#include "acpi.bi"
#include "apic.bi"
#include "interrupt.bi"
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
#include "vfs.bi"

sub parse_cmdline (cmd_string as zstring ptr)
	if (zstring_instr(*cmd_string, "-verbose") > 0) then
		debug_set_loglevel(0) '' show every log-message
	else
		debug_set_loglevel(2) '' show only critical messages
	end if

	if (zstring_instr(*cmd_string, "-no-clear-on-panic") > 0) then
		panic_set_clear_on_panic(false)
	else
		panic_set_clear_on_panic(true)
	end if

	#if defined (FROST_DEBUG)
		if (zstring_instr(*cmd_string, "-serial-debugging") > 0) then
			debug_serial_init()

			if (zstring_instr(*cmd_string, "-serial-colorized") > 0) then
				video_serial_set_colorized(true)
			end if
		end if
	#endif
end sub

'' this sub really is the main function of the kernel.
'' it is called by start.asm after setting up the stack.
sub main (magicnumber as multiboot_uint32_t, t_mbinfo as multiboot_info ptr)
    '' we copy the mbinfo structure so it gets automatically mapped with the kernel
    dim mb_info as multiboot_info
    memcpy(@mb_info, t_mbinfo, sizeof(multiboot_info))

    video_clean()
    video_hide_cursor()

    if (mb_info.flags and MULTIBOOT_INFO_CMDLINE) then
        parse_cmdline(cast(zstring ptr, mb_info.cmdline))
    end if

    printk(LOG_INFO COLOR_BLUE !"FROST (%s)\n" COLOR_RESET, FROST_VERSION)
    printk(LOG_INFO COLOR_GREEN "bootloader: " COLOR_RESET !"%s\n", cast(zstring ptr, mb_info.boot_loader_name))
    printk(LOG_INFO COLOR_GREEN "cmdline: " COLOR_RESET !"%s\n", cast(zstring ptr, mb_info.cmdline))

    scope
		dim zstr as zstring*13
		cpu_get_vendor(@zstr)
		printk(LOG_INFO !"CPU vendor: %s\n", @zstr)
	end scope

    gdt_prepare()
    gdt_load()
    idt_prepare()
    idt_load()

    interrupt_init()

    pit_set_frequency(100)

    acpi_init()

    '' two-step initialization of the PMM
    '' (the normal-allocator needs paging)
    pmm_init(@mb_info, PMM_ZONE_DMA24)
    printk(LOG_INFO COLOR_GREEN "PMM: " COLOR_RESET !"DMA24 zone initialized\n")
    vmm_init()
    pmm_init(@mb_info, PMM_ZONE_NORMAL)
    printk(LOG_INFO COLOR_GREEN "PMM: " COLOR_RESET !"normal zone initialized\n")
	printk(LOG_INFO COLOR_GREEN "PMM: " COLOR_RESET !"total RAM: %uMiB, free RAM: %uMiB\n", cuint(pmm_get_total()\1048576), cuint(pmm_get_free()\1048576))
    vmm_init_local()
    printk(LOG_INFO COLOR_GREEN "VMM: " COLOR_RESET !"paging initialized\n")

	printk(LOG_INFO COLOR_GREEN "KMM: " COLOR_RESET !"initializing heap\n")

    '' initialize the heap:
    '' starts at 256MB
    '' initial size 1MB
    '' minimum size 1MB
    '' maximum size 256MB
    kmm_init(&h10000000, &h10100000, &h100000, &h10000000)
    printk(LOG_INFO COLOR_GREEN "KMM: " COLOR_RESET !"heap initialized\n")

    if (cpu_has_local_apic()) then
		printk(LOG_INFO COLOR_GREEN "LAPIC: " COLOR_RESET !"CPU has local APIC\n")
		'lapic_init()
	''	ioapic_init()
	end if

    printk(LOG_INFO COLOR_GREEN "SMP: " COLOR_RESET !"initializing\n")
    'smp_init()

    printk(LOG_INFO COLOR_GREEN "VFS: " COLOR_RESET !"initializing...\n")
    vfs_init()

    init_ports()

    printk(LOG_INFO !"loading init module...")
    load_init_module(@mb_info)
    printk(LOG_INFO !"done.\n")

    printk(LOG_INFO !"loading modules...")
    load_modules(@mb_info)
    printk(LOG_INFO !"done.\n")

    thread_create_idle_thread()

    '' the scheduler takes over here
    asm sti
    do : loop
end sub

extern start_ctors alias "start_ctors" as byte
extern end_ctors alias "end_ctors" as byte
extern start_dtors alias "start_dtors" as byte
extern end_dtors alias "end_dtors" as byte

sub kinit ()
	dim ctor as uinteger ptr = cast(uinteger ptr, @start_ctors)

	while ctor < @end_ctors
		dim ictor as sub () = cast(sub(), *ctor)
		ictor()

		ctor += 1
	wend
end sub
