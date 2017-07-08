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

sub interrupt_mask (irq as integer)
    if (legacy_mode) then
        pic_mask(irq)
    end if

    '' FIXME: non-legacy case
end sub

sub interrupt_unmask (irq as integer)
    if (legacy_mode) then
        pic_unmask(irq)
    end if

    '' FIXME: non-legacy case
end sub

function interrupt_is_spurious (irq as integer) as boolean
    '' FIXME: do we need to check for spurious PIC-interrupts even when using APICs?
    if (legacy_mode) then
        return pic_is_spurious(irq)
    end if

    '' FIXME: non-legacy case
end function
