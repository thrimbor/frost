/'
 ' FROST
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

#include "../libfrost/frost.bi"
'asm
'    .global fb_ctor__init
'end asm


sub main ()
	frost_syscall_43(strptr("this is a test"))
	
	do
		frost_syscall_thread_yield()
	loop
end sub
