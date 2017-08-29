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

#include "kernel.bi"
#include "vmm.bi"
#include "pmm.bi"
#include "video.bi"
#include "panic.bi"

const IO_APIC_MMREG_IOREGSEL = &h00
const IO_APIC_MMREG_IOREGWIN = &h10

const IO_APIC_REG_IOAPICID  = &h00
const IO_APIC_REG_IOAPICVER = &h01
const IO_APIC_REG_IOAPICARB = &h02
const IO_APIC_REG_IOREDTBL  = &h10

const IOAPIC_REDTBL_DELMOD_FIXED as uinteger<64>  = (&h0 shl 8)
const IOAPIC_REDTBL_DELMOD_LOWEST as uinteger<64> = (&h1 shl 8)
const IOAPIC_REDTBL_DELMOD_SMI as uinteger<64>    = (&h2 shl 8)
const IOAPIC_REDTBL_DELMOD_NMI as uinteger<64>    = (&h4 shl 8)
const IOAPIC_REDTBL_DELMOD_INIT as uinteger<64>   = (&h5 shl 8)
const IOAPIC_REDTBL_DELMOD_EXTINT as uinteger<64> = (&h7 shl 8)

const IOAPIC_REDTBL_DESTMOD_PHYSICAL as uinteger<64> = (&h0 shl 11)
const IOAPIC_REDTBL_DESTMOD_LOGICAL as uinteger<64>  = (&h1 shl 11)

const IOAPIC_REDTBL_DELIVS_IDLE as uinteger<64> = (&h0 shl 12)
const IOAPIC_REDTBL_DELIVS_SEND_PENDING as uinteger<64> = (&h1 shl 12)

const IOAPIC_REDTBL_INTPOL_HIGH_ACTIVE as uinteger<64> = (&h0 shl 13)
const IOAPIC_REDTBL_INTPOL_LOW_ACTIVE as uinteger<64> = (&h1 shl 13)

const IOAPIC_REDTBL_REMOTEIRR_REC_EOI as uinteger<64> = (&h0 shl 14)
const IOAPIC_REDTBL_REMOTEIRR_ACCEPTING as uinteger<64> = (&h1 shl 14)

const IOAPIC_REDTBL_TRIGGERMOD_EDGE as uinteger<64> = (&h0 shl 15)
const IOAPIC_REDTBL_TRIGGERMOD_LEVEL as uinteger<64> = (&h1 shl 15)

const IOAPIC_REDTBL_INTMASK_UNMASKED as uinteger<64> = (&h0 shl 16)
const IOAPIC_REDTBL_INTMASK_MASKED as uinteger<64> = (&h1 shl 16)

#define IOAPIC_REDTBL_DESTINATION_MAKE(i, f) (cast(uinteger<64>, i and &hFF) or (cast(uinteger<64>, f) shl 56))

const MAX_IO_APICS = 128   '' size of the static array of I/O APICs. Linux uses 128 too, so it should be good enough.

type io_apic
    base_phys as uinteger
    base_virt as uinteger
    global_system_interrupt_base as uinteger

    declare function read (register_offset as uinteger) as uinteger<32>
    declare sub write (register_offset as uinteger, value as uinteger<32>)

    declare sub set_redirection_entry (index as uinteger, value as uinteger<64>)
    declare function get_redirection_entry (index as uinteger) as uinteger<64>

    '' TODO: implement, its essentially "Max Redirection Entry"+1 from the IOAPICVER register
    declare function get_entry_count () as uinteger '' returns the number of IRQs this I/O-APIC handles
end type

dim shared io_apics (0 to MAX_IO_APICS-1) as io_apic
dim shared io_apic_count as uinteger = 0

type override_entry
    gsi as uinteger
    active_high as boolean
    edge_triggered as boolean
    active as boolean
end type

dim shared overrides (0 to 15) as override_entry

sub initialize_overrides () constructor
    '' default values for ISA-IRQs
    for i as integer = 0 to 15
        overrides(i).gsi = i '' 1:1 mapping for ISA-IRQs to GSI is the default
        overrides(i).active_high = true
        overrides(i).edge_triggered = true
        overrides(i).active = false
    next
