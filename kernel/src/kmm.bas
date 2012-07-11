#include "kmm.bi"
#include "kernel.bi"
#include "video.bi"

dim shared kmm_first_block as any ptr
dim shared kmm_minimum_size as uinteger
dim shared kmm_maximum_size as uinteger
dim shared kmm_start_address as uinteger
dim shared kmm_end_address as uinteger

'' the following issues are left:
'' - the function does not check for errors (checksum, is_hole not true...) -> isn't needed, list is guaranteed to be correct

'' todo:
'' - heap initialization
'' - heap expansion

const OVERHEAD_TO_SPLIT as uinteger = sizeof(kmm_header) + sizeof(kmm_footer) + 4

sub kmm_init (start_addr as uinteger, end_addr as uinteger, minimum as uinteger, maximum as uinteger)
    kmm_start_address = start_addr
    kmm_end_address = end_addr
    kmm_minimum_size = minimum
    kmm_maximum_size = maximum
    
    kmm_first_block = cast(any ptr, kmm_start_address)
    
    video.fout("heap start: %hI, end: %hI, min: %hI, max: %hI\n", kmm_start_address, kmm_end_address, kmm_minimum_size, kmm_maximum_size)
    video.fout("first block: %hI\n", cuint(kmm_first_block))
    
    dim header as kmm_header ptr = kmm_first_block
    dim footer as kmm_footer ptr = cast(kmm_footer ptr, (kmm_end_address-sizeof(kmm_footer)))
    dim content_area as kmm_content ptr = cast(kmm_content ptr, header+1)
    header->magic = HEAP_MAGIC
    header->is_hole = 1
    header->size = kmm_end_address - kmm_start_address - sizeof(kmm_header) - sizeof(kmm_footer)
    footer->magic = HEAP_MAGIC
    footer->header = header
    content_area->prev_entry = 0
    content_area->next_entry = 0
end sub


'' if the list would be ordered, the runtime could be reduced _heavily_
function find_hole (size as uinteger) as kmm_header ptr
    dim current_block       as kmm_header ptr = kmm_first_block
    dim best_block_till_now as kmm_header ptr = 0
    
    '' loop through the list of blocks
    do until (current_block = 0)
        if (current_block->size = size) then
            '' best block possible, so return it
            return current_block
        elseif (current_block->size > size) then
            if (best_block_till_now = 0) then
                '' no block memorized yet so memorize this one
                best_block_till_now = current_block
            else
                if (current_block->size < best_block_till_now->size) then
                    '' block is better than the block memorized
                    best_block_till_now = current_block
                end if
            end if
        end if
        
        '' go to the next block
        current_block = cast(kmm_content ptr, current_block+1)->next_entry
    loop
    
    '' we could reach this code for two reasons:
    '' Either the code hasn't found a suitable block
    '' or we have a block, but not a perfect one.
    '' We don't need to take care for this as the function calling this one will check the return value.
    return best_block_till_now
end function

sub remove_hole (hole as kmm_header ptr)
    '' get the next and previous elements from the list
    dim prev_entry as kmm_header ptr = cast(kmm_content ptr, hole+1)->prev_entry
    dim next_entry as kmm_header ptr = cast(kmm_content ptr, hole+1)->next_entry
    '' check the previous one
    if (prev_entry <> 0) then
        '' get content area
        dim prev_content as kmm_content ptr = cast(kmm_content ptr, prev_entry+1)
        '' set pointer
        prev_content->next_entry = next_entry
    else
        kmm_first_block = next_entry
    end if
    '' check the next one
    if (next_entry <> 0) then
        '' get content area
        dim next_content as kmm_content ptr = cast(kmm_content ptr, next_entry+1)
        '' set pointer
        next_content->prev_entry = prev_entry
    end if
    '' hole is now removed from list
end sub

