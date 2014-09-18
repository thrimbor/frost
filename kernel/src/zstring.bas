/'
 ' FROST x86 microkernel
 ' Copyright (C) 2010-2014  Stefan Schmidt
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
#include "kernel.bi"

'' this function searches for the string-terminator (\0)
'' to find out the length of the string
function zstring_len (zstr as zstring) as uinteger
    dim counter as uinteger = 0
    while (zstr[counter] > 0)
        counter += 1
    wend
    return counter
end function

'' this is a simple function to find out if and where a string is containing another
function zstring_instr (zstr as zstring, substr as zstring) as uinteger
    dim is_substring as boolean
    dim len_zstr as uinteger = zstring_len(zstr)
    dim len_substr as uinteger = zstring_len(substr)
    
    if (len_zstr < len_substr) then return 0
    
    for counter as uinteger = 0 to len_zstr-len_substr
        is_substring = true
        for substring_length as uinteger = 0 to len_substr-1
            if (zstr[counter+substring_length] <> substr[substring_length]) then is_substring = false
        next
        if (is_substring) then return counter+1
    next
    
    return 0
end function

function zstring_cmp (zstr1 as zstring, zstr2 as zstring) as integer
	dim c as uinteger = 0
	while (zstr1[c] = zstr2[c])
		if (zstr1[c] = 0) then return 0
		c += 1
	wend
	
	return zstr1[c] - zstr2[c]
end function

function zstring_ncmp (zstr1 as zstring, zstr2 as zstring, n as uinteger) as integer
	dim c as uinteger = 0
	
	while (c<n)
		if (zstr1[c] <> zstr2[c]) then return (zstr1[c] - zstr2[c])
		if (zstr1[c] = 0) then exit while
		c += 1
	wend
	
	return 0
end function
