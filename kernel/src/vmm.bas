#include "vmm.bi"
#include "pmm.bi"
#include "kmm.bi"
#include "mem.bi"
#include "kernel.bi"
#include "panic.bi"

namespace vmm

	declare function get_pagetable_addr (pdir as uinteger ptr, index as uinteger) as uinteger ptr
	
    dim shared kernel_context as context
    dim shared paging_activated as byte = 0
    
    #define num_pages(n) (((n + &hFFF) and (&hFFFFF000)) shr 12)
    
    '' init () sets up the required structures and activates paging
    sub init ()
        '' initialize the kernel context (only used before the first task is started)
        '' the pagedir is also automatically mapped
        kernel_context.version = 0
        kernel_context.pagedir = pmm.alloc()
        memset(kernel_context.pagedir, 0, pmm.PAGE_SIZE)
        kernel_context.v_pagedir = cast(uinteger ptr, (PAGETABLES_VIRT_START shr 22)*4096*1024 + (PAGETABLES_VIRT_START shr 22)*4096)
        
        '' map the page directory
        map_page(kernel_context.pagedir, cuint(kernel_context.pagedir), cuint(kernel_context.pagedir), FLAG_PRESENT or FLAG_WRITE)
        
        '' map the page tables
        kernel_context.pagedir[PAGETABLES_VIRT_START shr 22] = cuint(kernel_context.pagedir) or FLAG_PRESENT or FLAG_WRITE
        
        '' map the kernel
        map_range(kernel_context.pagedir, cuint(kernel_start), cuint(kernel_start), cuint(kernel_end), (FLAG_PRESENT or FLAG_WRITE))
        
        '' map the video memory
        map_page(kernel_context.pagedir, &hB8000, &hB8000, (FLAG_PRESENT or FLAG_WRITE))    
        
        '' the pmm's bitmap lies inside the bss-section of the kernel, so it doesn't need extra mapping
        
        '' activate the context
        activate_context(@kernel_context)
        
        '' activate paging
        activate()
        
        paging_activated = -1
    end sub
    
    function alloc() as any ptr
		panic_error("NOT IMPLEMENTED YET!")
		return 0
		'' todo: implement
		'' this function should reserve a page, map it into the kernel's address space and return it's address
		dim page as any ptr = pmm.alloc()
		'' map it... search for a free place
		
		'' return the virtual address
	end function
   
    '' create_context () creates and clears space for a page-directory
    sub context_initialize (cntxt as context ptr)
        cntxt->version = 0
        cntxt->pagedir = pmm.alloc()
        memset(cntxt->pagedir, 0, pmm.PAGE_SIZE)
        cntxt->v_pagedir = kernel_automap(cntxt->pagedir, pmm.PAGE_SIZE)
    end sub
    
    '' map_page maps a single page into a given context
    function map_page (page_directory as uinteger ptr, virtual as uinteger, physical as uinteger, flags as uinteger) as integer
        dim pd_index as uinteger = (virtual shr 22)            '' extract the page-directory (bits 0-11)
        dim pt_index as uinteger = (virtual shr 12) and &h3FF  '' extract the page-table (bits 12-21)
        dim page_table as uinteger ptr
        
        '' is one of the addresses not 4k-aligned?
        if ((virtual and &hFFF) or (physical and &hFFF)) then
            return 0
        end if
        
        '' do the flags try to manipulate the address?
        if (flags and (not &h01F)) then return 0
        
        '' does the page table not exist?
        if (page_directory[pd_index] = 0) then
            '' reserve memory
            page_directory[pd_index] = cuint(pmm.alloc())
            '' clear it
            memset(cast(any ptr, page_directory[pd_index]), 0, pmm.PAGE_SIZE)
            '' set the flags
            page_directory[pd_index] or= (FLAG_PRESENT or FLAG_WRITE or FLAG_USERSPACE)
        end if
        
        '' fetch page-table address from page directory
		page_table = get_pagetable_addr(page_directory, pd_index)
        
        
        '' set address and flags
        page_table[pt_index] = (physical or flags)
        
        '' invalidate virtual address
        asm
            invlpg [virtual]
        end asm
        
        return -1
    end function
    
    sub unmap_page (page_directory as uinteger ptr, v_addr as any ptr)
		'' TODO: implement
		'' - should remove the mapping and, if possible, the page table
	end sub
    
    function map_range (page_directory as uinteger ptr, v_addr as uinteger, p_start as uinteger, p_end as uinteger, flags as uinteger) as integer
        'panic_error("this sub does not reverse the mapping if it fails")
        dim v_dest as uinteger = v_addr-(v_addr mod pmm.PAGE_SIZE)
        dim p_src as uinteger = p_start-(p_start mod pmm.PAGE_SIZE)
        
		'' TODO: first check if the area is free, and map only then
        
        while (p_src < p_end)
            if ((map_page(page_directory, v_dest, p_src, flags)=0)) then
                return 0
            end if
            p_src += pmm.PAGE_SIZE
            v_dest += pmm.PAGE_SIZE
        wend
        
        return -1
    end function
    
    function move_pages (source_pdir as uinteger ptr, dest_pdir as uinteger ptr, src_page as uinteger, dest_page as uinteger, pages as uinteger) as byte
		'' TODO: moves page mappings from one context to another
		return 0
	end function
	
	function get_pagetable_addr (pdir as uinteger ptr, index as uinteger) as uinteger ptr
		if (pdir = get_current_pagedir()) then
			'' the pdir is currently active
			if (paging_activated) then
				return cast(uinteger ptr, pdir[index] and &hFFFFF000)
			else
				return cast(uinteger ptr, PAGETABLES_VIRT_START + 4096*index)
			end if
		end if
		/'
		if (paging_activated) then
			'' this only works if we are in the kernel context
			return cast(uinteger ptr, PAGETABLES_VIRT_START + 4096*index)
		else
			return cast(uinteger ptr, pdir[index] and &hFFFFF000)
		end if
		'/
	end function
	
	function find_free_pages (pdir as uinteger ptr, num_pages as uinteger) as uinteger
		dim free_pages_found as uinteger = 0
		dim lower_limit as uinteger = pmm.PAGE_SIZE
		dim upper_limit as uinteger = &h40000000
		
		dim cur_page_table as uinteger = lower_limit shr 22
		dim cur_page as uinteger = (lower_limit shr 12) mod 1024
		
		while ((free_pages_found < num_pages) and ((cur_page_table shl 22) < upper_limit))
			if (pdir[cur_page_table] and FLAG_PRESENT) then
				'' ok, there is a page table, search the entries
				dim ptable as uinteger ptr = get_pagetable_addr(pdir, cur_page_table)
				
				while (cur_page < 1024)
					''is the entry free?
					if ((ptable[cur_page] and FLAG_PRESENT) = 0) then
						free_pages_found += 1
						if (free_pages_found >= num_pages) then exit while
					else
						
						free_pages_found = 0
						lower_limit = (cur_page_table shl 22) or ((cur_page+1) shl 12)
					end if
					cur_page += 1
				wend
			else
				'' the whole table is free
				free_pages_found += 1024
			end if
			
			cur_page = 0
			cur_page_table += 1
		wend
		
		if ((free_pages_found >= num_pages) and (lower_limit + num_pages * pmm.PAGE_SIZE <= upper_limit)) then
			return lower_limit
		else
			return 0
		end if
	end function
	
	function kernel_automap (p_start as any ptr, size as uinteger) as any ptr
		'' this maps a piece of physical memory to a free location in the kernel's address space
		'' and returns the virtual address
		if (size = 0) then return 0
		dim pagedir as uinteger ptr = iif(paging_activated, kernel_context.v_pagedir, kernel_context.pagedir)
		dim aligned_addr as uinteger = cuint(p_start) and &hFFFFF000
		dim aligned_bytes as uinteger = size + (cuint(p_start) - aligned_addr)
		
		dim vaddr as uinteger = find_free_pages(pagedir, num_pages(aligned_bytes))
		if (vaddr = 0) then
			'' we have a problem, we could not find enough space
			return 0
		end if
		
		map_range(pagedir, vaddr, aligned_addr, aligned_addr+aligned_bytes, FLAG_PRESENT or FLAG_WRITE)
		return vaddr + (p_start - aligned_addr)
	end function
    
    function get_p_addr (page_directory as uinteger ptr, v_addr as uinteger, reserve_if_na as ubyte) as uinteger
        '' TODO: needs to use get_pagetable_addr, otherwise it will fail when paging is activated
        
        dim pd_index as uinteger = (v_addr shr 22)
        dim pt_index as uinteger = (v_addr shr 12) and &h3FF
        dim page_table as uinteger ptr
        
        if (page_directory[pd_index] = 0) then
            if (reserve_if_na = 1) then
                page_directory[pd_index] = cuint(pmm.alloc())
                memset(cast(any ptr, page_directory[pd_index]), 0, pmm.PAGE_SIZE)
                page_directory[pd_index] or= (FLAG_PRESENT or FLAG_WRITE or FLAG_USERSPACE)
            else
                return 0
            end if
        end if
        
        page_table = cast(uinteger ptr, (page_directory[pd_index] and &hFFFFF000))
        
        if (page_table[pt_index] = 0) then
            if (reserve_if_na = 1) then
                page_table[pt_index] = cuint(pmm.alloc())
                memset(cast(any ptr, page_table[pt_index]), 0, pmm.PAGE_SIZE)
                page_table[pt_index] or= (FLAG_PRESENT or FLAG_WRITE or FLAG_USERSPACE)
            else
                return 0
            end if
        end if
        
        return ((page_table[pt_index] and &hFFFFF000) or (v_addr and &hFFF))
    end function
    
    sub activate_context (cntxt as context ptr)
        dim pagedir as uinteger ptr = cntxt->pagedir
        asm
            mov eax, [pagedir]
            mov cr3, eax
        end asm
    end sub
    
    '' activate () sets the paging-bit (31) in cr0
    sub activate ()
        asm
            mov eax, cr0
            or eax, &h80000000
            mov cr0, eax
        end asm
    end sub
    
    function get_current_pagedir () as uinteger ptr
		asm
			mov eax, cr0
			mov [function], eax
		end asm
	end function
end namespace
