#include once "kmm.bi"

dim shared kmm_first_block as any ptr

sub memcpy (destination as any ptr, source as any ptr, size as uinteger)
    asm
        mov ecx, [size]
        mov edi, [destination]
        mov esi, [source]
        
        rep movsb
    end asm
end sub

sub memset (destination as any ptr, value as ubyte, size as uinteger)
    asm
        mov ecx, [size]
        mov edi, [destination]
        mov al, [value]
        
        rep stosb
    end asm
end sub

'' the following issues are left:
'' - the function does not check for errors (checksum, is_hole not true...)
'' - the function does not stop at the end of the list (next_entry = 0)

function kmalloc (size as uinteger) as any ptr
    dim current_block as kmm_block_header ptr = kmm_first_block
    dim best_fit_block as kmm_block_header ptr
    dim difference as integer
    dim last_difference as integer
    
    if (current_block = 0) then return 0
    
    '' loop through the list and find the best free block
    while
        if (current_block->size = size) then
            '' we found a perfect block
            best_fit_block = current_block
            exit while
        end if
        
        difference = current_block->size - size
        if (difference < 0) then difference = 0 - difference
        
        if (difference < last_difference) then
            last_difference = difference
            best_fit_block = current_block
        end if
        
        current_block = cast(kmm_free_block_list ptr, current_block+1)->next_entry
    wend
    
    '' if we arrive here, we found a good block
end function

sub kfree (addr as any ptr)
    
end sub
