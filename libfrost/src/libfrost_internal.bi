#pragma once

#macro syscall_param0(syscall_nr)
	asm
		mov eax, syscall_nr
		int &hFF
	end asm
#endmacro

#macro syscall_param1(syscall_nr, a)
	asm
		mov eax, syscall_nr
		mov ebx, [a]
		int &hFF
	end asm
#endmacro

#macro syscall_param2(syscall_nr, a, b)
	asm
		mov eax, syscall_nr
		mov ebx, [a]
		mov ecx, [b]
		int &hFF
	end asm
#endmacro

#macro syscall_param3(syscall_nr, a, b, c)
	asm
		mov eax, syscall_nr
		mov ebx, [a]
		mov ecx, [b]
		mov edx, [c]
		int &hFF
	end asm
#endmacro

#macro syscall_param0_ret(syscall_nr, ret)
	asm
		mov eax, syscall_nr
		int &hFF
		mov [ret], eax
	end asm
#endmacro

#macro syscall_param1_ret(syscall_nr, ret, a)
	asm
		mov eax, syscall_nr
		mov ebx, [a]
		int &hFF
		mov [ret], eax
	end asm
#endmacro

#macro syscall_param2_ret(syscall_nr, ret, a, b)
	asm
		mov eax, syscall_nr
		mov ebx, [a]
		mov ecx, [b]
		int &hFF
		mov [ret], eax
	end asm
#endmacro

#macro syscall_param3_ret(syscall_nr, ret, a, b, c)
	asm
		mov eax, syscall_nr
		mov ebx, [a]
		mov ecx, [b]
		mov edx, [c]
		int &hFF
		mov [ret], eax
	end asm
#endmacro
