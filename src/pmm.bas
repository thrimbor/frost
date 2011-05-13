#include once "inc/pmm.bi"
#include once "inc/multiboot.bi"

'// these two symbols are provided by our linkerscript. do not access them directly, they don't have variables behind them!
extern kernel_start alias "kernel_start" as byte
extern kernel_end   alias "kernel_end"   as byte

namespace pmm
    '// our memory bitmap. bit=0 : page used; bit=1 : page free
    dim shared bitmap (0 to pmm.bitmap_size-1) as uinteger
    
    sub init (mbinfo as multiboot_info ptr)
        '// this sub will take 3 steps:
        '// 1. mark the whole memory as used
        '// 2. free the memory marked as free in the memory-map
        '// 3. mark the whole memory used by the kernel as used
        dim mmap as multiboot_mmap_entry ptr = cast(multiboot_mmap_entry ptr, mbinfo->mmap_addr)
        dim mmap_end as multiboot_mmap_entry ptr = cast(multiboot_mmap_entry ptr, (mbinfo->mmap_addr + mbinfo->mmap_length))
        
        '// free the memory listed in the memory-map
        while (mmap < mmap_end)
            if (mmap->type = MULTIBOOT_MEMORY_AVAILABLE) then
                dim addr as uinteger = mmap->addr
                dim end_addr as uinteger = (mmap->addr+mmap->len)
                
                while (addr < end_addr)
                    pmm.free(cast(any ptr, addr))
                    addr += 4096
                wend
            end if
            '// go to the next entry of the map
            mmap += 1
        wend
        
        '// mark the memory used by the kernel as used
        dim addr as any ptr = @kernel_start
        while (addr < cast(any ptr, @kernel_end))
            pmm.mark_used(addr)
            addr += 4096
        wend
        
        '// what's still missing:
        '// - the multiboot-info structure
        '// - the multiboot-modules
    end sub
    
    
    function alloc () as any ptr
        '// first search for a free place
        dim counter as uinteger
        dim bitcounter as uinteger
        
        for counter=0 to pmm.bitmap_size-1 step 1
            if (not(pmm.bitmap(counter)=0)) then
                '// we found a free place and need to search for the set bit
                for bitcounter=0 to 31 step 1
                    if (pmm.bitmap(counter) and (1 shl bitcounter)) then
                        '// found it, unset the bit and return the address
                        pmm.bitmap(counter) and= not(1 shl bitcounter)
                        return cast(any ptr, ((counter*32+bitcounter)*4096))
                    end if
                next
            end if
        next
        
        '// if we get here, there's nothing free
        return 0
    end function
    
    sub free (page as any ptr)
        dim index as uinteger = cast(uinteger, page) / 4096
        pmm.bitmap(index/32) or= (1 shl (index mod 32))
    end sub
    
    sub mark_used (page as any ptr)
        dim index as uinteger = cast(uinteger, page) / 4096
        pmm.bitmap(index/32) and= not(1 shl (index mod 32))
    end sub
end namespace
