#include once "kmm.bi"
#include once "kernel.bi"

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
'' - the function does not check for errors (checksum, is_hole not true...) -> isn't needed, list is guaranteed to be correct

'' todo:
'' - heap initialization
'' - heap expansion
'' - splitting blocks

const OVERHEAD_TO_SPLIT as uinteger = sizeof(kmm_block_header)+sizeof(kmm_block_content_area)+sizeof(kmm_block_footer)+4

function kmalloc (size as uinteger) as any ptr
    dim current_block as kmm_block_header ptr = kmm_first_block
    dim best_fit_block as kmm_block_header ptr
    dim is_block_perfect as byte = 0
    dim overhead as uinteger
    dim last_overhead as uinteger
    
    '' loop through the list and find the best free block
    do until (current_block = 0)
        if (current_block->size = size) then                 '' is the size exactly right? We found a perfect block!
            best_fit_block = current_block                   '' remember the block
            is_block_perfect = -1                            '' block is perfect, so we set the flag
            exit do                                          '' we have a perfect block, so we stop searching
        end if
        
        if (size < current_block->size) then                 '' is the block bigger than requested?
            overhead = current_block->size - size            '' calculate the blocks overhead
            
            if (overhead < last_overhead) then               '' do we have less overhead than the last time?
                last_overhead = overhead                     '' save the current overhead
                best_fit_block = current_block               '' remember the block
            end if
        end if
        
        '' get the next block in the list
        current_block = cast(kmm_block_content_area ptr, current_block+1)->next_entry
    loop
    
    if (best_fit_block = 0) then return 0                    '' we could not find a suitable block
    
    '' if we arrive here, we found a good block
    if (is_block_perfect = 0) then                           '' is the block not perfect?
        overhead = best_fit_block->size - size               '' calculate the overhead
        
        if (overhead >= OVERHEAD_TO_SPLIT) then              '' is the block big enough to be split?
            '' block is going to be split
            
        end if
        
        '' if it's not beneficial to split the block, we just reserve the whole block
    end if
    
    '' get access to the list-links
    dim content_area as kmm_block_content_area ptr = cast(kmm_block_content_area ptr, (best_fit_block + 1))
    dim prev_content_area as kmm_block_content_area ptr = cast(kmm_block_content_area ptr, (content_area->prev_entry + 1))
    dim next_content_area as kmm_block_content_area ptr = cast(kmm_block_content_area ptr, (content_area->next_entry + 1))
    
    if (not(prev_content_area = 0)) then
        prev_content_area->next_entry = content_area->next_entry
    end if
    
    if (not(next_content_area = 0)) then
        next_content_area->prev_entry = content_area->prev_entry
    end if
    
    '' block is now removed from list
    best_fit_block->is_hole = false
    
    '' return pointer to the content-area of the block
    return content_area
end function

sub kfree (addr as any ptr)
    '' steps to take:
    '' - set block to hole
    '' - unify left
    '' - unify right
    '' - sort hole into the list
    '' - if we are freeing the last block of the heap, contract the size of the heap (we should not ALWAYS contract)
end sub
