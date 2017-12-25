; FROST x86 microkernel
; Copyright (C) 2010-2017  Stefan Schmidt
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

; This file is to provide stubs for the exceptions and irqs
; which then call the interrupt handler of the kernel
section .text

extern HANDLE_INTERRUPT

; some ints push a errorcode on the stack
; the handler for ints which do not do that pushes a zero to the stack to make the stack look equal
%macro int_stub 1
	global INT_STUB_%1
	INT_STUB_%1:
		%if (%1 != 8) && (%1 < 10 || %1 > 14) && (%1 != 17)
			push dword 0
		%endif
		push dword %1
		jmp int_common
%endmacro

; create all 256 stubs (0-255)
%assign stub_counter 0
%rep 256
	int_stub stub_counter
	%assign stub_counter stub_counter+1
%endrep

extern HANDLE_INTERRUPT
global SYSENTER_ENTRY

int_common:
    ; save the registers
    push ebp
    push edi
    push esi
    push edx
    push ecx
    push ebx
    push eax

    ; load the ring-0 segment-registers
    mov ax, 0x10
    mov ds, ax
    mov es, ax

    push dword 0

    ; now call the handler
    push esp                  ; push the old stack address
    call HANDLE_INTERRUPT     ; call the interrupt-handler written in FreeBASIC
    mov esp, eax              ; set the new stack address

    pop ebx
    test ebx, ebx
    jne SYSENTER_EXIT

int_exit:
    ; load the ring-3 segment-registers
    mov ax, 0x23
    mov ds, ax
    mov es, ax

    ; restore the old state
    pop eax
    pop ebx
    pop ecx
    pop edx
    pop esi
    pop edi
    pop ebp

    ; skip the errorcode and the interrupt-number
    add esp, 8

    ; now we return
    iret


section .text
SYSENTER_ENTRY:
    ; We make the stack look like an x86 interrupt-stackframe
    sub esp, 24
    push dword 0xFF

    push ebp
    push edi
    push esi
    push edx
    push ecx
    push ebx
    push eax

    push dword 1

    push esp
    call HANDLE_INTERRUPT
    mov esp, eax

    pop ebx
    test ebx, ebx
    je int_exit

SYSENTER_EXIT:
    pop eax
    pop ebx
    pop ecx
    pop edx
    pop esi
    pop edi
    pop ebp

    add esp, 28

    ; SYSENTER clears the interrupt-flag in EFLAGS without saving,
    ; so we set it again with sti. sti has a delay of one instruction,
    ; so it's impossible we get interrupted before sysexit.
    sti
    sysexit
