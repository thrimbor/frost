#pragma once

type cpu_state
    eax as uinteger
    ebx as uinteger
    ecx as uinteger
    edx as uinteger
    esi as uinteger
    edi as uinteger
    ebp as uinteger
    
    int_nr as uinteger
    errorcode as uinteger
    
    '' saved by the CPU:
    eip as uinteger
    cs as uinteger
    eflags as uinteger
    esp as uinteger
    ss as uinteger
end type
