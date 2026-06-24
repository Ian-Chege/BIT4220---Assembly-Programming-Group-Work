; ============================================================
; hello.asm — Task 1: Hello World in NASM (x86-64 Linux)
; ============================================================

section .data
    msg     db  "Hello, World, from our GROUP", 0x0A
    msglen  equ $ - msg
    msg2    db  "Mic testing here, works fine...", 0x0A
    msg2len equ $ - msg2

section .bss
    unused  resb 1

section .text
    global _start   

_start:
    mov rax, 1          ; syscall #1 = sys_write
    mov rdi, 1          ; fd = 1 (stdout)
    mov rsi, msg        ; pointer to our message string
    mov rdx, msglen     ; how many bytes to write
    syscall             ; hand control to the kernel → it prints it

    mov rax, 1
    mov rdi, 1
    mov rsi, msg2
    mov rdx, msg2len
    syscall

    mov rax, 60
    mov rdi, 0
    syscall
