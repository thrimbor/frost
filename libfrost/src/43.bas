
sub frost_syscall_43 (str_ptr as byte ptr)
	asm
		mov eax, 43
		mov ebx, [str_ptr]
		int &hFF
	end asm
end sub
