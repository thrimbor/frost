/'
 ' FROST x86 microkernel
 ' Copyright (C) 2010-2016  Stefan Schmidt
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

#define Listtype(T_) Listtype_##T_

#macro DECLARE_LIST(T_)
	'' IMPORTANT: RefCountPtr needs to be declared BEFORE declaring the list!
	#if defined(RefCountPtr_##T_)
		'' this type seems to be refcounted!
		type Listtype_p_##T_ as RefCountPtr(T_)
		#define Listtype_r_##t_
	#else
		'' not refcounted, use normal pointer
		type Listtype_p_##T_ as T_ ptr
	#endif
	

	type Listtype_t_##T_ as T_

    type Listtype(T_)
		private:
			next_ptr as Listtype(T_) ptr
			prev_ptr as Listtype(T_) ptr
			owner as Listtype_p_##T_
		public:
			declare constructor (offset as uinteger)
			declare constructor ()
			declare destructor ()
			declare sub insert_after (new_head as Listtype(T_) ptr)
			declare sub insert_before (new_head as Listtype(T_) ptr)
			declare sub remove ()
			declare function is_empty () as integer
			declare function is_singular () as integer
			declare function get_next () as Listtype(T_) ptr
			declare function get_prev () as Listtype(T_) ptr
			declare function get_owner () as Listtype_p_##T_
    end type
#endmacro

#macro DEFINE_LIST(T_)
    constructor Listtype(T_) (offset as uinteger)
		assert(offset <> 0)
		
		this.next_ptr = @this
		this.prev_ptr = @this
		#if defined(Listtype_r_##t_)
			this.owner = Listtype_p_##T_(cast(T_ ptr, cast(any ptr, @this)-offset))
		#else
			this.owner = cast(Listtype_p_##T_, cast(any ptr, @this)-offset)
		#endif
	end constructor
	
	constructor Listtype(T_) ()
		this.next_ptr = @this
		this.prev_ptr = @this
		#if not defined(Listtype_r_##t_)
			this.owner = 0
		#endif
	end constructor

	destructor Listtype(T_)
		this.remove()
	end destructor

	sub Listtype(T_).insert_after (new_head as Listtype(T_) ptr)
		new_head->next_ptr = this.next_ptr
		new_head->prev_ptr = @this
		
		this.next_ptr->prev_ptr = new_head
		this.next_ptr = new_head
	end sub

	sub Listtype(T_).insert_before (new_head as Listtype(T_) ptr)
		new_head->prev_ptr = this.prev_ptr
		new_head->next_ptr = @this
		
		this.prev_ptr->next_ptr = new_head
		this.prev_ptr = new_head
	end sub

	sub Listtype(T_).remove ()
		this.prev_ptr->next_ptr = this.next_ptr
		this.next_ptr->prev_ptr = this.prev_ptr
	end sub

	function Listtype(T_).is_empty () as integer
		return (this.next_ptr = @this)
	end function

	function Listtype(T_).is_singular () as integer
		if (not this.is_empty()) then
			return (this.next_ptr = this.prev_ptr)
		end if
		
		return 0
	end function

	function Listtype(T_).get_next () as Listtype(T_) ptr
		return this.next_ptr
	end function

	function Listtype(T_).get_prev () as Listtype(T_) ptr
		return this.prev_ptr
	end function
	
	function Listtype(T_).get_owner () as Listtype_p_##T_
		return this.owner
	end function
#endmacro


#macro list_foreach (ITERATOR_, LIST_)
	scope
		dim ITERATOR_ as typeof(LIST_) ptr = LIST_.get_next()
		while (ITERATOR_ <> @LIST_)
			
#endmacro

#define list_foreach_exit exit while

#macro list_next (ITERATOR_)
			ITERATOR_ = ITERATOR_->get_next()
		wend
	end scope
#endmacro
