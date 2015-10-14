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

#include "atomic.bi"

type RefCounted
    dim refcount as AtomicInt

    declare sub ref ()
    declare sub deref ()
end type


#define RefCountPtr(T_) RefCountPtr_##T_

#macro DECLARE_REFCOUNTPTR(T_)
    type RefCountPtr(T_)
        ref as T_ ptr

        '' construct from raw pointer
        declare constructor (reference as T_ ptr)

        '' copy-constructor
        declare constructor (reference as RefCountPtr(T_))

        '' clean-up destructor
        declare destructor ()

        declare function get_count () as integer
    end type
#endmacro

#macro DEFINE_REFCOUNTPTR(T_)
    constructor RefCountPtr(T_) (reference as T_ ptr)
        reference->ref()
        this.ref = reference
    end constructor

    constructor RefCountPtr(T_) (reference as RefCountPtr(T_))
        reference.ref->ref()
        this.ref = reference.ref
    end constructor

    destructor RefCountPtr(T_) ()
        this.ref->deref()

        if (this.ref->refcount.get() = 0) then
            delete this.ref
        end if
    end destructor

    function RefCountPtr(T_).get_count () as integer
        return this.ref->refcount.get()
    end function
#endmacro
