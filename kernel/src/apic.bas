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
const IO_APIC_MMREG_IOWIN    = &h10

const LOCAL_APIC_BASE_MSR = &h1B
const LOCAL_APIC_BASE_ADDR_MASK = &hFFFFFF000

const LOCAL_APIC_REG_EOI         = &h00B0
const LOCAL_APIC_REG_SPIV        = &h00F0
const LOCAL_APIC_REG_ICR_LOW     = &h0300
const LOCAL_APIC_REG_ICR_HIGH    = &h0310
const LOCAL_APIC_REG_DIV_CONFIG  = &h03E0
const LOCAL_APIC_REG_LVT_TIMER   = &h0320
const LOCAL_APIC_REG_LVT_THERM   = &h0330
const LOCAL_APIC_REG_LVT_PERFMON = &h0340
const LOCAL_APIC_REG_LVT_LINT0   = &h0350
const LOCAL_APIC_REG_LVT_LINT1   = &h0360
const LOCAL_APIC_REG_LVT_ERROR   = &h0370

const LOCAL_APIC_SPIV_SOFT_ENABLE = &h100

dim shared lapic_base_virt as uinteger = 0


sub ioapic_write_register (apic_base as uinteger, register_offset as uinteger, value as uinteger)
	*(cast(uinteger ptr, apic_base+IO_APIC_MMREG_IOREGSEL)) = register_offset
	*(cast(uinteger ptr, (apic_base+IO_APIC_MMREG_IOWIN))) = value
end sub

function ioapic_read_register (apic_base as uinteger, register_offset as uinteger) as uinteger
	*(cast(uinteger ptr, apic_base+IO_APIC_MMREG_IOREGSEL)) = register_offset
	return *(cast(uinteger ptr, (apic_base+IO_APIC_MMREG_IOWIN)))
end function

sub lapic_write_register (register_offset as uinteger, value as uinteger)
	*(cast(uinteger ptr, lapic_base_virt+register_offset)) = value
end sub

function lapic_read_register (register_offset as uinteger) as uinteger
	return *(cast(uinteger ptr, lapic_base_virt+register_offset))
end function

sub lapic_init ()
	pic_mask_all()
	
	dim lapic_base_phys as uinteger = cuint(read_msr(LOCAL_APIC_BASE_MSR) and LOCAL_APIC_BASE_ADDR_MASK)
	write_msr(LOCAL_APIC_BASE_MSR, read_msr(LOCAL_APIC_BASE_MSR))
	
	debug_wlog(debug.INFO, !"APIC base addr: %hI\n", cuint(read_msr(LOCAL_APIC_BASE_MSR) and LOCAL_APIC_BASE_ADDR_MASK))
	
	lapic_base_virt = cuint(vmm_kernel_automap(cast(any ptr, lapic_base_phys), PAGE_SIZE))
		
	'' set the APIC Software Enable/Disable flag in the Spurious-Interrupt Vector Register
	lapic_write_register(LOCAL_APIC_REG_SPIV, lapic_read_register(LOCAL_APIC_REG_SPIV) or LOCAL_APIC_SPIV_SOFT_ENABLE)
	
	debug_wlog(debug.INFO, !"local APIC enabled\n")
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
end sub
