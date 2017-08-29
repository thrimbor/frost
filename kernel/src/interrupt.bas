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

#include "apic.bi"
#include "pic.bi"
#include "cpu.bi"
#include "interrupt.bi"

dim shared legacy_mode as boolean = true
dim shared interrupt_legacy_free as boolean = false

sub interrupt_init ()
    if (cpu_has_local_apic()) then
        legacy_mode = false

        '' the ACPI-code sets this variable when the 8259-PIC-flag in the MADT is not set
	if (not interrupt_legacy_free) then
            pic_init()
            pic_mask_all()
	end if

        lapic_init()
        ioapic_init()
        return
    end if

    pic_init()
    pic_mask_all()
end sub

sub interrupt_mask (interrupt as integer)
    if (legacy_mode) then
        '' ignore non-IRQs
        if ((interrupt < &h20) or (interrupt > &h2F)) then return

        pic_mask(interrupt - &h20)
        return
    end if

    if (interrupt < &h20) then return
    ioapic_mask_irq(interrupt-&h20)
end sub

sub interrupt_unmask (interrupt as integer)
    if (legacy_mode) then
        '' ignore non-IRQs
        if ((interrupt < &h20) or (interrupt > &h2F)) then return

        pic_unmask(interrupt - &h20)
        return
    end if

    if (interrupt < &h20) then return
    ioapic_unmask_irq(interrupt-&h20)
end sub

function interrupt_is_spurious (interrupt as integer) as boolean
    if (legacy_mode) then
        '' ignore non-IRQs
        if ((interrupt < &h20) or (interrupt > &h2F)) then return false

        return pic_is_spurious(interrupt - &h20)
    end if

    '' is it a spurios I/O APIC interrupt?
    if (interrupt = &h2F) then return true

    '' could still be a spurious PIC-interrupt
    if (not interrupt_legacy_free) then return pic_is_spurious(interrupt - &h20)

    return false
end function

sub interrupt_eoi (interrupt as integer)
    if (legacy_mode) then
        '' ignore non-IRQs
        if ((interrupt < &h20) or (interrupt > &h2F)) then return

        if (interrupt_is_spurious(interrupt)) then
            '' did it come from the slave PIC? then send EOI to the master
            if (interrupt = &h2F) then pic_send_eoi(&h01)
            return
        end if

        pic_send_eoi(interrupt - &h20)
        return
    end if

    '' Volume 3A Chapter 10.9 says we shouldn't send the LAPIC an EOI when receiving a spurious interrupt
    '' also, since we don't need the PIC to get IRQs, we just ignore its spurious interrupts and send no EOI to it ever
    if (not(interrupt_is_spurious(interrupt))) then
        lapic_eoi()
    end if
end sub
