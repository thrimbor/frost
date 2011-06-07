[global _start]
_start:
before:
mov eax, 666
int 0x62
jmp before
