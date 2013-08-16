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

#include "zstring.bi"

'' this function searches for the string-terminator (\0)
'' to find out the lenght of the string
function z_len (text as zstring) as uinteger
    dim text_ptr as ubyte ptr = @text
    dim counter as uinteger = 0
    while (text_ptr[counter] > 0)
        counter += 1
    wend
    return counter
end function

'' this is a simple function to find out if and where a string is containing another
function z_instr (text as zstring, pattern as zstring) as uinteger
    dim is_instr    as ubyte
    dim len_text    as uinteger = z_len(text)
    dim len_pattern as uinteger = z_len(pattern)
    dim text_ptr    as ubyte ptr = @text
    dim pattern_ptr as ubyte ptr = @pattern
    
    if (len_text < len_pattern) then return 0
    
    for i as uinteger = 0 to len_text-len_pattern
        is_instr = 1
        for x as uinteger = 0 to len_pattern-1
            if (text_ptr[i+x] <> pattern_ptr[x]) then is_instr = 0
        next
        if (is_instr=1) then return i+1
    next
end function
