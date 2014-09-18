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

#include "cpu.bi"
#include "kernel.bi"
#include "mem.bi"

sub cpu_get_vendor (zstr as zstring ptr)
	asm
		mov eax, 0
		cpuid
		mov eax, dword ptr [zstr]
        mov dword ptr [eax], ebx
		mov dword ptr [eax+4], edx
		mov dword ptr [eax+8], ecx
	end asm
end sub

function cpu_has_local_apic () as boolean
	dim t_edx as uinteger
	asm
		mov eax, 1
		cpuid
		mov dword ptr [t_edx], edx
	end asm
	
	return iif((t_edx and (1 shl 9)), true, false)
end function

function read_msr (msr as uinteger) as ulongint
	dim a as uinteger
	dim d as uinteger
	
	asm
		mov ecx, [msr]
		
		rdmsr
		
		mov [a], eax
		mov [d], edx
	end asm
	
	return (cast(ulongint, d) shl 32) or a
end function

sub write_msr (msr as uinteger, value as ulongint)
	dim a as uinteger = cuint(value)
	dim d as uinteger = cuint(value shr 32)
	
	asm
		mov ecx, [msr]
		mov eax, [a]
		mov edx, [d]
		
		wrmsr
	end asm
end sub
