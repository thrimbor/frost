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

#define spawned_block best_fit_block

const BLOCK_FRAME_SIZE = sizeof(kmm_block_header)+sizeof(kmm_block_content_area)+sizeof(kmm_block_footer)
const OVERHEAD_TO_SPLIT as uinteger = BLOCK_FRAME_SIZE + 4

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
            
            dim content_area as kmm_block_content_area ptr = cast(kmm_block_content_area ptr, (best_fit_block + 1))
            dim new_block_size as uinteger = overhead-BLOCK_FRAME_SIZE
            dim req_block_address as kmm_block_header ptr = cast(any ptr, content_area)+new_block_size+sizeof(kmm_block_footer)
            
            '' we create a new block at the address of the found one
            dim spawned_footer as kmm_block_footer ptr = cast(any ptr, best_fit_block)+sizeof(kmm_block_header)+new_block_size
            spawned_block->size = new_block_size
            spawned_footer->magic = FOOTER_MAGIC
            spawned_footer->header = spawned_block
            
            '' the new block is ready! now prepare the requested one
            req_block_address->magic = HEADER_MAGIC
            req_block_address->is_hole = false
            req_block_address->size = size
            
            dim req_footer as kmm_block_footer ptr = cast(any ptr, req_block_address)+size
            req_footer->header = req_block_address
            
            return content_area
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
    
    if (addr = 0) return;
    
    '' get header and footer of the block
    dim header as kmm_block_header ptr = addr-sizeof(kmm_block_header)
    dim footer as kmm_block_footer ptr = addr + header->size
    
    dim add_to_list as byte = true
    
    '' unify left
    dim test_footer as kmm_block_footer ptr = cast(any ptr, header)-sizeof(kmm_block_footer)
    if ((test_footer->magic = FOOTER_MAGIC) and (test_footer->header->is_hole = true)) then
        dim cached_size as uinteger = header->size
        header->magic = 0
        
        header = test_footer->header
        footer->header = header
        header->size += cached_size
        add_to_list = false
    end if
    
    '' unify right
    dim test_header as kmm_block_header ptr = cast(any ptr, footer)+sizeof(kmm_block_footer)
    if ((test_header->magic = HEADER_MAGIC) and (test_header->is_hole = true)) then
        '' this is a little more complicated, because we have to modify the list
    end if
    
end sub
