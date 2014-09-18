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

#include "pmm.bi"
#include "mem.bi"
#include "kernel.bi"
#include "multiboot.bi"
#include "spinlock.bi"
#include "panic.bi"

const bitmap_size = 32768

'' our memory bitmap. bit=0 : page used; bit=1 : page free
dim shared bitmap (0 to bitmap_size-1) as uinteger
'' the amount of free memory
dim shared free_mem as uinteger = 0
dim shared total_mem as uinteger = 0

dim shared pmm_lock as spinlock = 0

declare sub pmm_mark_used (page as any ptr)

sub pmm_init (mbinfo as multiboot_info ptr)
	'' 1. mark the whole memory as used
	'' 2. free the memory marked as free in the memory-map
	'' 3. mark the whole memory used by the kernel as used
	'' 4. mark the video memory as used
	'' 5. mark the modules and their cmdline as used
	
	if ((mbinfo->flags and MULTIBOOT_INFO_MEM_MAP) = 0) then
		panic_error(!"Memory map not available!\n")
	end if
	
	dim mmap as multiboot_mmap_entry ptr = cast(multiboot_mmap_entry ptr, mbinfo->mmap_addr)
	dim mmap_end as multiboot_mmap_entry ptr = cast(multiboot_mmap_entry ptr, (mbinfo->mmap_addr + mbinfo->mmap_length))
	
	'' mark the whole memory as occupied
	memset(@bitmap(0), 0, bitmap_size)
	
	'' free the memory listed in the memory-map
	while (mmap < mmap_end)
		'' only free regions that are marked as available
		if (mmap->type = MULTIBOOT_MEMORY_AVAILABLE) then
			dim addr as addr_t = mmap->addr
			dim end_addr as addr_t = (mmap->addr+mmap->len)
			
			if (cuint((mmap->addr shr 32) and &hFFFFFFFF) = 0) then
				total_mem += mmap->len
				
				'' free each block of the region
				while (addr < end_addr)
					'' free one block at a time
					pmm_free(cast(any ptr, cuint(addr)))
					addr += PAGE_SIZE
				wend
			end if
		end if
		'' go to the next entry of the map
		mmap = cast(multiboot_mmap_entry ptr, cuint(mmap)+mmap->size+sizeof(multiboot_uint32_t))
	wend
	
	'' mark the memory used by the kernel as used (this includes the mbinfo-structure and stack)
	dim kernel_addr as addr_t = caddr(kernel_start)
	dim kernel_end_addr as addr_t = caddr(kernel_end)
	while (kernel_addr < kernel_end_addr)
		pmm_mark_used(cast(any ptr, kernel_addr))
		kernel_addr += PAGE_SIZE
	wend
	
	'' mark the video-memory as used
	pmm_mark_used(cast(any ptr, &hB8000))
	
	'' reserve the memory of the multiboot modules
	if (mbinfo->mods_count = 0) then return
	dim module_addr as addr_t
	dim module_end_addr as addr_t
	dim module_ptr as multiboot_mod_list ptr = cast(any ptr, mbinfo->mods_addr)
	
	'' iterate over the module list
	for counter as uinteger = 1 to mbinfo->mods_count
		module_addr = module_ptr->mod_start
		module_end_addr = module_ptr->mod_end
		
		'' mark the image
		while (module_addr < module_end_addr)
			pmm_mark_used(cast(any ptr, module_addr))
			module_addr += PAGE_SIZE
		wend
		
		'' mark the cmdline
		pmm_mark_used(cast(any ptr, mbinfo->cmdline))
		
		module_ptr += 1
	next
end sub

function pmm_alloc (num_pages as uinteger) as any ptr
	if (num_pages = 0) then
		panic_error(!"kernel tried to reserve zero pages\n")
	end if
	
	spinlock_acquire(@pmm_lock)
	
	dim pages_found as uinteger = 0
	dim pages_start as uinteger = 0
	
	'' find some free pages
	for counter as uinteger = 0 to bitmap_size-1
		if (bitmap(counter) = &hFFFFFFFF) then
			'' all bits of the uinteger are marked free
			pages_found += 32
		elseif (bitmap(counter) = 0) then
			'' all bits of the uinteger are marked used
			pages_found = 0
			pages_start = (counter+1)*32
		else
			'' at least one page in this block is occupied
			for bitcounter as uinteger = 0 to 31
				if (bitmap(counter) and (1 shl bitcounter)) then
					'' this page is free
					pages_found += 1
				else
					'' this page is occupied, reset our found-counter and remember the next position
					pages_found = 0
					pages_start = counter*32 + bitcounter + 1
				end if
				
				'' enough free pages found?
				if (pages_found >= num_pages) then exit for
			next
		end if
		
		'' enough free pages found?
		if (pages_found >= num_pages) then exit for
	next
	
	'' if the loop didn't find enough pages, return a null-pointer
	if (pages_found >= num_pages) then
		'' only reserve needed blocks, not all available
		for counter as uinteger = 0 to num_pages-1
			pmm_mark_used(cast(any ptr, (pages_start+counter)*PAGE_SIZE))
		next
		
		'' return the address
		function = cast(any ptr, pages_start * PAGE_SIZE)
	else
		function = nullptr
	end if
	
	'' never forget to release the lock
	spinlock_release(@pmm_lock)
end function

sub pmm_free (page as any ptr, num_pages as uinteger)
	spinlock_acquire(@pmm_lock)
	
	dim blocks_start as uinteger = cuint(page) \ PAGE_SIZE
	
	for counter as uinteger = 0 to num_pages-1
		dim index as uinteger = (blocks_start+counter) shr 5
		dim modifier as uinteger = (1 shl ((blocks_start+counter) mod 32))
		
		'' if the page wasn't occupied before, we panic
		if ((bitmap(index) and modifier) <> 0) then
			panic_error("Tried to free already free physical memory area!")
		end if
		
		'' increase the free memory variable
		free_mem += PAGE_SIZE
		
		'' set the bit
		bitmap(index) or= modifier
	next
	
	spinlock_release(@pmm_lock)
end sub

sub pmm_mark_used (page as any ptr)
	dim index as uinteger = cuint(page) \ PAGE_SIZE
	dim modifier as uinteger  = (1 shl (index mod 32))
	index shr= 5 '' faster version of "index \= 32"
	
	'' if the page wasn't occupied before, the free memory variable is reduced
	if (bitmap(index) and modifier) then free_mem -= PAGE_SIZE
	
	'' set the bit
	bitmap(index) and= (not(modifier))
end sub

function pmm_get_total () as uinteger
	return total_mem
end function

function pmm_get_free () as uinteger
	return free_mem
end function
