/'
 ' FROST x86 microkernel
 ' Copyright (C) 2010-2015  Stefan Schmidt
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

#include "pmm.bi"
#include "spinlock.bi"
#include "kernel.bi"
#include "vmm.bi"
#include "panic.bi"

dim shared pmm_normal_lock as spinlock = 0

dim shared pmm_stack_min as uinteger ptr = cast(uinteger ptr, PMM_STACK_TOP)
dim shared pmm_stack_ptr as uinteger ptr = cast(uinteger ptr, PMM_STACK_TOP)
dim shared pmm_ready as boolean = false

function pmm_alloc_normal () as any ptr
	if (not (pmm_ready and vmm_is_paging_ready())) then return nullptr '' let the request fall through
	
	if (pmm_stack_ptr = PMM_STACK_TOP) then return nullptr
	
	spinlock_acquire(@pmm_normal_lock)
	
	if (pmm_stack_ptr = (pmm_stack_min + PMM_STACK_ENTRIES_PER_PAGE)) then
		'' resolve page address
		function = vmm_resolve(vmm_get_current_context(), pmm_stack_min)
		
		'' unmap page
		vmm_unmap_page(vmm_get_current_context(), pmm_stack_min)
		
		'' adjust stack size
		pmm_stack_min += PMM_STACK_ENTRIES_PER_PAGE
	else
		if (vmm_is_paging_activated()) then
			function = cast(any ptr, *pmm_stack_ptr)
		else
			dim pmm_stack_ptr_phys as uinteger ptr = vmm_resolve(vmm_get_current_context(), pmm_stack_ptr)
			function = cast(any ptr, *pmm_stack_ptr_phys)
		end if
		pmm_stack_ptr += 1
	end if
	
	spinlock_release(@pmm_normal_lock)
end function

sub pmm_free_normal (addr as any ptr)
	'' make sure the address is page-aligned
	addr = cast(any ptr, cuint(addr) and VMM_PAGE_MASK)
	
	spinlock_acquire(@pmm_normal_lock)
	
	'' stack full?
	if (pmm_stack_ptr = pmm_stack_min) then
		vmm_map_page(vmm_get_current_context(), pmm_stack_min-PMM_STACK_ENTRIES_PER_PAGE, addr, VMM_FLAGS.KERNEL_DATA)
		pmm_stack_min -= PMM_STACK_ENTRIES_PER_PAGE
		assert(vmm_resolve(vmm_get_current_context(), pmm_stack_min) <> nullptr)
	else
		'' put the page on the stack
		pmm_stack_ptr -= 1
				
		if (vmm_is_paging_activated()) then
			*pmm_stack_ptr = cuint(addr)
		else
			dim pmm_stack_ptr_phys as uinteger ptr = vmm_resolve(vmm_get_current_context(), pmm_stack_ptr)
			assert(pmm_stack_ptr_phys <> nullptr)
			*pmm_stack_ptr_phys = cuint(addr)
		end if
	end if
	
	pmm_ready = true
	
	spinlock_release(@pmm_normal_lock)
end sub