sub insert_hole (hole as kmm_header ptr)
    '' adjust the first block in the list
    'video.fout("1\n")
    dim first_block_content as kmm_content ptr = cast(kmm_content ptr, cast(kmm_header ptr, kmm_first_block)+1)
    'video.fout("2\n")
    first_block_content->prev_entry = hole
    'video.fout("3\n")
    '' attach the new hole to the beginning of the list
    dim content as kmm_content ptr = cast(kmm_content ptr, hole+1)
    'video.fout("4\n")
    content->next_entry = kmm_first_block
    'video.fout("5\n")
    content->prev_entry = 0
    'video.fout("6\n")
    kmm_first_block = hole
    'video.fout("7\n")
end sub

sub split_hole (hole as kmm_header ptr, size as uinteger)
    '' save the old size of the hole
    dim old_size as uinteger = hole->size
    '' set the new size
    hole->size = size
    '' create a footer at the end of the hole
    dim footer as kmm_footer ptr = cast(kmm_footer ptr, cuint(hole)+size-sizeof(kmm_footer))
    footer->magic = HEAP_MAGIC
    footer->header = hole
    
    '' create a new hole
    dim new_hole as kmm_header ptr = cast(kmm_header ptr, footer+1)
    new_hole->magic = HEAP_MAGIC
    new_hole->is_hole = 1
    new_hole->size = old_size-size
    
    '' create a footer for our new hole
    dim new_footer as kmm_footer ptr = cast(kmm_footer ptr, cuint(new_hole)+new_hole->size-sizeof(kmm_footer))
    new_footer->magic = HEAP_MAGIC
    new_footer->header = new_hole
    
    '' at last, we have to add our new hole to the list
    insert_hole(new_hole)
end sub

function kmalloc (size as uinteger) as any ptr
    '' take size of header and footer into account
    dim new_size as uinteger = size + sizeof(kmm_header) + sizeof(kmm_footer)
    '' find the smallest fitting hole
    dim hole as kmm_header ptr = find_hole(new_size)
    
    if (hole = 0) then
        '' error handling code...
        '' I think we should expand the heap here
        return 0
    end if
    
    '' was the hole perfect or not?
    if (hole->size <> new_size) then
        '' to split or not to split, that is the question...
        if ((hole->size - new_size) < OVERHEAD_TO_SPLIT) then
            '' don't split, increase requested size to fit
            new_size = hole->size
        else
            split_hole(hole, new_size)
        end if
    end if
    
    '' remove hole from list
    remove_hole(hole)
    
    '' hole is now a block
    hole->is_hole = 0
    
    '' and we're done!
    return cast(any ptr, cuint(hole)+sizeof(kmm_header))
end function

sub kfree (addr as any ptr)
    '' no null-pointers here ;)
    if (addr = 0) then return
    
    dim header as kmm_header ptr = addr - sizeof(kmm_header)
    '' only free if it's occupied
    if (header->is_hole = 1) then return
    dim footer as kmm_footer ptr = cast(kmm_footer ptr, cuint(header) + header->size - sizeof(kmm_footer))
    
    '' well, we _could_ check the magic fields here ;)
    
    '' the block is now a hole again
    header->is_hole = 1
    
    '' we want to add the header to the free holes
    dim do_add as byte = true
    
    '' unify left
    dim test_footer as kmm_footer ptr = cast(kmm_footer ptr, cuint(header)-sizeof(kmm_footer))
    if ((test_footer->magic = HEAP_MAGIC) and (test_footer->header->is_hole = 1)) then
        dim cached_size as uinteger = header->size
        header = test_footer->header
        footer->header = header
        header->size += cached_size
        do_add = false
    end if
    
    '' unify right
    dim test_header as kmm_header ptr = cast(kmm_header ptr, cuint(footer)+sizeof(kmm_footer))
    if ((test_header->magic = HEAP_MAGIC) and (test_header->is_hole = 1)) then
        '' increase the size of our hole
        header->size += test_header->size
        '' find the header of the following hole
        test_footer = cast(kmm_footer ptr, cuint(test_header)+test_header->size-sizeof(kmm_footer))
        '' this footer is now ours
        footer = test_footer
        '' let our new footer point to our header
        footer->header = header
        '' remove the header of the absorbed hole from the list
        remove_hole(test_header)
    end if
    
    '' we should check for the possibility to contract here
    
    if (do_add) then
        insert_hole(header)
    end if
end sub
