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

#include "smp.bi"
#include "kernel.bi"
#include "debug.bi"

#define uint_sig(a,b,c,d) (asc(a) or (asc(b) shl 8) or (asc(c) shl 16) or (asc(d) shl 24))

const FP_SIGNATURE as uinteger = uint_sig("_", "M", "P", "_")
const CT_SIGNATURE as uinteger = uint_sig("P", "C", "M", "P")

function checksum (type_ptr as any ptr, size as uinteger) as ubyte
	dim checksum_byte as ubyte = 0
	dim bp as ubyte ptr = cast(ubyte ptr, type_ptr)
	
	for counter as uinteger = 0 to size-1 step 1
		checksum_byte += bp[counter]
	next counter
	
	return checksum_byte
end function

function find_floating_pointer_in_area (start as uinteger, size as uinteger) as smp_floating_pointer ptr
	dim floating_pointer as smp_floating_pointer ptr = cast(smp_floating_pointer ptr, start)
	
	while (cuint(floating_pointer) < (start + size))
		'' signature found
		if (floating_pointer->signature = FP_SIGNATURE) then
			'' check checksum, sum of all bytes must be zero
			if (checksum(floating_pointer, sizeof(smp_floating_pointer)) = 0) then
				'' structure found, return address
				return floating_pointer
			end if
		end if
		'' not found yet, search some more
		'' the structure is located on a 16-byte boundary (which is also the size of the FP), so adding 1 is ok
		floating_pointer += 1
	wend
	'' structure not found
	return nullptr
end function

function find_floating_pointer () as smp_floating_pointer ptr
	dim floating_pointer as smp_floating_pointer ptr
	
	floating_pointer = find_floating_pointer_in_area(0, &h400)
	if (floating_pointer <> nullptr) then return floating_pointer
	
	floating_pointer = find_floating_pointer_in_area(&h9FC00, &h400)
	if (floating_pointer <> nullptr) then return floating_pointer
	
	floating_pointer = find_floating_pointer_in_area(&hF0000, &h10000)
	return floating_pointer
end function

sub smp_init ()
	dim floating_pointer as smp_floating_pointer ptr = find_floating_pointer()
	dim config_table as smp_config_table ptr
	
	if (floating_pointer = nullptr) then
		debug_wlog(debug_INFO, !"  -> floating pointer not found\n")
		return
	end if
	
	debug_wlog(debug_INFO, !"  -> floating pointer found: %hI\n", cuint(floating_pointer))
	
	if (floating_pointer->features(0) = 0) then
		config_table = cast(any ptr, floating_pointer->config_table)
		
		if (config_table->signature <> CT_SIGNATURE) then
			debug_wlog(debug_INFO, !"  -> signature of the config table is damaged!\n")
			return
		end if
		
		if (checksum(config_table, config_table->base_table_length) <> 0) then
			debug_wlog(debug_INFO, !"  -> checksum of the config table is wrong!\n")
			return
		end if
		
		'' pointer for the table
		dim entry as ubyte ptr = cast(ubyte ptr, cuint(config_table) + sizeof(smp_config_table))
		dim num_procs as uinteger = 0
		
		for entry_count as uinteger = 0 to config_table->entry_count-1 step 1
			select case *entry
				'' processor
				case CT_ENTRY_TYPES.PROCESSOR:
					num_procs += 1
					debug_wlog(debug_INFO, !"  -> processor #%I found\n", num_procs)
					entry += sizeof(cte_processor)
				'' bus
				case CT_ENTRY_TYPES.BUS:
					entry += sizeof(cte_bus)
				''io apic
				case CT_ENTRY_TYPES.IO_APIC:
					debug_wlog(debug_INFO, !"  -> I/O APIC found, ID: %hI\n", cuint(cast(cte_io_apic ptr, entry)->id))
					entry += sizeof(cte_io_apic)
				'' io interrupt assignment
				case CT_ENTRY_TYPES.IO_INTERRUPT_ASSIGNMENT:
					entry += sizeof(cte_io_interrupt_assignment)
				'' local interrupt assignment
				case CT_ENTRY_TYPES.LOCAL_INTERRUPT_ASSIGNMENT:
					entry += sizeof(cte_local_interrupt_assignment)
				'' something went wrong
				case else:
					debug_wlog(debug_INFO, !"  -> config table entries corrupt!\n")
					return
			end select
		next
		
	end if
end sub

'' we don't do much more here because FROST can't handle multiple processors atm
'' TODO: proper SMP support
