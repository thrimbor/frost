#include once "kmm.bi"
#include once "kernel.bi"
#include once "video.bi"

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
'' - splitting blocks

#define spawned_block best_fit_block

const OVERHEAD_TO_SPLIT as uinteger = sizeof(kmm_header) + sizeof(kmm_footer) + 4

sub kmm_init (start_addr as uinteger, end_addr as uinteger, minimum as uinteger, maximum as uinteger)
    kmm_start_address = start_addr
    kmm_end_address = end_addr
    kmm_minimum_size = minimum
    kmm_maximum_size = maximum
    
    kmm_first_block = cast(any ptr, kmm_start_address)
    
    video.fout("heap start: %hI, end: %hI, min: %hI, max: %hI\n", kmm_start_address, kmm_end_address, kmm_minimum_size, kmm_maximum_size)
    video.fout("first block: %hI\n", cuint(kmm_first_block))
    
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
    '' connect their pointers
    if (next_entry <> 0) then next_entry->prev_entry = prev_entry
    if (prev_entry <> 0) then prev_entry->next_entry = next_entry
    '' hole is now removed from list
end sub

sub insert_hole (hole as kmm_header ptr)
    dim content as kmm_content ptr = cast(kmm_content ptr, hole+1)
    content->next_entry = kmm_first_block
    content->prev_entry = 0
    kmm_first_block = hole
end sub

function kmalloc (size as uinteger) as any ptr
    '' take size of header and footer into account
    dim real_size as uinteger = size + sizeof(kmm_header) + sizeof(kmm_footer)
    '' find the smallest fitting hole
    dim hole as kmm_header ptr = find_hole(new_size)
    
    if (hole = 0) then
        '' error handling code...
        '' I think we should expand the heap here
        return 0
    end if
    
    '' to split or not to split, that is the question...
    if ((hole->size - new_size) < OVERHEAD_TO_SPLIT) then
        '' don't split, increase requested size to fit
        new_size = hole->size
        '' remove hole from list
        remove_hole(hole)
    else
        '' yes, we split
        '' create a new hole reusing the list-place of the old one
        dim new_hole as kmm_header ptr = hole
        new_hole->size = (hole->size - new_size)
        '' we also need to built a new footer
        dim new_footer as kmm_footer ptr = cast(kmm_footer ptr, cuint(new_hole)+new_hole->size-sizeof(kmm_footer))
        new_footer->magic = FOOTER_MAGIC
        new_footer->header = kmm_header
        '' now fix the old hole
        hole = cast(kmm_header ptr, cuint(new_hole) + new_hole->size))
        hole->magic = HEADER_MAGIC
        hole->is_hole = false
        hole->size = new_size
        '' of course this hole also needs a fixed footer
        new_footer = cast(kmm_footer ptr, cuint(hole) + hole->size - sizeof(kmm_footer))
        '' magic number should still fit, so we just set the header pointer
        new_footer->header = hole
    end if
    
    '' and we're done!
    return cast(any ptr, cuint(hole)+sizeof(kmm_header))
end function

sub kfree (addr as any ptr)
    '' no null-pointers here ;)
    if (addr = 0) then return
    
    dim header as kmm_header ptr = addr - sizeof(kmm_header)
    dim footer as kmm_footer ptr = addr + header->size
    
    '' well, we _could_ check the magic fields here ;)
    
    '' the block is now a hole again
    header->is_hole = true
    
    '' we want to add the header to the free holes
    dim do_add as byte = true
    
    '' unify left
    dim test_footer as kmm_footer ptr = cast(kmm_footer ptr, cuint(header)-sizeof(kmm_footer))
    if ((test_footer->magic = FOOTER_MAGIC) and (test_footer->header->is_hole = 1)) then
        dim cached_size as uinteger = header->size
        header = test_footer->header
        footer->header = header
        header->size += cached_size
        do_add = false
    end if
    
    '' unify right
    dim test_header as kmm_header ptr = cast(kmm_header ptr, cuint(footer)+sizeof(kmm_footer))
    if ((test_header->magic = HEADER_MAGIC) and (test_header->is_hole)) then
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
