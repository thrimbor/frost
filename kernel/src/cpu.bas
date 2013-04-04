#include "cpu.bi"
#include "kernel.bi"
#include "mem.bi"

function cpu.get_vendor () as zstring ptr
	static zstr as zstring * 13
	memset(@zstr, 0, 13)
	asm
		mov eax, 0
		cpuid
		mov dword ptr [zstr], ebx
		mov dword ptr [zstr+4], edx
		mov dword ptr [zstr+8], ecx
	end asm
	
	return @zstr
end function

function cpu.has_apic () as boolean
	dim t_edx as uinteger
	asm
		mov eax, 1
		cpuid
		mov dword ptr [t_edx], edx
	end asm
	
	return iif((t_edx and &h200), true, false)
end function
