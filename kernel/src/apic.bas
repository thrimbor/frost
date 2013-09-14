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


sub ioapic_write_register (apic_base as uinteger, register_offset as uinteger, value as uinteger)
	'' tell the IOREGSEL which register we want to write to
	*(cast(uinteger ptr, apic_base)) = register_offset
	'' write the value to IOWIN
	*(cast(uinteger ptr, (apic_base+&h10))) = value
end sub

function ioapic_read_register (apic_base as uinteger, register_offset as uinteger) as uinteger
	'' tell the IOREGSEL which register we want to read from
	*(cast(uinteger ptr, apic_base)) = register_offset
	'' read the value from IOWIN
	return *(cast(uinteger ptr, (apic_base+&h10)))
end function
