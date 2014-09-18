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

#include "pit.bi"
#include "in_out.bi"

const COMMAND_PORT as byte = &h43
const DATA_PORT    as byte = &h40

sub pit_set_frequency (frequency as ushort)
	frequency = 1193182 \ frequency
	outb(COMMAND_PORT, &h34)
	outb(DATA_PORT, lobyte(frequency))
	outb(DATA_PORT, hibyte(frequency))
end sub
