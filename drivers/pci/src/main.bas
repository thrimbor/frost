#include "../../../kernel/include/syscall_defs.bi"
#include "../../libfrost/frost.bi"

const CONFIG_ADDRESS = &hCF8
const CONFIG_DATA = &hCFC

asm
    .global fb_ctor__main
end asm

'' request access to the textbuffer
'dim buffer as byte ptr
'
'asm
'	mov eax, syscalls.SYSCALL_MEMORY_ALLOCATE_PHYSICAL
'	mov ebx, 4096
'	mov ecx, &hb8000
'	int &h62
'	mov [buffer], eax
'end asm

declare sub printd (format_string as const zstring, ...)

sub outl (port as ushort, value as integer)
    asm
        movw dx, [port]
        mov eax, [value]
        outd dx, eax
    end asm
end sub

function inl (port as ushort) as integer
    asm
        movw dx, [port]
        ind eax, dx
        mov [function], eax
    end asm
end function

function PciRead (bus as integer, dev as integer, func as integer, offset as integer) as integer
	dim addr as integer = &h80000000 or (bus shl 16) or (dev shl 11) or (func shl 8) or (offset and &hFC)
	outl(CONFIG_ADDRESS, addr)
	return inl(CONFIG_DATA)
end function

sub PciWrite (bus as integer, dev as integer, func as integer, offset as integer, value as integer)
	dim addr as integer = &h80000000 or (bus shl 16) or (dev shl 11) or (func shl 8) or (offset and &hFC)
	outl(CONFIG_ADDRESS, addr)
	outl(CONFIG_DATA, value)
end sub

function PciIsDevicePresent (bus as integer, dev as integer) as boolean
	dim value as integer = PciRead(bus, dev, 0, 0)
	dim vendor as integer = value and &hFFFF
	dim device as integer = (value shr 16) and &hFFFF
	
	if vendor <> &hFFFF then
		printd(!"%X:%X\n", vendor, device)
		return true
	end if
	
	return false
end function

printd(!"Requesting PCI port access...\n")
frost_syscall_port_request(CONFIG_ADDRESS)
frost_syscall_port_request(CONFIG_ADDRESS+1)
frost_syscall_port_request(CONFIG_ADDRESS+2)
frost_syscall_port_request(CONFIG_ADDRESS+3)
frost_syscall_port_request(CONFIG_DATA)
frost_syscall_port_request(CONFIG_DATA+1)
frost_syscall_port_request(CONFIG_DATA+2)
frost_syscall_port_request(CONFIG_DATA+3)

printd(!"Done.\n")

for x as integer = 0 to 32
	PciIsDevicePresent(0, x)
next

while true
	'frost_syscall_thread_yield()
wend

asm jmp $


declare sub put_uint (number as uinteger, numerical_base as const ubyte = 10, minchars as const ubyte = 1, fillchar as ubyte = 32, lowercase as const boolean = false)
declare sub put_int (number as integer, numerical_base as const ubyte = 10, minchars as const ubyte = 1, fillchar as const ubyte = 32)

'' print one char
sub putc (char as ubyte)
	dim chars (0 to 1) as ubyte
	chars(1) = 0
	chars(0) = char
	
	frost_syscall_43(@chars(0))
end sub

sub printd (format_string as const zstring, ...)
    dim fstr as const ubyte ptr = cast(const ubyte ptr, @format_string)
    dim arg as any ptr = va_first()
    dim c as uinteger = 0
    dim is_format as boolean = false
    var format_minchars = 1
    var format_fillchar = asc(" ")

    while (fstr[c] <> 0)
        if (is_format) then
            select case fstr[c]
                case asc("%")
                    putc(fstr[c])
                    is_format = false
                case asc("d"), asc("i")
                    put_int(va_arg(arg, integer), 10, format_minchars, format_fillchar)
                    arg = va_next(arg, integer)
                    is_format = false
                case asc("u")
                    put_uint(va_arg(arg, uinteger), 10, format_minchars, format_fillchar)
                    arg = va_next(arg, uinteger)
                    is_format = false
                case asc("x")
                    put_uint(va_arg(arg, uinteger), 16, format_minchars, format_fillchar, true)
                    arg = va_next(arg, uinteger)
                    is_format = false
                case asc("X")
                    put_uint(va_arg(arg, uinteger), 16, format_minchars, format_fillchar)
                    arg = va_next(arg, uinteger)
                    is_format = false
                case asc("c")
					putc(va_arg(arg, byte))
					arg = va_next(arg, byte)
					is_format = false
                case asc("s")
                    dim s_it as uinteger = 0
                    dim s_str as byte ptr = va_arg(arg, byte ptr)
                    arg = va_next(arg, byte ptr)

                    while (s_str[s_it] <> 0)
                        putc(s_str[s_it])
                        s_it += 1
                    wend
                    
                    is_format = false
				case asc("0") to asc("9")
					if (fstr[c] = asc("0") and (fstr[c-1] = asc("%"))) then
						format_fillchar = asc("0")
					else
						format_minchars = format_minchars*10 + (fstr[c] - asc("0"))
					end if
            end select
        else
            select case fstr[c]
                case asc("%")
                    is_format = true
                    format_minchars = 1
                    format_fillchar = asc(" ")
                case else
                    putc(fstr[c])
            end select
        end if

        c += 1
    wend
end sub

'' print an uinteger with a given base and at least as many digits as given in minchars
sub put_uint (number as uinteger, numerical_base as const ubyte = 10, minchars as const ubyte = 1, fillchar as ubyte = 32, lowercase as const boolean = false)
	if ((numerical_base > 36) or (numerical_base < 2)) then return
	if (minchars = 1) then fillchar = asc("0")
	dim chars(1 to 10) as ubyte
	dim num as ubyte
	dim counter as uinteger = 10
	dim rem_chars as integer = minchars

	do
		chars(counter) = 48+(number mod numerical_base)
		if (chars(counter)>57) then chars(counter) += 7
		counter -= 1
		number \= numerical_base
		rem_chars -= 1
	loop until ((number <= 0) and (rem_chars <= 0))

	for counter = 1 to 10
		if ((chars(counter)=0) and (num = 0)) then continue for
		if ((chars(counter)=asc("0")) and (num=0)) then
			putc(fillchar)
		else
			if (lowercase) and cast(boolean, (chars(counter) > 64)) then chars(counter) += 32
			putc(chars(counter))
			num = 1
		end if
	next
end sub

'' same game with integers. if the number is negative we just print a minus and then the number.
sub put_int (number as integer, numerical_base as const ubyte = 10, minchars as const ubyte = 1, fillchar as const ubyte = 32)
	if ((numerical_base > 36) or (numerical_base < 2)) then return
	if (number<0) then
		putc(45)
		number = -number
	end if
	put_uint(cuint(number),numerical_base,minchars,fillchar)
end sub
