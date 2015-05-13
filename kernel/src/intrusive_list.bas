/'
 ' FROST x86 microkernel
 ' Copyright (C) 2010-2015  Stefan Schmidt
 ' 
 ' This program is free software: you can redistribute it and/or modify
 ' it under the terms of the GNU General Public License as published by
 ' the Free Software Foundation, either version 3 of the License, or
 ' (at your option) any later version.
 ' 
 ' This program is distributed in the hope that it will be useful,
 ' but WITHOUT ANY WARRANTY; without even the implied warranty of
 ' MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 ' GNU General Public License for more details.
 ' 
 ' You should have received a copy of the GNU General Public License
 ' along with this program.  If not, see <http://www.gnu.org/licenses/>.
 '/ 

#include "intrusive_list.bi"

constructor list_head
	this.next_ptr = @this
	this.prev_ptr = @this
end constructor

destructor list_head
    this.remove()
end destructor

sub list_head.insert_after (new_head as list_head ptr)
    new_head->next_ptr = this.next_ptr
    new_head->prev_ptr = @this
    
    this.next_ptr->prev_ptr = new_head
    this.next_ptr = new_head
end sub

sub list_head.insert_before (new_head as list_head ptr)
    new_head->prev_ptr = this.prev_ptr
    new_head->next_ptr = @this
    
    this.prev_ptr->next_ptr = new_head
    this.prev_ptr = new_head
end sub

sub list_head.remove ()
    this.prev_ptr->next_ptr = this.next_ptr
    this.next_ptr->prev_ptr = this.prev_ptr
end sub

function list_head.is_empty () as integer
    return (this.next_ptr = @this)
end function

function list_head.is_singular () as integer
    if (not this.is_empty()) then
        return (this.next_ptr = this.prev_ptr)
    end if
    
    return 0
end function

function list_head.get_next () as list_head ptr
	return this.next_ptr
end function

function list_head.get_prev () as list_head ptr
	return this.prev_ptr
end function 
