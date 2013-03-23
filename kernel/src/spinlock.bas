#include "spinlock.bi"
#include "kernel.bi"

sub spinlock_acquire (slock as spinlock ptr)
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

function spinlock_trylock (slock as spinlock ptr) as boolean
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

sub spinlock_release (slock as spinlock ptr)
	*slock = 0
end sub

function spinlock_locked (slock as spinlock ptr) as boolean
	return (not (*slock = 0))
end function	
