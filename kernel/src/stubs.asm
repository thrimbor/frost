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

; reserved
int_stub 19
int_stub 20
int_stub 21
int_stub 22
int_stub 23
int_stub 24
int_stub 25
int_stub 26
int_stub 27
int_stub 28
int_stub 29
int_stub 30
int_stub 31

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

int_stub 48
int_stub 49
int_stub 50
int_stub 51
int_stub 52
int_stub 53
int_stub 54
int_stub 55
int_stub 56
int_stub 57
int_stub 58
int_stub 59
int_stub 60
int_stub 61
int_stub 62
int_stub 63
int_stub 64
int_stub 65
int_stub 66
int_stub 67
int_stub 68
int_stub 69
int_stub 70
int_stub 71
int_stub 72
int_stub 73
int_stub 74
int_stub 75
int_stub 76
int_stub 77
int_stub 78
int_stub 79
int_stub 80
int_stub 81
int_stub 82
int_stub 83
int_stub 84
int_stub 85
int_stub 86
int_stub 87
int_stub 88
int_stub 89
int_stub 90
int_stub 91
int_stub 92
int_stub 93
int_stub 94
int_stub 95
int_stub 96
int_stub 97
int_stub 98
int_stub 99
int_stub 100
int_stub 101
int_stub 102
int_stub 103
int_stub 104
int_stub 105
int_stub 106
int_stub 107
int_stub 108
int_stub 109
int_stub 110
int_stub 111
int_stub 112
int_stub 113
int_stub 114
int_stub 115
int_stub 116
int_stub 117
int_stub 118
int_stub 119
int_stub 120
int_stub 121
int_stub 122
int_stub 123
int_stub 124
int_stub 125
int_stub 126
int_stub 127
int_stub 128
int_stub 129
int_stub 130
int_stub 131
int_stub 132
int_stub 133
int_stub 134
int_stub 135
int_stub 136
int_stub 137
int_stub 138
int_stub 139
int_stub 140
int_stub 141
int_stub 142
int_stub 143
int_stub 144
int_stub 145
int_stub 146
int_stub 147
int_stub 148
int_stub 149
int_stub 150
int_stub 151
int_stub 152
int_stub 153
int_stub 154
int_stub 155
int_stub 156
int_stub 157
int_stub 158
int_stub 159
int_stub 160
int_stub 161
int_stub 162
int_stub 163
int_stub 164
int_stub 165
int_stub 166
int_stub 167
int_stub 168
int_stub 169
int_stub 170
int_stub 171
int_stub 172
int_stub 173
int_stub 174
int_stub 175
int_stub 176
int_stub 177
int_stub 178
int_stub 179
int_stub 180
int_stub 181
int_stub 182
int_stub 183
int_stub 184
int_stub 185
int_stub 186
int_stub 187
int_stub 188
int_stub 189
int_stub 190
int_stub 191
int_stub 192
int_stub 193
int_stub 194
int_stub 195
int_stub 196
int_stub 197
int_stub 198
int_stub 199
int_stub 200
int_stub 201
int_stub 202
int_stub 203
int_stub 204
int_stub 205
int_stub 206
int_stub 207
int_stub 208
int_stub 209
int_stub 210
int_stub 211
int_stub 212
int_stub 213
int_stub 214
int_stub 215
int_stub 216
int_stub 217
int_stub 218
int_stub 219
int_stub 220
int_stub 221
int_stub 222
int_stub 223
int_stub 224
int_stub 225
int_stub 226
int_stub 227
int_stub 228
int_stub 229
int_stub 230
int_stub 231
int_stub 232
int_stub 233
int_stub 234
int_stub 235
int_stub 236
int_stub 237
int_stub 238
int_stub 239
int_stub 240
int_stub 241
int_stub 242
int_stub 243
int_stub 244
int_stub 245
int_stub 246
int_stub 247
int_stub 248
int_stub 249
int_stub 250
int_stub 251
int_stub 252
int_stub 253
int_stub 254
int_stub 255


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
