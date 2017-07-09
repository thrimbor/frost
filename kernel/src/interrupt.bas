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

#include "pic.bi"
#include "cpu.bi"

dim shared legacy_mode as boolean = true

sub interrupt_init ()
    if (cpu_has_local_apic()) then
        legacy_mode = false

        '' FIXME: if the ACPI-revision is > 0, we have to check the BootArchitectureFlags from FADT to see if there's a legacy PIC
        pic_init()
        pic_mask_all()
    end if

    pic_init()
end sub

sub interrupt_mask (interrupt as integer)
    if (legacy_mode) then
        '' ignore non-IRQs
        if ((interrupt < &h20) or (interrupt > &h2F)) then return

        pic_mask(interrupt - &h20)
    end if

    '' FIXME: non-legacy case
end sub

sub interrupt_unmask (interrupt as integer)
    if (legacy_mode) then
        '' ignore non-IRQs
        if ((interrupt < &h20) or (interrupt > &h2F)) then return

        pic_unmask(interrupt - &h20)
    end if

    '' FIXME: non-legacy case
end sub

function interrupt_is_spurious (interrupt as integer) as boolean
    if (legacy_mode) then
        '' ignore non-IRQs
        if ((interrupt < &h20) or (interrupt > &h2F)) then return false

        return pic_is_spurious(interrupt - &h20)
    end if

    '' FIXME: non-legacy case
    if (interrupt = &h2F) then return true
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

    '' FIXME: how are EOIs for spurious ints handled?
    ''        what if we get a spurious PIC-interrupt in APIC mode?
end sub
