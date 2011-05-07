'// this code is a bit strange, but it's the only comfortable way to use in/out in FreeBASIC without the rtlib (which can't be used in a kernel)

sub _fb_Out cdecl alias "fb_Out" (port as ushort, value as ubyte)
    asm
        movw dx, [port]
        movb al, [value]
        outb dx, al
    end asm
end sub

function _fb_In cdecl alias "fb_In" (port as ushort) as ubyte
    asm
        movw dx, [port]
        inb al, dx
        mov [function], al
    end asm
end function
