/'
 ' FROST x86 microkernel
 ' Copyright (C) 2010-2013  Stefan Schmidt
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

namespace video
    declare sub fout (fstr as zstring, ...)
    declare sub cout overload (number as uinteger, base as ubyte = 10, minchars as ubyte = 0)
    declare sub cout overload (number as integer, base as ubyte = 10, minchars as ubyte = 0)
    declare sub clean (b_color as ubyte = 0)
    declare sub set_color (fc as ubyte, bc as ubyte)
    declare sub hide_cursor ()
    declare sub show_cursor ()
    declare sub move_cursor (x as ubyte, y as ubyte)
end namespace
