/'
 ' FROST x86 microkernel
 ' Copyright (C) 2010-2017  Stefan Schmidt
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

#include "spinlock.bi"

type uid128
    #ifdef __FB_BIGENDIAN__
        h as uinteger<64>
        l as uinteger<64>
    #else
        l as uinteger<64>
        h as uinteger<64>
    #endif

    declare constructor (h as uinteger<64>, l as uinteger<64>)
    declare constructor (id as uid128)
    declare constructor ()
    declare sub inc ()
end type

type uid128_generator
    current_id as uid128
    id_lock as spinlock

    declare constructor ()
    declare constructor (id as uid128)
    declare function generate () as uid128
end type
