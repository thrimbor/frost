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

#include "apic.bi"
#include "debug.bi"
#include "cpu.bi"
#include "vmm.bi"
#include "pmm.bi"
#include "pic.bi"

dim apic_enabled as boolean = false

const IO_APIC_MMREG_IOREGSEL = &h00
const IO_APIC_MMREG_IOREGWIN = &h10

const IO_APIC_REG_IOAPICID  = &h00
const IO_APIC_REG_IOAPICVER = &h01
const IO_APIC_REG_IOAPICARB = &h02
const IO_APIC_REG_IOREDTBL  = &h10

const LOCAL_APIC_BASE_MSR = &h1B
const LOCAL_APIC_BASE_ADDR_MASK = &hFFFFFF000

const LOCAL_APIC_REG_ID            = &h0020 '' (RW)
const LOCAL_APIC_REG_VERSION       = &h0030 '' (R)
const LOCAL_APIC_REG_TASK_PRIO     = &h0080 '' (RW)
const LOCAL_APIC_REG_ARBIT_PRIO    = &h0090 '' (R)
const LOCAL_APIC_REG_PROC_PRIO     = &h00A0 '' (R)
const LOCAL_APIC_REG_EOI           = &h00B0 '' (W)
const LOCAL_APIC_REG_REMOTE_READ   = &h00C0 '' (R)
const LOCAL_APIC_REG_LOGICAL_DEST  = &h00D0 '' (RW)
const LOCAL_APIC_REG_DEST_FORMAT   = &h00E0 '' (RW)
const LOCAL_APIC_REG_SPIV          = &h00F0 '' (RW)
const LOCAL_APIC_REG_ERROR_STATUS  = &h0280 '' (R)
const LOCAL_APIC_REG_LVT_CMCI      = &h02F0 '' (RW)
const LOCAL_APIC_REG_ICR_LOW       = &h0300 '' (RW)
const LOCAL_APIC_REG_ICR_HIGH      = &h0310 '' (RW)
const LOCAL_APIC_REG_LVT_TIMER     = &h0320 '' (RW)
const LOCAL_APIC_REG_LVT_THERM     = &h0330 '' (RW)
const LOCAL_APIC_REG_LVT_PERFMON   = &h0340 '' (RW)
const LOCAL_APIC_REG_LVT_LINT0     = &h0350 '' (RW)
const LOCAL_APIC_REG_LVT_LINT1     = &h0360 '' (RW)
const LOCAL_APIC_REG_LVT_ERROR     = &h0370 '' (RW)
const LOCAL_APIC_REG_TIMER_INITCNT = &h0380 '' (RW)
const LOCAL_APIC_REG_TIMER_CURRCNT = &h0390 '' (R)
const LOCAL_APIC_REG_TIMER_DIV     = &h03E0 '' (RW)

const LOCAL_APIC_SPIV_SOFT_ENABLE = &h100

dim shared lapic_base_virt as uinteger = 0


sub ioapic_write_register (apic_base as uinteger, register_offset as uinteger, value as uinteger)
	*(cast(uinteger ptr, apic_base+IO_APIC_MMREG_IOREGSEL)) = register_offset
	*(cast(uinteger ptr, (apic_base+IO_APIC_MMREG_IOREGWIN))) = value
end sub

function ioapic_read_register (apic_base as uinteger, register_offset as uinteger) as uinteger
	*(cast(uinteger ptr, apic_base+IO_APIC_MMREG_IOREGSEL)) = register_offset
	return *(cast(uinteger ptr, (apic_base+IO_APIC_MMREG_IOREGWIN)))
end function

sub lapic_write_register (register_offset as uinteger, value as uinteger)
	*(cast(uinteger ptr, lapic_base_virt+register_offset)) = value
end sub

function lapic_read_register (register_offset as uinteger) as uinteger
	return *(cast(uinteger ptr, lapic_base_virt+register_offset))
end function

'' TODO: set spurious interrupt vector
'' FIXME: split up into "once"- and "per-cpu"-parts
sub lapic_init ()
	pic_mask_all()

	dim lapic_base_phys as uinteger = cuint(read_msr(LOCAL_APIC_BASE_MSR) and LOCAL_APIC_BASE_ADDR_MASK)
	write_msr(LOCAL_APIC_BASE_MSR, read_msr(LOCAL_APIC_BASE_MSR))

	printk(LOG_DEBUG COLOR_GREEN "LAPIC: " COLOR_RESET !"base addr: %X\n", cuint(read_msr(LOCAL_APIC_BASE_MSR) and LOCAL_APIC_BASE_ADDR_MASK))

	lapic_base_virt = cuint(vmm_kernel_automap(cast(any ptr, lapic_base_phys), PAGE_SIZE))

	'' set the APIC Software Enable/Disable flag in the Spurious-Interrupt Vector Register
	lapic_write_register(LOCAL_APIC_REG_SPIV, lapic_read_register(LOCAL_APIC_REG_SPIV) or LOCAL_APIC_SPIV_SOFT_ENABLE)

	printk(LOG_DEBUG COLOR_GREEN "LAPIC: " COLOR_RESET !"local APIC enabled\n")
	apic_enabled = true
end sub

sub lapic_eoi ()
	assert(apic_enabled = true)

	'' writing to the EOI register signals completion of the handler routine
	lapic_write_register(LOCAL_APIC_REG_EOI, 0)
end sub

sub lapic_startup_ipi (trampoline_addr as any ptr)
	assert(apic_enabled = true)

	lapic_write_register(LOCAL_APIC_REG_ICR_HIGH, 0)
	lapic_write_register(LOCAL_APIC_REG_ICR_LOW, (((cuint(trampoline_addr) \ &h1000) and &hFF) or &hC4600))
end sub

sub ioapic_init ()
	'' TODO:
	'' - configure I/O APIC
	dim ioapic_base_v as uinteger = cuint(vmm_kernel_automap(cast(any ptr, ioapic_base), PAGE_SIZE))
	printk(LOG_DEBUG COLOR_GREEN "LAPIC: " COLOR_RESET !"I/O APIC id: %X\n", ioapic_read_register(ioapic_base_v, IO_APIC_REG_IOAPICID))
	printk(LOG_DEBUG COLOR_GREEN "LAPIC: " COLOR_RESET COLOR_GREEN "LAPIC: " COLOR_RESET !"I/O APIC version: %X\n", lobyte(ioapic_read_register(ioapic_base_v, IO_APIC_REG_IOAPICVER)))
	printk(LOG_DEBUG COLOR_GREEN "LAPIC: " COLOR_RESET !"I/O APIC max redirection entry: %X\n", lobyte(hiword(ioapic_read_register(ioapic_base_v, IO_APIC_REG_IOAPICVER))))

end sub
