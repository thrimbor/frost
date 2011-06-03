#include once "inc/paging.bi"
#include once "inc/pmm.bi"

namespace paging
    dim shared kernel_context as uinteger ptr
    
    sub init
        kernel_context = pmm.alloc()
        pmm.clean(kernel_context)
        
        for counter as uinteger = 0 to 20*1024*1024 step 4096
            map_page(kernel_context, counter, counter, (FLAG_PRESENT or FLAG_WRITE))
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
            pmm.clean(cast(any ptr, page_directory[pd_index]))
            page_directory[pd_index] or= (FLAG_PRESENT or FLAG_WRITE)
        end if
        
        page_table = cast(uinteger ptr, (page_directory[pd_index] and &hFFFFF000))
        
        page_table[pt_index] = (physical or flags)
        
        asm
            invlpg [virtual]
        end asm
        
        return -1
    end function
    
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