#include once "kmm.bi"

sub memcpy (destination as any ptr, source as any ptr, size as uinteger)
    asm
        mov ecx, [size]
        mov edi, [destination]
        mov esi, [source]
        
        rep movsb
    end asm
end sub

sub memset (destination as any ptr, value as ubyte, size as uinteger)
    asm
        mov ecx, [size]
        mov edi, [destination]
        mov al, [value]
        
        rep stosb
    end asm
end sub

function kmalloc (size as uinteger) as any ptr
    
end function

sub kfree (addr as any ptr)
    
end sub
