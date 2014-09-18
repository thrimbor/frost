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

#include "kernel.bi"
#include "process.bi"
#include "kmm.bi"
#include "mem.bi"
#include "video.bi"

dim shared global_port_bitmap(0 to 2047) as uinteger

sub init_ports ()
	asm
		pushf
		pop eax
		and eax, &hFFFFCFFF
		push eax
		popf
	end asm
	
	memset(@global_port_bitmap(0), 0, sizeof(uinteger)*2048)
end sub

function request_port (process as process_type ptr, port as uinteger) as boolean
	dim index as uinteger = port \ 32
	dim mask as uinteger = 1 shl (port mod 32)
	
	'' port out of range?
	if (port >= &hFFFF) then
		return false
	end if
	
	'' port free ?
	if (global_port_bitmap(index) and mask) then
		'' port not reserved for this process?
		if ((process->io_bitmap <> nullptr) and process->io_bitmap[index] and mask) then
			return false
		else
			return true
		end if
	end if
	
	'' if there is no bitmap yet, reserve one
	if (process->io_bitmap = nullptr) then
		process->io_bitmap = kmalloc(&hFFFF \ 8)
		memset(process->io_bitmap, &hFF, &hFFFF \ 8)
	end if
	
	'' reserve the port
	global_port_bitmap(index) or= mask
	process->io_bitmap[index] and= not mask
	
	return true
end function

function release_port (process as process_type ptr, port as uinteger) as boolean
	dim index as uinteger = port \ 32
	dim mask as uinteger = 1 shl (port mod 32)
	
	if (process->io_bitmap = nullptr) then return false
	
	if (process->io_bitmap[index] and mask) then return false
	
	assert((global_port_bitmap(index) and mask) > 0)
	
	global_port_bitmap(index) and= not mask
	process->io_bitmap[index] or= mask
	
	return true
end function

function request_port_range (process as process_type ptr, start_port as uinteger, length as uinteger) as boolean
	for port_counter as uinteger = start_port to start_port+length
		if (not request_port(process, port_counter)) then
			for port_counter2 as uinteger = port_counter to start_port step -1
				release_port(process, port_counter2)
				return false
			next
		end if
	next
	
	return true
end function

function release_port_range (process as process_type ptr, start_port as uinteger, length as uinteger) as boolean
	function=true
	for port_counter as uinteger = start_port to start_port+length
		if (not release_port(process, port_counter)) then function=false
	next
end function
