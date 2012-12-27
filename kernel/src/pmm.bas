#include "pmm.bi"
#include "mem.bi"
#include "kernel.bi"
#include "multiboot.bi"

namespace pmm
    '' our memory bitmap. bit=0 : page used; bit=1 : page free
    dim shared bitmap (0 to pmm.bitmap_size-1) as uinteger
    '' the amount of free memory
    dim shared free_mem as uinteger = 0
    dim shared total_mem as uinteger = 0
    
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
    
    
    function alloc () as any ptr
        '' first search for a free place
        dim counter as uinteger
        dim bitcounter as uinteger
        
        for counter=0 to pmm.bitmap_size-1
            if (pmm.bitmap(counter) > 0) then
                '' we found a free place and need to search for the set bit
                for bitcounter=0 to 31 step 1
                    if (pmm.bitmap(counter) and (1 shl bitcounter)) then
                        '' found it, unset the bit and return the address
                        pmm.bitmap(counter) and= not(1 shl bitcounter)
                        free_mem -= pmm.PAGE_SIZE
                        return cast(any ptr, ((counter*32+bitcounter)*pmm.PAGE_SIZE))
                    end if
                next
            end if
        next
        
        '' if we get here, there's nothing free
        return 0
    end function
    
    function alloc (blocks as uinteger) as any ptr
		dim counter as uinteger = 0
		dim blocks_found as uinteger = 0
		dim blocks_start as uinteger = 0
		
		'' find some free blocks
		while (blocks_found <  blocks)
			if (pmm.bitmap(counter) = 0) then
				blocks_found += 32
			else
				for bitcounter as uinteger = 0 to 31
					if (pmm.bitmap(counter) and (1 shl bitcounter)) then
						blocks_found += 1
					else
						blocks_found = 0
						blocks_start = counter*32 + bitcounter + 1
					end if
					
					if (blocks_found >= blocks) then exit for
				next
			end if
			
			counter += 1
		wend
		
		'' if we found no blocks, return a null-pointer
		if (blocks_found = 0) then return nullptr
		
		'' now reserve them
		for i as uinteger = 0 to blocks_found-1
			mark_used(cast(any ptr, (blocks_start+i)*pmm.PAGE_SIZE))
		next
		
		'' return the address
		return cast(any ptr, blocks_start * pmm.PAGE_SIZE)
	end function
	
	sub free (page as any ptr, num_pages as uinteger)
		dim blocks_start as uinteger = cuint(page) \ pmm.PAGE_SIZE
		
		for i as uinteger = 0 to num_pages-1
			dim index as uinteger = (blocks_start+i) shr 5
			dim modifier as uinteger = (1 shl (blocks_start+i))
			
			'' if the page was occupied before, we increase the free memory variable
			if ((pmm.bitmap(index) and modifier) = 0) then free_mem += pmm.PAGE_SIZE
			
			'' set the bit
			pmm.bitmap(index) or= modifier
		next
	end sub
    
    sub free (page as any ptr)
        dim index as uinteger = cuint(page) \ pmm.PAGE_SIZE
        dim modifier as uinteger = (1 shl (index mod 32))
        index shr= 5 '' faster version of "index \= 32"
        
        '' if the page was occupied before, the free memory variable is increased
        if ((pmm.bitmap(index) and modifier) = 0) then free_mem += pmm.PAGE_SIZE
        
        '' set the bit
        pmm.bitmap(index) or= modifier
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
