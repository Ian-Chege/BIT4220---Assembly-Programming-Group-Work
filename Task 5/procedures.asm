; ============================================================
; procedures.asm — Task 5: Reusable Procedure Library
; BIT 4220 Assembly Programming | x86-64 Linux
; ============================================================
;
; CALLING CONVENTION  (System V AMD64 ABI — Linux standard)
;   Integer arguments : rdi, rsi, rdx, rcx, r8, r9
;   Return value      : rax
;   Callee-saved regs : rbx, rbp, r12-r15, rsp  ← procedures MUST preserve
;   Caller-saved regs : rax, rcx, rdx, rsi, rdi, r8-r11  ← may be clobbered
;
; EXPORTED PROCEDURES
;   1. factorial(n:rdi)          -> rax   recursive n!
;   2. str_len(str:rdi)          -> rax   null-terminated string length
;   3. max3(a:rdi, b:rsi, c:rdx) -> rax   largest of three signed integers
;   4. uint_to_dec(n:rdi,buf:rsi)-> rax   unsigned int → decimal ASCII string
;   5. sum_array(arr:rdi, n:rsi) -> rax   sum of n × 8-byte signed integers
;
; BUILD (as part of a two-object link — see run.sh)
;   nasm -f elf64 procedures.asm -o procedures.o
;   nasm -f elf64 driver.asm     -o driver.o
;   ld procedures.o driver.o -o driver
; ============================================================

global factorial
global str_len
global max3
global uint_to_dec
global sum_array

section .text

; ──────────────────────────────────────────────────────────────
; 1. factorial(n: rdi) -> rax
;
; Returns n!  computed recursively.
;   Base case : n <= 1  → rax = 1
;   Recursive : rax = n × factorial(n-1)
;
; Register discipline
;   rbx is CALLEE-SAVED: we push it so the CALLER's rbx is not lost.
;   We then store n in rbx so that it survives the recursive CALL.
;   Each recursive frame pushes its own copy of rbx, building a
;   "chain" of saved n values on the stack (see STACK_DIAGRAMS.md).
;
; Safe input range: n ≤ 20  (20! fits in a 64-bit unsigned integer).
; For n > 20 the product overflows silently.
; ──────────────────────────────────────────────────────────────
factorial:
    push rbx                ; ← CALLEE-SAVE: preserve caller's rbx
    mov  rbx, rdi           ; rbx = n  (will survive the recursive CALL)

    cmp  rdi, 1
    jle  .base              ; n <= 1: return 1

    dec  rdi                ; arg = n - 1
    call factorial          ; rax = (n-1)!   (recursive; factorial preserves rbx)
    imul rax, rbx           ; rax = n * (n-1)! = n!
    jmp  .done

.base:
    mov  rax, 1             ; 0! = 1! = 1

.done:
    pop  rbx                ; ← RESTORE caller's rbx
    ret

; ──────────────────────────────────────────────────────────────
; 2. str_len(str: rdi) -> rax
;
; Counts bytes from str until the first NUL byte (exclusive).
; Returns 0 for an empty string (str[0] == 0).
;
; No registers need saving: rdi (arg) and rax (counter/return) are
; both caller-saved by the ABI, so clobbering them is permitted.
; ──────────────────────────────────────────────────────────────
str_len:
    xor  rax, rax           ; length = 0
.sl_loop:
    cmp  byte [rdi + rax], 0
    je   .sl_done
    inc  rax
    jmp  .sl_loop
.sl_done:
    ret

; ──────────────────────────────────────────────────────────────
; 3. max3(a: rdi, b: rsi, c: rdx) -> rax
;
; Returns the largest of three signed 64-bit integers.
; All three arguments and rax are caller-saved — no push/pop needed.
; ──────────────────────────────────────────────────────────────
max3:
    mov  rax, rdi           ; assume a is maximum
    cmp  rsi, rax
    jle  .m3c
    mov  rax, rsi           ; b is larger
.m3c:
    cmp  rdx, rax
    jle  .m3done
    mov  rax, rdx           ; c is largest
.m3done:
    ret

; ──────────────────────────────────────────────────────────────
; 4. uint_to_dec(n: rdi, buf: rsi) -> rax
;
; Converts unsigned 64-bit n to a decimal ASCII string in buf,
; null-terminated.  buf must be at least 21 bytes.
; Returns: number of characters written (not counting NUL).
;
; Algorithm
;   Divide n by 10 repeatedly, storing each remainder right-to-left
;   in the LAST 21 bytes of buf.  Then copy the result to buf[0..].
;   Avoids a separate scratch buffer by using the tail of buf itself.
;
; Register discipline
;   rbx  — working write pointer (callee-saved: pushed/popped)
;   rdi  — n, consumed by DIV (caller-saved: may be clobbered)
;   rsi  — buf pointer (caller-saved; caller must reload after call)
;   rax  — quotient then return value
;   rdx  — remainder from DIV (caller-saved)
;   rcx  — divisor 10 (caller-saved)
;   r8   — digit count (caller-saved)
;   r9   — saved buf-start address (caller-saved)
; ──────────────────────────────────────────────────────────────
uint_to_dec:
    push rbx                ; ← CALLEE-SAVE

    mov  r9, rsi            ; r9 = buf start (persists through div loop)

    test rdi, rdi           ; n == 0 ?
    jnz  .u2d_nonzero
    mov  byte [r9],     '0'
    mov  byte [r9 + 1], 0
    mov  rax, 1
    pop  rbx
    ret

.u2d_nonzero:
    lea  rbx, [r9 + 20]    ; rbx = one-past-end of 21-byte workspace
    mov  byte [rbx], 0     ; plant NUL terminator
    mov  rax, rdi          ; rax = n
    mov  rcx, 10           ; divisor (caller-saved: no push required)
    xor  r8,  r8           ; digit count = 0

.u2d_digit:
    xor  rdx, rdx
    div  rcx               ; rax = rax/10;  rdx = rax mod 10
    dec  rbx
    add  dl, '0'
    mov  [rbx], dl         ; store digit right-to-left
    inc  r8
    test rax, rax
    jnz  .u2d_digit

    ; Copy r8 bytes from rbx (first/most-significant digit) to r9 (buf start)
    mov  rcx, r8
.u2d_copy:
    mov  al,  [rbx]
    mov  [r9], al
    inc  rbx
    inc  r9
    dec  rcx
    jnz  .u2d_copy
    mov  byte [r9], 0      ; null-terminate

    mov  rax, r8           ; return digit count
    pop  rbx               ; ← RESTORE
    ret

; ──────────────────────────────────────────────────────────────
; 5. sum_array(arr: rdi, n: rsi) -> rax
;
; Sums n consecutive signed 64-bit integers starting at arr.
; arr must be 8-byte aligned.  Returns 0 when n == 0.
;
; Only caller-saved registers used (rax, rcx, rdi, rsi) — no
; push/pop required.
; ──────────────────────────────────────────────────────────────
sum_array:
    xor  rax, rax           ; sum = 0
    test rsi, rsi
    jz   .sa_done           ; n == 0: return 0
    xor  rcx, rcx           ; index i = 0
.sa_loop:
    add  rax, [rdi + rcx*8] ; sum += arr[i]
    inc  rcx
    cmp  rcx, rsi           ; i < n ?
    jb   .sa_loop
.sa_done:
    ret
