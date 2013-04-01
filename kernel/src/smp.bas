#include "smp.bi"
#include "kernel.bi"
#include "debug.bi"

namespace smp
	function checksum (type_ptr as any ptr, size as uinteger) as ubyte
		dim checksum_byte as ubyte = 0
		dim bp as ubyte ptr = cast(ubyte ptr, type_ptr)
		
		for counter as uinteger = 0 to size-1 step 1
			checksum_byte += bp[counter]
		next counter
		
		return checksum_byte
	end function
	
	function find_floating_pointer_in_area (start as uinteger, size as uinteger) as floating_pointer_type ptr
		dim floating_pointer as floating_pointer_type ptr = cast(floating_pointer_type ptr, start)
		
		while (cuint(floating_pointer) < (start + size))
			'' signature found
			if (floating_pointer->signature = FP_SIGNATURE) then
				'' check checksum, sum of all bytes must be zero
				if (checksum(floating_pointer, sizeof(floating_pointer_type)) = 0) then
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

	function find_floating_pointer () as floating_pointer_type ptr
		dim floating_pointer as floating_pointer_type ptr
		
		floating_pointer = find_floating_pointer_in_area(0, &h400)
		if (floating_pointer <> nullptr) then return floating_pointer
		
		floating_pointer = find_floating_pointer_in_area(&h9FC00, &h400)
		if (floating_pointer <> nullptr) then return floating_pointer
		
		floating_pointer = find_floating_pointer_in_area(&hF0000, &h10000)
		return floating_pointer
	end function
	
	sub init ()
		dim floating_pointer as floating_pointer_type ptr = find_floating_pointer()
		dim config_table as config_table_type ptr
		
		if (floating_pointer = nullptr) then
			debug_wlog(debug.INFO, !"  -> floating pointer not found\n")
			return
		end if
		
		debug_wlog(debug.INFO, !"  -> floating pointer found: %hI\n", cuint(floating_pointer))
		
		if (floating_pointer->features(0) = 0) then
			config_table = cast(any ptr, floating_pointer->config_table)
			
			if (config_table->signature <> CT_SIGNATURE) then
				debug_wlog(debug.INFO, !"  -> signature of the config table is damaged!\n")
				return
			end if
			
			if (checksum(config_table, config_table->base_table_length) <> 0) then
				debug_wlog(debug.INFO, !"  -> checksum of the config table is wrong!\n")
				return
			end if
			
			'' pointer for the table
			dim entry as ubyte ptr = cast(ubyte ptr, cuint(config_table) + sizeof(config_table_type))
			dim num_procs as uinteger = 0
			
			for entry_count as uinteger = 0 to config_table->entry_count-1 step 1
				select case *entry
					'' processor
					case 0:
						num_procs += 1
						debug_wlog(debug.INFO, !"  -> processor #%I found\n", num_procs)
						entry += sizeof(cte_processor)
					'' bus
					case 1:
						entry += sizeof(cte_bus)
					''io apic
					case 2:
						entry += sizeof(cte_io_apic)
					'' io interrupt assignment
					case 3:
						entry += sizeof(cte_io_interrupt_assignment)
					'' local interrupt assignment
					case 4:
						entry += sizeof(cte_local_interrupt_assignment)
					'' something went wrong
					case else:
						debug_wlog(debug.INFO, !"  -> config table entries corrupt!\n")
						return
				end select
			next
			
		end if
	end sub
	
	'' we don't do much more here because FROST can't handle multiple processors atm
end namespace
