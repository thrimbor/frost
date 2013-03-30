#include "vmm.bi"
#include "pmm.bi"
#include "kmm.bi"
#include "mem.bi"
#include "kernel.bi"
#include "panic.bi"

namespace vmm

	declare function get_pagetable_addr (cntxt as context ptr, index as uinteger) as uinteger ptr
	
    dim shared kernel_context as context
    dim shared current_context as context ptr
    dim shared paging_activated as byte = 0
    
    #define num_pages(n) (((n + &hFFF) and (&hFFFFF000)) shr 12)
    
    function allocate_page (entry as uinteger ptr) as boolean
		'' allocate a free physical page frame
		dim p as any ptr = pmm.alloc()
		if (p = nullptr) then return false
		
		'' map it
		*entry = cuint(p) or PTE_FLAGS.PRESENT
    end function
    
    sub free_page (entry as uinteger ptr)
		dim p as any ptr = cast(any ptr, (*entry and PTE_FLAGS.FRAME))
		if (p <> nullptr) then pmm.free(p)
		
		*entry and= not PTE_FLAGS.PRESENT
	end sub
    
    '' init () sets up the required structures and activates paging
    sub init ()
        '' initialize the kernel context (only used before the first task is started)
        '' the pagedir is also automatically mapped
        kernel_context.version = 0
        kernel_context.p_pagedir = pmm.alloc()
        memset(kernel_context.p_pagedir, 0, pmm.PAGE_SIZE)
        kernel_context.v_pagedir = kernel_context.p_pagedir
        
        '' we need to activate the context early for kernel_context to be valid
        activate_context(@kernel_context)
        
        '' map the page directory
        map_page(@kernel_context, kernel_context.p_pagedir, kernel_context.p_pagedir, PTE_FLAGS.PRESENT or PTE_FLAGS.WRITABLE)
        
        '' map the page tables
        kernel_context.p_pagedir[PAGETABLES_VIRT_START shr 22] = cuint(kernel_context.p_pagedir) or PTE_FLAGS.PRESENT or PTE_FLAGS.WRITABLE
        
        '' map the kernel 1:1
        map_range(@kernel_context, kernel_start, kernel_start, kernel_end, (PTE_FLAGS.PRESENT or PTE_FLAGS.WRITABLE))
        
        '' map the video memory 1:1
        map_page(@kernel_context, cast(any ptr, &hB8000), cast(any ptr, &hB8000), (PTE_FLAGS.PRESENT or PTE_FLAGS.WRITABLE))
        
        kernel_context.v_pagedir = cast(uinteger ptr, (PAGETABLES_VIRT_START shr 22)*4096*1024 + (PAGETABLES_VIRT_START shr 22)*4096)
        
        '' activate paging
        activate()
        
        paging_activated = -1
    end sub
    
    function alloc() as any ptr
		panic_error(!"NOT IMPLEMENTED YET!")
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
        cntxt->p_pagedir = pmm.alloc()
        memset(cntxt->p_pagedir, 0, pmm.PAGE_SIZE)
        cntxt->v_pagedir = kernel_automap(cntxt->p_pagedir, pmm.PAGE_SIZE)
    end sub
    
    '' map_page maps a single page into a given context
    function map_page (cntxt as context ptr, virtual as any ptr, physical as any ptr, flags as uinteger) as boolean
        dim pagedir_entry_ptr as uinteger ptr = @cntxt->v_pagedir[GET_PAGEDIR_INDEX(cuint(virtual))]
        
        '' is one of the addresses not 4k-aligned?
        if ((cuint(virtual) and &hFFF) or (cuint(physical) and &hFFF)) then return false
        
        '' do the flags try to manipulate the address?
        if (flags and (not &h01F)) then return false
        
        '' page table not present?
        if ((*pagedir_entry_ptr and PDE_FLAGS.PRESENT) <> PDE_FLAGS.PRESENT) then
            '' reserve memory
            *pagedir_entry_ptr = cuint(pmm.alloc())
            '' clear it
            memset(cast(any ptr, *pagedir_entry_ptr), 0, pmm.PAGE_SIZE)
            '' set the flags
            *pagedir_entry_ptr or= PDE_FLAGS.PRESENT or PDE_FLAGS.WRITABLE or PDE_FLAGS.USERSPACE
        end if
        
        '' fetch page-table address from page directory
		dim page_table as uinteger ptr = get_pagetable_addr(cntxt, GET_PAGEDIR_INDEX(cuint(virtual)))
        
        '' set address and flags
        page_table[GET_PAGETABLE_INDEX(cuint(virtual))] = (cuint(physical) or flags)
        
        '' invalidate virtual address
        asm
            invlpg [virtual]
        end asm
        
        return true
    end function
    
    function map_range (cntxt as context ptr, v_addr as any ptr, p_start as any ptr, p_end as any ptr, flags as uinteger) as boolean
        'panic_error("this sub does not reverse the mapping if it fails")
        dim v_dest as uinteger = cuint(v_addr)-(cuint(v_addr) mod pmm.PAGE_SIZE)
        dim p_src as uinteger = cuint(p_start)-(cuint(p_start) mod pmm.PAGE_SIZE)
        
		'' TODO: first check if the area is free, and map only then
        
        while (p_src < p_end)
            if ((map_page(cntxt, cast(any ptr, v_dest), cast(any ptr, p_src), flags)=0)) then
                return false
            end if
            p_src += pmm.PAGE_SIZE
            v_dest += pmm.PAGE_SIZE
        wend
        
        return true
    end function
    
    function move_pages (src as context ptr, dest as context ptr, src_addr as any ptr, dest_addr as any ptr, pages as uinteger) as boolean
		'' TODO: moves page mappings from one context to another
		
		dim src_cur as uinteger = cuint(src_addr)
		dim dest_cur as uinteger = cuint(dest_addr)
		
		for counter as uinteger = 1 to pages step 1
			
		next
		
		return false
	end function
	
	
	'' TODO: a function to free the automapped space
	function get_pagetable_addr (cntxt as context ptr, index as uinteger) as uinteger ptr
		dim pdir as uinteger ptr = cntxt->v_pagedir
		
		'' is there no pagetable?
		if ((pdir[index] and PTE_FLAGS.PRESENT) = 0) then return nullptr
		
		if (cntxt->p_pagedir = get_current_pagedir()) then
			'' the pdir is currently active
			if (paging_activated) then
				return cast(uinteger ptr, PAGETABLES_VIRT_START + 4096*index)
			else
				return cast(uinteger ptr, pdir[index] and PTE_FLAGS.FRAME)
			end if
		else
			return kernel_automap(cast(any ptr, (pdir[index] and PTE_FLAGS.FRAME)), pmm.PAGE_SIZE)
		end if
	end function
	
	sub free_pagetable (cntxt as context ptr, table as uinteger ptr)
		if (cntxt->p_pagedir <> get_current_pagedir()) then
			
		end if
	end sub
	
	function find_free_pages (cntxt as context ptr, num_pages as uinteger) as uinteger
		dim pdir as uinteger ptr = cntxt->v_pagedir
		dim free_pages_found as uinteger = 0
		dim lower_limit as uinteger = pmm.PAGE_SIZE
		dim upper_limit as uinteger = &h40000000
		
		dim cur_page_table as uinteger = lower_limit shr 22
		dim cur_page as uinteger = (lower_limit shr 12) mod 1024
		
		while ((free_pages_found < num_pages) and ((cur_page_table shl 22) < upper_limit))
			if (pdir[cur_page_table] and PTE_FLAGS.PRESENT) then
				'' ok, there is a page table, search the entries
				dim ptable as uinteger ptr = get_pagetable_addr(cntxt, cur_page_table)
				
				while (cur_page < 1024)
					''is the entry free?
					if ((ptable[cur_page] and PTE_FLAGS.PRESENT) = 0) then
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
		'dim pagedir as uinteger ptr = iif(paging_activated, kernel_context.v_pagedir, kernel_context.p_pagedir)
		dim aligned_addr as uinteger = cuint(p_start) and PTE_FLAGS.FRAME
		dim aligned_bytes as uinteger = size + (cuint(p_start) - aligned_addr)
		
		dim vaddr as uinteger = find_free_pages(@kernel_context, num_pages(aligned_bytes))
		if (vaddr = 0) then
			'' we have a problem, we could not find enough space
			return 0
		end if
		
		map_range(@kernel_context, cast(any ptr, vaddr), cast(any ptr, aligned_addr), cast(any ptr, aligned_addr+aligned_bytes), PTE_FLAGS.PRESENT or PTE_FLAGS.WRITABLE)
		return vaddr + (p_start - aligned_addr)
	end function
	
	function resolve (cntxt as context ptr, vaddr as uinteger) as uinteger
		dim pagetable_virt as uinteger ptr 
		dim result as uinteger
		
		'' get the pagetable
		pagetable_virt = get_pagetable_addr(cntxt, GET_PAGEDIR_INDEX(vaddr))
		
		'' pagetable not present?
		if (pagetable_virt = 0) then return 0
		
		'' get the entry of the page
		result = pagetable_virt[GET_PAGETABLE_INDEX(vaddr)]
		
		if (result and PTE_FLAGS.PRESENT) then
			'' page present
			result = (result and PTE_FLAGS.FRAME) or (vaddr and &hFFF)
		else
			'' page not present
			result = 0
		end if
		
		'' free the pagetable
		free_pagetable(cntxt, pagetable_virt)
		
		return result
	end function
    
    #if 0
    function get_p_addr (cntxt as context ptr, v_addr as uinteger, reserve_if_na as ubyte) as uinteger
        '' TODO: needs to use get_pagetable_addr, otherwise it will fail when paging is activated
        
        dim page_directory as uinteger ptr = cntxt->v_pagedir
        dim pd_index as uinteger = (v_addr shr 22)
        dim pt_index as uinteger = (v_addr shr 12) and &h3FF
        dim page_table as uinteger ptr
        
        if (page_directory[pd_index] = 0) then
            if (reserve_if_na = 1) then
                page_directory[pd_index] = cuint(pmm.alloc())
                memset(cast(any ptr, page_directory[pd_index]), 0, pmm.PAGE_SIZE)
                page_directory[pd_index] or= (PTE_FLAGS.PRESENT or PTE_FLAGS.WRITABLE or PTE_FLAGS.USERSPACE)
            else
                return 0
            end if
        end if
        
        page_table = cast(uinteger ptr, (page_directory[pd_index] and PTE_FLAGS.FRAME))
        
        if (page_table[pt_index] = 0) then
            if (reserve_if_na = 1) then
                page_table[pt_index] = cuint(pmm.alloc())
                memset(cast(any ptr, page_table[pt_index]), 0, pmm.PAGE_SIZE)
                page_table[pt_index] or= (PTE_FLAGS.PRESENT or PTE_FLAGS.WRITABLE or PTE_FLAGS.USERSPACE)
            else
                return 0
            end if
        end if
        
        return ((page_table[pt_index] and PTE_FLAGS.FRAME) or (v_addr and &hFFF))
    end function
    #endif
    sub activate_context (cntxt as context ptr)
        current_context = cntxt
        dim pagedir as uinteger ptr = cntxt->p_pagedir
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
		return current_context->p_pagedir
	end function
end namespace
