#include once "inc/paging.bi"
#include once "inc/pmm.bi"

namespace paging
    dim shared kernel_context as uinteger ptr
    
    sub init ()
        kernel_context = pmm.alloc()
        pmm.memset(cuint(kernel_context), 0, 4096)
        
        for counter as uinteger = 0 to 63*1024*1024 step 4096
            map_page(kernel_context, counter, counter, (FLAG_PRESENT or FLAG_WRITE or FLAG_USERSPACE))
        next
        
        activate_directory(kernel_context)
        
        activate()
    end sub
    
    function map_page (page_directory as uinteger ptr, virtual as uinteger, physical as uinteger, flags as uinteger) as byte
        dim pd_index as uinteger = (virtual shr 22)
        dim pt_index as uinteger = (virtual shr 12) and &h3FF
        dim page_table as uinteger ptr
        
        if (((virtual mod 4096)>0) or ((physical mod 4096)>0)) then
            return 0
        end if
        
        if (page_directory[pd_index] = 0) then
            page_directory[pd_index] = cuint(pmm.alloc())
            pmm.memset(page_directory[pd_index], 0, 4096)
            page_directory[pd_index] or= (FLAG_PRESENT or FLAG_WRITE or FLAG_USERSPACE)
        end if
        
        page_table = cast(uinteger ptr, (page_directory[pd_index] and &hFFFFF000))
        
        page_table[pt_index] = (physical or flags)
        
        asm
            invlpg [virtual]
        end asm
        
        return -1
    end function
    
    function get_p_addr (page_directory as uinteger ptr, v_addr as uinteger, reserve_if_na as ubyte) as uinteger
        dim pd_index as uinteger = (v_addr shr 22)
        dim pt_index as uinteger = (v_addr shr 12) and &h3FF
        dim page_table as uinteger ptr
        
        if (page_directory[pd_index] = 0) then
            if (reserve_if_na = 1) then
                page_directory[pd_index] = cuint(pmm.alloc())
                pmm.memset(page_directory[pd_index], 0, 4096)
                page_directory[pd_index] or= (FLAG_PRESENT or FLAG_WRITE or FLAG_USERSPACE)
            else
                return 0
            end if
        end if
        
        page_table = cast(uinteger ptr, (page_directory[pd_index] and &hFFFFF000))
        
        if (page_table[pt_index] = 0) then
            if (reserve_if_na = 1) then
                page_table[pt_index] = cuint(pmm.alloc())
                pmm.memset(page_table[pt_index], 0, 4096)
                page_table[pt_index] or= (FLAG_PRESENT or FLAG_WRITE or FLAG_USERSPACE)
            else
                return 0
            end if
        end if
        
        return ((page_table[pt_index] and &hFFFFF000) or (v_addr and &hFFF))
    end function
    
    sub copy_to_context (page_directory as uinteger ptr, p_start as uinteger, v_dest as uinteger, size as uinteger)
        dim bytes_left as uinteger = size
        dim size_for_this_page as uinteger
        dim p_addr as uinteger = p_start
        dim p_v_addr as uinteger
        dim v_addr as uinteger = v_dest
        
        while (bytes_left > 0)
            p_v_addr = get_p_addr(page_directory, v_addr, 1)
            size_for_this_page = ((v_addr+4096) and &hFFF) - v_addr
            pmm.memcpy(p_v_addr, p_addr, size_for_this_page)
            bytes_left -= size_for_this_page
            p_addr += size_for_this_page
            v_addr += size_for_this_page
        wend
    end sub
    
    sub activate_directory (page_directory as uinteger ptr)
        asm
            mov eax, [page_directory]
            mov cr3, eax
        end asm
    end sub
    
    sub activate ()
        asm
            mov eax, cr0
            or eax, &h80000000
            mov cr0, eax
        end asm
    end sub
end namespace