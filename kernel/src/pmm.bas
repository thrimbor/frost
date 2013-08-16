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

namespace pmm
    '' our memory bitmap. bit=0 : page used; bit=1 : page free
    dim shared bitmap (0 to pmm.bitmap_size-1) as uinteger
    '' the amount of free memory
    dim shared free_mem as uinteger = 0
    dim shared total_mem as uinteger = 0
    
    dim shared pmm_lock as spinlock = 0
    
    sub init (mbinfo as multiboot_info ptr)
        '' this sub will take 3 steps:
        '' 1. mark the whole memory as used
        '' 2. free the memory marked as free in the memory-map
        '' 3. mark the whole memory used by the kernel as used
        
        dim mmap as multiboot_mmap_entry ptr = cast(multiboot_mmap_entry ptr, mbinfo->mmap_addr)
        dim mmap_end as multiboot_mmap_entry ptr = cast(multiboot_mmap_entry ptr, (mbinfo->mmap_addr + mbinfo->mmap_length))
        
        '' mark the whole memory as occupied
        memset(@bitmap(0), 0, pmm.bitmap_size)
        
        '' free the memory listed in the memory-map
        while (mmap < mmap_end)
            total_mem += mmap->len
            '' only free regions that are marked as available
            if (mmap->type = MULTIBOOT_MEMORY_AVAILABLE) then
                dim addr as addr_t = mmap->addr
                dim end_addr as addr_t = (mmap->addr+mmap->len)
                
                '' free each block of the region
                while (addr < end_addr)
                    '' free one block at a time
                    pmm.free(cast(any ptr, addr))
                    addr += pmm.PAGE_SIZE
                wend
            end if
            '' go to the next entry of the map
            mmap += 1
        wend
        
        '' mark the memory used by the kernel as used (this includes the mbinfo-structure and stack)
        dim kernel_addr as addr_t = caddr(kernel_start)
        dim kernel_end_addr as addr_t = caddr(kernel_end)
        while (kernel_addr < kernel_end_addr)
            pmm.mark_used(cast(any ptr, kernel_addr))
            kernel_addr += pmm.PAGE_SIZE
        wend
        
        '' mark the video-memory as used
        pmm.mark_used(cast(any ptr, &hB8000))
        
        '' the mbinfo-structure was copied to the kernel stack, so it
        '' doesn't need to be marked because: kernel_start < mbinfo < kernel_end
        '' however, the modules need to be protected
        if (mbinfo->mods_count = 0) then return
        dim module_addr as addr_t
        dim module_end_addr as addr_t
        dim module_ptr as multiboot_mod_list ptr = cast(any ptr, mbinfo->mods_addr)
        for counter as uinteger = 1 to mbinfo->mods_count
            module_addr = module_ptr->mod_start
            module_end_addr = module_ptr->mod_end
            while (module_addr < module_end_addr)
                pmm.mark_used(cast(any ptr, module_addr))
                module_addr += pmm.PAGE_SIZE
            wend
            module_ptr += 1
        next
    end sub
    
    function alloc (num_pages as uinteger = 1) as any ptr
		spinlock_acquire(@pmm_lock)
		
		dim pages_found as uinteger = 0
		dim pages_start as uinteger = 0
		
		'' find some free pages
		for counter as uinteger = 0 to pmm.bitmap_size-1
			if (pmm.bitmap(counter) = &hFFFFFFFF) then
				'' all bits of the uinteger are marked free
				pages_found += 32
			else
				'' at least one page in this block is occupied
				for bitcounter as uinteger = 0 to 31
					if (pmm.bitmap(counter) and (1 shl bitcounter)) then
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
			for i as uinteger = 0 to num_pages-1
				mark_used(cast(any ptr, (pages_start+i)*pmm.PAGE_SIZE))
			next
			
			'' return the address
			function = cast(any ptr, pages_start * pmm.PAGE_SIZE)
		else
			function = nullptr
		end if
		
		'' never forget to release the lock
		spinlock_release(@pmm_lock)
	end function
	
	sub free (page as any ptr, num_pages as uinteger)
		spinlock_acquire(@pmm_lock)
		
		dim blocks_start as uinteger = cuint(page) \ pmm.PAGE_SIZE
		
		for i as uinteger = 0 to num_pages-1
			dim index as uinteger = (blocks_start+i) shr 5
			dim modifier as uinteger = (1 shl ((blocks_start+i) mod 32))
			
			'' if the page wasn't occupied before, we panic
			if ((pmm.bitmap(index) and modifier) <> 0) then
				panic_error("Tried to free already free physical memory area!")
			end if
			
			'' increase the free memory variable
			free_mem += pmm.PAGE_SIZE
			
			'' set the bit
			pmm.bitmap(index) or= modifier
		next
		
		spinlock_release(@pmm_lock)
	end sub
    
    sub mark_used (page as any ptr)
        dim index as uinteger = cuint(page) \ pmm.PAGE_SIZE
        dim modifier as uinteger  = (1 shl (index mod 32))
        index shr= 5 '' faster version of "index \= 32"
        
        '' if the page wasn't occupied before, the free memory variable is reduced
        if (pmm.bitmap(index) and modifier) then free_mem -= pmm.PAGE_SIZE
        
        '' set the bit
        pmm.bitmap(index) and= (not(modifier))
    end sub
    
    function get_total () as uinteger
        return total_mem
    end function
    
    function get_free () as uinteger
        return free_mem
    end function
end namespace
