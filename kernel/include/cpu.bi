#pragma once

type cpu_state
    '' saved per asm-code:
    eax as uinteger
    ebx as uinteger
    ecx as uinteger
    edx as uinteger
    esi as uinteger
    edi as uinteger
    ebp as uinteger
    
    '' saved by asm-code to identify the interrupt
    int_nr as uinteger
    errorcode as uinteger
    
    '' saved automatically by the cpu:
    eip as uinteger
    cs as uinteger
    eflags as uinteger
    esp as uinteger
    ss as uinteger
end type