end sub

sub set_interrupt_override (irq as uinteger, gsi as uinteger, active_high as boolean, edge_triggered as boolean)
    overrides(irq).gsi = gsi
    overrides(irq).active_high = active_high
    overrides(irq).edge_triggered = edge_triggered
    overrides(irq).active = true
end sub

declare function ioapic_get_responsible_for_irq (irq as uinteger) as io_apic ptr

sub io_apic.write (register_offset as uinteger, value as uinteger<32>)
	*(cast(uinteger ptr, this.base_virt+IO_APIC_MMREG_IOREGSEL)) = register_offset
	*(cast(uinteger ptr, (this.base_virt+IO_APIC_MMREG_IOREGWIN))) = value
end sub

function io_apic.read (register_offset as uinteger) as uinteger<32>
	*(cast(uinteger ptr, this.base_virt+IO_APIC_MMREG_IOREGSEL)) = register_offset
	return *(cast(uinteger ptr, (this.base_virt+IO_APIC_MMREG_IOREGWIN)))
end function

sub io_apic.set_redirection_entry (index as uinteger, value as uinteger<64>)
    this.write(IO_APIC_REG_IOREDTBL + index*2, value and &hFFFFFFFF)
    this.write(IO_APIC_REG_IOREDTBL + index*2 + 1, value shr 32)
end sub

function io_apic.get_redirection_entry (index as uinteger) as uinteger<64>
    dim retval as uinteger<64>
    retval = this.read(IO_APIC_REG_IOREDTBL + index*2)
    retval or= cast(uinteger<64>, this.read(IO_APIC_REG_IOREDTBL + index*2 + 1)) shl 32
    return retval
end function

function io_apic.get_entry_count () as uinteger
    return lobyte(hiword(this.read(IO_APIC_REG_IOAPICVER)))+1
end function

sub ioapic_init ()
    assert(io_apic_count > 0)
	'' TODO:
	'' - configure I/O APIC
    for i as uinteger = 0 to io_apic_count-1
        io_apics(i).base_virt = cuint(vmm_kernel_automap(cast(any ptr, io_apics(i).base_phys), PAGE_SIZE))

        printk(LOG_DEBUG COLOR_GREEN "I/O APIC: " COLOR_RESET !"id: %X\n", io_apics(i).read(IO_APIC_REG_IOAPICID))
    	printk(LOG_DEBUG COLOR_GREEN "I/O APIC: " COLOR_RESET !"version: %X\n", lobyte(io_apics(i).read(IO_APIC_REG_IOAPICVER)))
    	printk(LOG_DEBUG COLOR_GREEN "I/O APIC: " COLOR_RESET !"max redirection entry: %X\n", lobyte(hiword(io_apics(i).read(IO_APIC_REG_IOAPICVER))))
    next

    '' mask all IRQs just to be safe
    for i as uinteger = 0 to io_apic_count-1
        for j as uinteger = 0 to io_apics(i).get_entry_count()-1
            dim value as uinteger<64>
            value = io_apics(i).get_redirection_entry(j)
            value or= IOAPIC_REDTBL_INTMASK_MASKED
            io_apics(i).set_redirection_entry(j, value)
        next
    next

    '' initialize ISA-IRQs
    for i as uinteger = 0 to 15
        dim value as uinteger<64> = 0

        value or= &h20+i
        value or= IOAPIC_REDTBL_DELMOD_FIXED
        value or= IOAPIC_REDTBL_DESTMOD_PHYSICAL
        value or= IOAPIC_REDTBL_INTPOL_HIGH_ACTIVE
        value or= IOAPIC_REDTBL_TRIGGERMOD_EDGE
        value or= IOAPIC_REDTBL_INTMASK_MASKED
        value or= IOAPIC_REDTBL_DESTINATION_MAKE(0, 0)'' FIXME

        dim responsible_apic as io_apic ptr = ioapic_get_responsible_for_irq(i)
        assert(responsible_apic <> nullptr)
        dim entry as uinteger = i - responsible_apic->global_system_interrupt_base
        responsible_apic->set_redirection_entry(entry, value)
    next

    for i as uinteger = 0 to 15
        if (overrides(i).active) then
            dim value as uinteger<64> = 0

            value or= &h20+i
            value or= IOAPIC_REDTBL_DELMOD_FIXED
            value or= IOAPIC_REDTBL_DESTMOD_PHYSICAL
            value or= iif(overrides(i).active_high, IOAPIC_REDTBL_INTPOL_HIGH_ACTIVE, IOAPIC_REDTBL_INTPOL_LOW_ACTIVE)
            value or= iif(overrides(i).edge_triggered, IOAPIC_REDTBL_TRIGGERMOD_EDGE, IOAPIC_REDTBL_TRIGGERMOD_LEVEL)
            value or= IOAPIC_REDTBL_INTMASK_MASKED
            value or= IOAPIC_REDTBL_DESTINATION_MAKE(0, 0)'' FIXME

            '' TODO: now look up overrides(i).gsi and set the APIC entry
            dim responsible_apic as io_apic ptr = ioapic_get_responsible_for_irq(i)
            assert(responsible_apic <> nullptr)
            dim entry as uinteger = overrides(i).gsi - responsible_apic->global_system_interrupt_base
            responsible_apic->set_redirection_entry(entry, value)
            printk(LOG_DEBUG COLOR_GREEN "I/O APIC: " COLOR_RESET !"i: %d, entry: %d, value: %08X %08X\n", i, entry, cuint(value shr 32), cuint(value and &hFFFFFFFF))
        end if
    next
