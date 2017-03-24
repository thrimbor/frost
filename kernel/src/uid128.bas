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

#include "uid128.bi"

constructor uid128 (h as uinteger<64>, l as uinteger<64>)
    this.h = h
    this.l = l
end constructor

constructor uid128 (id as uid128)
    this.h = id.h
    this.l = id.l
end constructor

constructor uid128 ()
    this.l = 0
    this.h = 0
end constructor

sub uid128.inc ()
    dim r as uid128
    r.l = this.l+1
    r.h = this.h + iif(r.l < this.l, 1, 0)

    this.l = r.l
    this.h = r.h
end sub

constructor uid128_generator ()
    
end constructor

constructor uid128_generator (id as uid128)
    this.id_lock.acquire()
    this.current_id = id
    this.id_lock.release()
end constructor

function uid128_generator.generate () as uid128
    this.id_lock.acquire()
    function = this.current_id
    this.current_id.inc()
    this.id_lock.release()
end function
