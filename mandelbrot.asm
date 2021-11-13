global main

extern printf
extern scanf

section .data

section .bss

section .text

main:



end:

mov    rax, 60
mov    rdi, 0
syscall

ret