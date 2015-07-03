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

#include "string_tokenizer.bi"
#include "kmm.bi"
#include "mem.bi"
#include "zstring.bi"

constructor StringTokenizer (s as zstring ptr)
	this.original_string = kmalloc(zstring_len(*s)+1)
	memcpy(this.original_string, s, zstring_len(*s)+1)
	string_iterator = original_string
end constructor

destructor StringTokenizer ()
	if (original_string <> 0) then
		kfree(this.original_string)
	end if
end destructor

function StringTokenizer.getToken (delimiters as zstring ptr) as zstring ptr
	if string_iterator = 0 then return 0
	
	'' skip leading delimiters
	dim delim_it as ubyte ptr = delimiters
	while (*delim_it <> 0 and *string_iterator <> 0)
		if (*string_iterator = *delim_it) then
			string_iterator += 1
			delim_it = delimiters
		else
			delim_it += 1
		end if
	wend
	
	'' did we reach the end of the string already?
	if *string_iterator = 0 then return 0
	
	function = string_iterator
	
	'' scan for the next delimiter
	while (*string_iterator <> 0)
		delim_it = delimiters
		
		while (*delim_it <> 0)
			if (*string_iterator = *delim_it) then
				'' found delimiter, replace with zero
				*cast(byte ptr, string_iterator) = 0
				
				'' set starting point for next round
				string_iterator += 1
				
				'' done for now
				exit function
			end if
			
			delim_it += 1
		wend
		
		string_iterator += 1
	wend
	
	string_iterator = 0
end function
