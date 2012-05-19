#include once "kmm.bi"
#include once "kernel.bi"

dim shared kmm_first_block as any ptr
dim shared kmm_minimum_size as uinteger
dim shared kmm_maximum_size as uinteger
dim shared kmm_start_address as uinteger
dim shared kmm_end_address as uinteger

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

sub kmm_init (start_addr as uinteger, end_addr as uinteger, minimum as uinteger, maximum as uinteger)
    kmm_start_address = start_addr
    kmm_end_address = end_addr
    kmm_minimum_size = minimum
    kmm_maximum_size = maximum
    
    kmm_first_block = cast(any ptr, kmm_start_address)
    
    dim header as kmm_block_header ptr = kmm_first_block
    dim footer as kmm_block_footer ptr = cast(kmm_block_footer ptr, (kmm_end_address-sizeof(kmm_block_footer)))
    dim content_area as kmm_block_content_area ptr = cast(kmm_block_content_area ptr, header+1)
    header->magic = HEADER_MAGIC
    header->is_hole = true
    header->size = kmm_end_address - kmm_start_address - sizeof(kmm_block_header) - sizeof(kmm_block_footer)
    footer->magic = FOOTER_MAGIC
    footer->header = header
    content_area->prev_entry = 0
    content_area->next_entry = 0
end sub

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

function kmm_contract (new_size as uinteger) as uinteger
    /'
    '' get the nearest following page boundary
    if ((new_size+kmm_start_address) mod pmm.PAGE_SIZE) > 0 then
        new_size += pmm.PAGE_SIZE - ((new_size+kmm_start_address) mod pmm.PAGE_SIZE)
    end if
    
    '' don't shrink beyound our minimum size
    if (new_size < kmm_minimum_size) then new_size = kmm_minimum_size
    
    dim old_size as uinteger = kmm_end_address - kmm_start_address
    dim i as uinteger = old_size - pmm.PAGE_SIZE
    
    while (new_size < i)
        '' free the page at kmm_start_address + i
        i -= pmm.PAGE_SIZE
    wend
    
    kmm_end_address = kmm_start_address + new_size
    return new_size
    '/
    return kmm_end_address - kmm_start_address
end function

sub kfree (addr as any ptr)
    '' steps to take:
    '' - set block to hole
    '' - unify left
    '' - unify right
    '' - sort hole into the list
    '' - if we are freeing the last block of the heap, contract the size of the heap (we should not ALWAYS contract)
    
    if (addr = 0) then return
    
    '' get header and footer of the block
    dim header as kmm_block_header ptr = addr-sizeof(kmm_block_header)
    dim footer as kmm_block_footer ptr = addr + header->size
    dim add_to_list as byte = true
    
    '' set block to hole
    header->is_hole = true
    
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
        '' we have a free block to our right
        dim content_area as kmm_block_content_area ptr = cast(kmm_block_content_area ptr, (test_header + 1))
        dim prev_content_area as kmm_block_content_area ptr = cast(kmm_block_content_area ptr, (content_area->prev_entry + 1))
        dim next_content_area as kmm_block_content_area ptr = cast(kmm_block_content_area ptr, (content_area->next_entry + 1))
        
        '' remove the block from the list
        prev_content_area->next_entry = content_area->next_entry
        next_content_area->prev_entry = content_area->prev_entry
        
        '' the space increases
        header->size += test_header->size + sizeof(kmm_block_header) + sizeof(kmm_block_footer)
        
        '' modify our new footer to point to the header
        ''test_header->footer->header = header
        footer = cast(any ptr, test_header+1) + test_header->size
        footer->header = header
        
        '' we're done
    end if
    
    '' is the footer end equal to the end of the heap?
    if ((cuint(footer)+sizeof(kmm_block_footer)) = kmm_end_address) then
        dim old_length as uinteger = kmm_end_address - kmm_start_address
        dim new_length as uinteger = kmm_contract(cuint(header) - kmm_start_address)
        
        '' is this block still existing?
        if ((header->size - (old_length - new_length)) > 0) then
            header->size -= old_length - new_length
            footer = cast(kmm_block_footer ptr, (cuint(header+1) + header->size))
            footer->magic = FOOTER_MAGIC
            footer->header = header
        else
            '' block isn't existing any longer
            if (add_to_list = false) then
                '' block was already on list, so remove it
                dim content_area as kmm_block_content_area ptr = cast(kmm_block_content_area ptr, (test_header + 1))
                dim prev_content_area as kmm_block_content_area ptr = cast(kmm_block_content_area ptr, (content_area->prev_entry + 1))
                dim next_content_area as kmm_block_content_area ptr = cast(kmm_block_content_area ptr, (content_area->next_entry + 1))
                
                if (not(prev_content_area = 0)) then prev_content_area->next_entry = content_area->next_entry
                if (not(next_content_area = 0)) then next_content_area->prev_entry = content_area->prev_entry
            end if
            
            '' make sure the (non-existing) block isn't going to be added
            add_to_list = false
        end if
    end if
    
    if (add_to_list = true) then
        '' we just add the header to the beginning of the list
        dim first_block as kmm_block_header ptr = kmm_first_block
        dim first_blockcontent_area as kmm_block_content_area ptr = cast(kmm_block_content_area ptr, (first_block +1))
        dim content_area as kmm_block_content_area ptr = cast(kmm_block_content_area ptr, (header + 1))
        first_blockcontent_area->prev_entry = header
        content_area->prev_entry = 0
        content_area->next_entry = first_block
        kmm_first_block = cast(any ptr, header)
    end if
    
end sub
