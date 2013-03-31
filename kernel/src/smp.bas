#include "smp.bi"
#include "kernel.bi"
#include "debug.bi"

namespace smp
	function find_floating_pointer_in_area (start as uinteger, size as uinteger) as floating_pointer_type ptr
		dim floating_pointer as floating_pointer_type ptr = cast(floating_pointer_type ptr, start)
		
		while (cuint(floating_pointer) < (start + size))
			'' signature found
			if (floating_pointer->signature = FP_SIGNATURE) then
				'' check checksum, sum of all bytes must be zero
				dim checksum as ubyte = 0
				dim fp as ubyte ptr = cast(ubyte ptr, floating_pointer)
				for counter as uinteger = 0 to sizeof(floating_pointer_type)-1 step 1
					checksum += fp[counter]
				next
				
				if (checksum = 0) then
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
		
		if (floating_pointer = nullptr) then
			debug_wlog(debug.INFO, !"  -> floating pointer not found\n")
			return
		end if
		
		debug_wlog(debug.INFO, !"  -> floating pointer found: %hI\n", cuint(floating_pointer))
		debug_wlog(debug.INFO, !"  -> SMP support not implemented yet\n")
	end sub
end namespace
