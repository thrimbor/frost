; this file is to provide stubs for the exceptions and irqs
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
int_stub 48

int_common:
    ; save the registers
    push ebp
    push edi
    push esi
    push edx
    push ecx
    push ebx
    push eax
    ;push ds
    ;push es
    ;push fs
    ;push gs
    
    ; load the ring-0 segment-registers
    ;mov ax, 0x10
    ;mov dx, ax
    ;mov es, ax
    
    ; now call the handler
    push esp            ; we push the address to the registers
    call HANDLE_INTERRUPT
    add esp, 4          ; now we skip the 4 bytes we pushed before the call
    
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