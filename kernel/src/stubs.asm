; FROST x86 microkernel
; Copyright (C) 2010-2013  Stefan Schmidt
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
        push dword 0
        push dword %1
    jmp int_common
%endmacro

%macro int_stub_errcode 1
    global INT_STUB_%1
    INT_STUB_%1:
        push dword %1
    jmp int_common
%endmacro

; all the stubs for the exceptions
int_stub 0
int_stub 1
int_stub 2
int_stub 3
int_stub 4
int_stub 5
int_stub 6
int_stub 7
int_stub_errcode 8
int_stub 9
int_stub_errcode 10
int_stub_errcode 11
int_stub_errcode 12
int_stub_errcode 13
int_stub_errcode 14
int_stub 15
int_stub 16
int_stub_errcode 17
int_stub 18

; now the irqs
int_stub 32
int_stub 33
int_stub 34
int_stub 35
int_stub 36
int_stub 37
int_stub 38
int_stub 39
int_stub 40
int_stub 41
int_stub 42
int_stub 43
int_stub 44
int_stub 45
int_stub 46
int_stub 47

; and the syscall-interrupt
int_stub 98

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
    
    ; now call the handler
    push esp                  ; push the old stack address
    call HANDLE_INTERRUPT     ; call the interrupt-handler written in FreeBASIC
    mov esp, eax              ; set the new stack address
    
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
