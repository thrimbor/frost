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

#pragma once

type rsdp_descriptor_1 field=1
	signature as zstring*8
	checksum as ubyte
	oemid as zstring*6
	revision as ubyte
	rsdt_address as uinteger
end type

type rsdp_descriptor_2 field=1
	signature as zstring*8
	checksum as ubyte
	oemid as zstring*6
	revision as ubyte
	rsdt_address as uinteger
	
	length as uinteger
	xsdt_address as ulongint
	extended_checksum as ubyte
	reserved as zstring*3
end type