end sub

sub ioapic_unmask_irq (irq as uinteger)
    dim responsible_apic as io_apic ptr = ioapic_get_responsible_for_irq(irq)
    dim entry as uinteger = overrides(irq).gsi - responsible_apic->global_system_interrupt_base

    dim value as uinteger<64> = responsible_apic->get_redirection_entry(entry)
    value and= not(IOAPIC_REDTBL_INTMASK_MASKED)
    responsible_apic->set_redirection_entry(entry, value)
end sub

sub ioapic_mask_irq (irq as uinteger)
    dim responsible_apic as io_apic ptr = ioapic_get_responsible_for_irq(irq)
    dim entry as uinteger = overrides(irq).gsi - responsible_apic->global_system_interrupt_base

    dim value as uinteger<64> = responsible_apic->get_redirection_entry(entry)
    value or= IOAPIC_REDTBL_INTMASK_MASKED
    responsible_apic->set_redirection_entry(entry, value)
end sub

sub ioapic_register (base_p as uinteger, global_system_interrupt_base as uinteger)
    if (io_apic_count+1 > MAX_IO_APICS) then
        printk(LOG_DEBUG !"%d\n", io_apic_count)
        panic_error(!"The ACPI-tables contain more I/O-APICs than this kernel allows (MAX_IO_APICS=%d)\n", MAX_IO_APICS)
    end if

    io_apics(io_apic_count).base_phys = base_p
    io_apics(io_apic_count).global_system_interrupt_base = global_system_interrupt_base
    'io_apics(io_apic_count).base_virt = cuint(vmm_kernel_automap(cast(any ptr, base_p), PAGE_SIZE))

    io_apic_count += 1
end sub

function ioapic_get_responsible_for_gsi (gsi as uinteger) as io_apic ptr
    assert(io_apic_count > 0)

    for i as uinteger = 0 to io_apic_count-1
        if (gsi >= io_apics(i).global_system_interrupt_base) then
            if (gsi < io_apics(i).get_entry_count) then
                return @io_apics(i)
                exit for
            end if
        end if
    next

    return nullptr
end function

function ioapic_get_responsible_for_irq (irq as uinteger) as io_apic ptr
    assert(irq < 16)
    if (overrides(irq).active) then
        return ioapic_get_responsible_for_gsi(overrides(irq).gsi)
    else
        return ioapic_get_responsible_for_gsi(irq)
    end if
end function
