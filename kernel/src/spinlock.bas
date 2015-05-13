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

#include "spinlock.bi"
#include "kernel.bi"

constructor spinlock ()
	this.lockvar = 0
end constructor

sub spinlock.acquire ()
	dim slock as integer ptr = @this.lockvar
	asm
		mov ecx, [slock]
        .acquire:
			lock bts dword ptr [ecx], 0
			jnc .acquired
		.retest:
			pause
			test dword ptr [ecx], 1
			je .retest
			
			lock bts dword ptr [ecx], 0
			jc .retest
		.acquired:
	end asm
end sub

function spinlock.trylock () as boolean
	dim slock as integer ptr = @this.lockvar
	asm
		mov ecx, [slock]
		lock bts dword ptr [ecx], 0
		jc .not_locked
		mov dword ptr [function], true
		jmp .fend
		.not_locked:
		mov dword ptr [function], false
		.fend:
	end asm
end function

sub spinlock.release ()
	this.lockvar = 0
end sub

function spinlock.locked () as boolean
	return (this.lockvar <> 0)
end function	
