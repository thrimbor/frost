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

#include "../../kernel/include/syscall_defs.bi"
'asm
'    .global fb_ctor__init
'end asm


sub handler (number as uinteger)
	dim y as ubyte ptr = strptr("IRQ catched  ")
	y[12] = number + &h30
	asm
		mov eax, 43
		mov ebx, [y]
		int &h62
		inb &h60
		
		mov eax, SYSCALL_IRQ_HANDLER_EXIT
		mov ebx, [number]
		int &h62
		
		jmp $
	end asm
end sub

sub main ()
	asm
		mov eax, SYSCALL_PORT_REQUEST
		mov ebx, &h60
		int &h62
	end asm

	dim z as any ptr = @handler
	asm
		mov eax, SYSCALL_IRQ_HANDLER_SET
		mov ebx, [z]
		int &h62
		
		mov eax, SYSCALL_IRQ_HANDLER_REGISTER
		mov ebx, 1
		int &h62
	end asm

	dim x as byte ptr = strptr("this is a test")
	asm
		mov eax, 43
		mov ebx, [x]
		int &h62
		jmp $
	end asm
end sub


#if 0
sub threadfunc ()
	dim y as byte ptr = strptr("thread hello")
	asm
		mov eax, 43
		mov ebx, [y]
		int &h62
		mov eax, SYSCALL_THREAD_EXIT
		int &h62
		jmp $ '' <- shouldn't be necessary, but the kernel doesn't reschedule atm
	end asm
end sub

sub main ()
	dim x as byte ptr = strptr("hello world")
	asm
		mov eax, 43
		mov ebx, [x]
		int &h62
		jmp $
	end asm
end sub
#endif
