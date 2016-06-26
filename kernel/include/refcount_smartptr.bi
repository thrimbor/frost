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

#include "atomic.bi"

type RefCounted
    dim refcount as AtomicInt
end type


#define RefCountPtr(T_) RefCountPtr_##T_

#macro DECLARE_REFCOUNTPTR(T_)
    type RefCountPtr(T_)
        ref as T_ ptr
        
        declare constructor ()

        '' construct from raw pointer
        declare constructor (reference as T_ ptr)

        '' copy-constructor
        declare constructor (reference as RefCountPtr(T_))

        '' clean-up destructor
        declare destructor ()
        
        declare operator let (byref rhs as RefCountPtr(T_))

        declare function get_count () as integer
    end type
#endmacro

#macro DEFINE_REFCOUNTPTR(T_)
	operator -> (byref tt_ as RefCountPtr(T_)) byref as T_
		assert(tt_.ref <> 0)
		return *tt_.ref
	end operator
	
	operator = (byref tt_ as RefCountPtr(T_), byref tt2_ as RefCountPtr(T_)) as integer
		if (tt_.ref = tt2_.ref) then return -1
		return 0
	end operator

	constructor RefCountPtr(T_) ()
        this.ref = 0
    end constructor
	
    constructor RefCountPtr(T_) (reference as T_ ptr)
		assert(reference <> 0)
        reference->refcount.inc()
        this.ref = reference
    end constructor

    constructor RefCountPtr(T_) (reference as RefCountPtr(T_))
		assert(reference.ref <> 0)
        reference.ref->refcount.inc()
        this.ref = reference.ref
    end constructor

    destructor RefCountPtr(T_) ()
		dim destroy as boolean = this.ref->refcount.sub_and_test(1)
        
        if (destroy) then
            delete this.ref
        end if
    end destructor
    
    operator RefCountPtr(T_).let (byref rhs as RefCountPtr(T_))
		if (this.ref <> 0) then
			dim destroy as boolean = this.ref->refcount.sub_and_test(1)
			
			if (destroy) then
				delete this.ref
			end if
		end if
		
		rhs.ref->refcount.inc()
		this.ref = rhs.ref
	end operator


    function RefCountPtr(T_).get_count () as integer
        return this.ref->refcount.get()
    end function
#endmacro
