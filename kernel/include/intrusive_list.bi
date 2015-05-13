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

#pragma once

type list_head
	private:
		next_ptr as list_head ptr
		prev_ptr as list_head ptr
    
    public:
		declare constructor ()
		declare destructor ()
		declare sub insert_after (new_head as list_head ptr)
		declare sub insert_before (new_head as list_head ptr)
		declare sub remove ()
		declare function is_empty () as integer
		declare function is_singular () as integer
		declare function get_next () as list_head ptr
		declare function get_prev () as list_head ptr
end type

#define LIST_GET_ENTRY(HEAD_, TYPE_, L) cast(TYPE_ ptr, cast(any ptr, HEAD_)-offsetof(TYPE_, L))

#macro list_foreach (ITERATOR_, LIST_)
	scope
		dim ITERATOR_ as list_head ptr = LIST_.get_next()
		while (ITERATOR_ <> @LIST_)
#endmacro

#define list_foreach_exit exit while

#macro list_next (ITERATOR_)
			ITERATOR_ = ITERATOR_->get_next()
		wend
	end scope
#endmacro 
