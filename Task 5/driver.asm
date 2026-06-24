; ============================================================
; driver.asm — Task 5: Test Driver for Procedure Library
; BIT 4220 Assembly Programming | x86-64 Linux
; ============================================================
;
; Calls five procedures from procedures.o with multiple inputs
; and prints every result to stdout.
;
; r12-r15 are CALLEE-SAVED registers (preserved by every procedure
; and every print helper) — used here to hold test inputs and
; results across calls without extra push/pop overhead.
; ============================================================

extern factorial
extern str_len
extern max3
extern uint_to_dec
extern sum_array

section .data

; ── Test strings for str_len ────────────────────────────────
t_empty     db  0
t_hello     db  "Hello", 0
t_bit4220   db  "BIT4220", 0
t_code      db  "Control Flow", 0

; ── Arrays for sum_array ────────────────────────────────────
arr1        dq  1, 2, 3, 4, 5
arr2        dq  10, 20, 30, 40

; ── Banner + section headers ────────────────────────────────
banner      db  0x0A
            db  "============================================", 0x0A
            db  "  Task 5: Procedure Library Test Driver    ", 0x0A
            db  "  BIT 4220 -- Stack-Based Function Calls   ", 0x0A
            db  "============================================", 0x0A
bannerlen   equ $ - banner

hdr_fact    db  0x0A, "--- factorial (recursive) ---", 0x0A
hdr_factlen equ $ - hdr_fact
hdr_strln   db  0x0A, "--- str_len ---", 0x0A
hdr_strlnl  equ $ - hdr_strln
hdr_max3    db  0x0A, "--- max3 ---", 0x0A
hdr_max3len equ $ - hdr_max3
hdr_u2d     db  0x0A, "--- uint_to_dec ---", 0x0A
hdr_u2dlen  equ $ - hdr_u2d
hdr_sum     db  0x0A, "--- sum_array ---", 0x0A
hdr_sumlen  equ $ - hdr_sum
done_s      db  0x0A, "All tests complete.", 0x0A, 0x0A
done_slen   equ $ - done_s

; ── Shared format atoms ─────────────────────────────────────
nl          db  0x0A
s_eq        db  ") = "
s_eqlen     equ $ - s_eq
s_comma     db  ", "
s_commalen  equ $ - s_comma

; ── Procedure-specific format strings ───────────────────────
pfx_fact    db  "  factorial("
pfx_factlen equ $ - pfx_fact

pfx_strln   db  "  str_len(", 0x22      ; str_len("
pfx_strlnl  equ $ - pfx_strln
sfx_strln   db  0x22, ") = "            ; ") =
sfx_strlnl  equ $ - sfx_strln

pfx_max3    db  "  max3("
pfx_max3len equ $ - pfx_max3

pfx_u2d     db  "  uint_to_dec("
pfx_u2dlen  equ $ - pfx_u2d
s_eq_q      db  ") = ", 0x22            ; ) = "
s_eq_qlen   equ $ - s_eq_q
s_q_paren   db  0x22, "  ("             ; "  (
s_q_parenl  equ $ - s_q_paren
s_chars     db  " chars)", 0x0A
s_charslen  equ $ - s_chars

pfx_sum     db  "  sum_array("
pfx_sumlen  equ $ - pfx_sum
arr0_s      db  "[]"
arr0_slen   equ $ - arr0_s
arr1_s      db  "[1,2,3,4,5]"
arr1_slen   equ $ - arr1_s
arr2_s      db  "[10,20,30,40]"
arr2_slen   equ $ - arr2_s
s_n_eq      db  ", n="
s_n_eqlen   equ $ - s_n_eq

section .bss
    numbuf  resb 24     ; scratch for print_uint_noeol decimal conversion
    decbuf  resb 22     ; output buffer for uint_to_dec (max 20 digits + NUL)

section .text
    global _start

; ──────────────────────────────────────────────────────────────
_start:
    mov rsi, banner
    mov rdx, bannerlen
    call print_str

; ══════════════════════════════════════════════════════════════
; FACTORIAL TESTS
; ══════════════════════════════════════════════════════════════
    mov rsi, hdr_fact
    mov rdx, hdr_factlen
    call print_str

    ; factorial(0) = 1
    mov  rdi, 0
    call factorial
    mov  r15, rax
    mov  rsi, pfx_fact
    mov  rdx, pfx_factlen
    call print_str
    xor  rax, rax
    call print_uint_noeol
    mov  rsi, s_eq
    mov  rdx, s_eqlen
    call print_str
    mov  rax, r15
    call print_uint

    ; factorial(1) = 1
    mov  rdi, 1
    call factorial
    mov  r15, rax
    mov  rsi, pfx_fact
    mov  rdx, pfx_factlen
    call print_str
    mov  rax, 1
    call print_uint_noeol
    mov  rsi, s_eq
    mov  rdx, s_eqlen
    call print_str
    mov  rax, r15
    call print_uint

    ; factorial(5) = 120
    mov  rdi, 5
    call factorial
    mov  r15, rax
    mov  rsi, pfx_fact
    mov  rdx, pfx_factlen
    call print_str
    mov  rax, 5
    call print_uint_noeol
    mov  rsi, s_eq
    mov  rdx, s_eqlen
    call print_str
    mov  rax, r15
    call print_uint

    ; factorial(10) = 3628800
    mov  rdi, 10
    call factorial
    mov  r15, rax
    mov  rsi, pfx_fact
    mov  rdx, pfx_factlen
    call print_str
    mov  rax, 10
    call print_uint_noeol
    mov  rsi, s_eq
    mov  rdx, s_eqlen
    call print_str
    mov  rax, r15
    call print_uint

    ; factorial(12) = 479001600
    mov  rdi, 12
    call factorial
    mov  r15, rax
    mov  rsi, pfx_fact
    mov  rdx, pfx_factlen
    call print_str
    mov  rax, 12
    call print_uint_noeol
    mov  rsi, s_eq
    mov  rdx, s_eqlen
    call print_str
    mov  rax, r15
    call print_uint

; ══════════════════════════════════════════════════════════════
; STR_LEN TESTS
; r12 = string address (callee-saved: survives str_len call)
; r15 = length result  (callee-saved: survives all print calls)
; ══════════════════════════════════════════════════════════════
    mov rsi, hdr_strln
    mov rdx, hdr_strlnl
    call print_str

    ; str_len("") = 0
    mov  r12, t_empty
    mov  rdi, r12
    call str_len
    mov  r15, rax
    mov  rsi, pfx_strln
    mov  rdx, pfx_strlnl
    call print_str
    mov  rsi, r12
    mov  rdx, r15
    call print_str
    mov  rsi, sfx_strln
    mov  rdx, sfx_strlnl
    call print_str
    mov  rax, r15
    call print_uint

    ; str_len("Hello") = 5
    mov  r12, t_hello
    mov  rdi, r12
    call str_len
    mov  r15, rax
    mov  rsi, pfx_strln
    mov  rdx, pfx_strlnl
    call print_str
    mov  rsi, r12
    mov  rdx, r15
    call print_str
    mov  rsi, sfx_strln
    mov  rdx, sfx_strlnl
    call print_str
    mov  rax, r15
    call print_uint

    ; str_len("BIT4220") = 7
    mov  r12, t_bit4220
    mov  rdi, r12
    call str_len
    mov  r15, rax
    mov  rsi, pfx_strln
    mov  rdx, pfx_strlnl
    call print_str
    mov  rsi, r12
    mov  rdx, r15
    call print_str
    mov  rsi, sfx_strln
    mov  rdx, sfx_strlnl
    call print_str
    mov  rax, r15
    call print_uint

    ; str_len("Control Flow") = 12
    mov  r12, t_code
    mov  rdi, r12
    call str_len
    mov  r15, rax
    mov  rsi, pfx_strln
    mov  rdx, pfx_strlnl
    call print_str
    mov  rsi, r12
    mov  rdx, r15
    call print_str
    mov  rsi, sfx_strln
    mov  rdx, sfx_strlnl
    call print_str
    mov  rax, r15
    call print_uint

; ══════════════════════════════════════════════════════════════
; MAX3 TESTS
; r12=a, r13=b, r14=c, r15=result (all callee-saved)
; ══════════════════════════════════════════════════════════════
    mov rsi, hdr_max3
    mov rdx, hdr_max3len
    call print_str

    ; max3(10, 20, 30) = 30  [maximum is the last argument]
    mov  r12, 10
    mov  r13, 20
    mov  r14, 30
    mov  rdi, r12
    mov  rsi, r13
    mov  rdx, r14
    call max3
    mov  r15, rax
    mov  rsi, pfx_max3
    mov  rdx, pfx_max3len
    call print_str
    mov  rax, r12
    call print_uint_noeol
    mov  rsi, s_comma
    mov  rdx, s_commalen
    call print_str
    mov  rax, r13
    call print_uint_noeol
    mov  rsi, s_comma
    mov  rdx, s_commalen
    call print_str
    mov  rax, r14
    call print_uint_noeol
    mov  rsi, s_eq
    mov  rdx, s_eqlen
    call print_str
    mov  rax, r15
    call print_uint

    ; max3(30, 20, 10) = 30  [maximum is the first argument]
    mov  r12, 30
    mov  r13, 20
    mov  r14, 10
    mov  rdi, r12
    mov  rsi, r13
    mov  rdx, r14
    call max3
    mov  r15, rax
    mov  rsi, pfx_max3
    mov  rdx, pfx_max3len
    call print_str
    mov  rax, r12
    call print_uint_noeol
    mov  rsi, s_comma
    mov  rdx, s_commalen
    call print_str
    mov  rax, r13
    call print_uint_noeol
    mov  rsi, s_comma
    mov  rdx, s_commalen
    call print_str
    mov  rax, r14
    call print_uint_noeol
    mov  rsi, s_eq
    mov  rdx, s_eqlen
    call print_str
    mov  rax, r15
    call print_uint

    ; max3(10, 30, 20) = 30  [maximum is the middle argument]
    mov  r12, 10
    mov  r13, 30
    mov  r14, 20
    mov  rdi, r12
    mov  rsi, r13
    mov  rdx, r14
    call max3
    mov  r15, rax
    mov  rsi, pfx_max3
    mov  rdx, pfx_max3len
    call print_str
    mov  rax, r12
    call print_uint_noeol
    mov  rsi, s_comma
    mov  rdx, s_commalen
    call print_str
    mov  rax, r13
    call print_uint_noeol
    mov  rsi, s_comma
    mov  rdx, s_commalen
    call print_str
    mov  rax, r14
    call print_uint_noeol
    mov  rsi, s_eq
    mov  rdx, s_eqlen
    call print_str
    mov  rax, r15
    call print_uint

    ; max3(7, 7, 7) = 7  [all equal]
    mov  r12, 7
    mov  r13, 7
    mov  r14, 7
    mov  rdi, r12
    mov  rsi, r13
    mov  rdx, r14
    call max3
    mov  r15, rax
    mov  rsi, pfx_max3
    mov  rdx, pfx_max3len
    call print_str
    mov  rax, r12
    call print_uint_noeol
    mov  rsi, s_comma
    mov  rdx, s_commalen
    call print_str
    mov  rax, r13
    call print_uint_noeol
    mov  rsi, s_comma
    mov  rdx, s_commalen
    call print_str
    mov  rax, r14
    call print_uint_noeol
    mov  rsi, s_eq
    mov  rdx, s_eqlen
    call print_str
    mov  rax, r15
    call print_uint

; ══════════════════════════════════════════════════════════════
; UINT_TO_DEC TESTS
; r12 = input n (callee-saved: survives uint_to_dec call)
; r15 = char count returned (callee-saved: survives print calls)
; decbuf holds the result string
; ══════════════════════════════════════════════════════════════
    mov rsi, hdr_u2d
    mov rdx, hdr_u2dlen
    call print_str

    ; uint_to_dec(0) = "0"  (1 char)
    mov  r12, 0
    mov  rdi, r12
    lea  rsi, [decbuf]
    call uint_to_dec
    mov  r15, rax
    mov  rsi, pfx_u2d
    mov  rdx, pfx_u2dlen
    call print_str
    mov  rax, r12
    call print_uint_noeol
    mov  rsi, s_eq_q
    mov  rdx, s_eq_qlen
    call print_str
    lea  rsi, [decbuf]
    mov  rdx, r15
    call print_str
    mov  rsi, s_q_paren
    mov  rdx, s_q_parenl
    call print_str
    mov  rax, r15
    call print_uint_noeol
    mov  rsi, s_chars
    mov  rdx, s_charslen
    call print_str

    ; uint_to_dec(42) = "42"  (2 chars)
    mov  r12, 42
    mov  rdi, r12
    lea  rsi, [decbuf]
    call uint_to_dec
    mov  r15, rax
    mov  rsi, pfx_u2d
    mov  rdx, pfx_u2dlen
    call print_str
    mov  rax, r12
    call print_uint_noeol
    mov  rsi, s_eq_q
    mov  rdx, s_eq_qlen
    call print_str
    lea  rsi, [decbuf]
    mov  rdx, r15
    call print_str
    mov  rsi, s_q_paren
    mov  rdx, s_q_parenl
    call print_str
    mov  rax, r15
    call print_uint_noeol
    mov  rsi, s_chars
    mov  rdx, s_charslen
    call print_str

    ; uint_to_dec(255) = "255"  (3 chars)
    mov  r12, 255
    mov  rdi, r12
    lea  rsi, [decbuf]
    call uint_to_dec
    mov  r15, rax
    mov  rsi, pfx_u2d
    mov  rdx, pfx_u2dlen
    call print_str
    mov  rax, r12
    call print_uint_noeol
    mov  rsi, s_eq_q
    mov  rdx, s_eq_qlen
    call print_str
    lea  rsi, [decbuf]
    mov  rdx, r15
    call print_str
    mov  rsi, s_q_paren
    mov  rdx, s_q_parenl
    call print_str
    mov  rax, r15
    call print_uint_noeol
    mov  rsi, s_chars
    mov  rdx, s_charslen
    call print_str

    ; uint_to_dec(65535) = "65535"  (5 chars)
    mov  r12, 65535
    mov  rdi, r12
    lea  rsi, [decbuf]
    call uint_to_dec
    mov  r15, rax
    mov  rsi, pfx_u2d
    mov  rdx, pfx_u2dlen
    call print_str
    mov  rax, r12
    call print_uint_noeol
    mov  rsi, s_eq_q
    mov  rdx, s_eq_qlen
    call print_str
    lea  rsi, [decbuf]
    mov  rdx, r15
    call print_str
    mov  rsi, s_q_paren
    mov  rdx, s_q_parenl
    call print_str
    mov  rax, r15
    call print_uint_noeol
    mov  rsi, s_chars
    mov  rdx, s_charslen
    call print_str

; ══════════════════════════════════════════════════════════════
; SUM_ARRAY TESTS
; r13 = element count n (callee-saved)
; r15 = sum result      (callee-saved)
; ══════════════════════════════════════════════════════════════
    mov rsi, hdr_sum
    mov rdx, hdr_sumlen
    call print_str

    ; sum_array([], n=0) = 0
    lea  rdi, [arr1]        ; pointer (n=0 means nothing is read)
    xor  r13, r13           ; n = 0
    mov  rsi, r13
    call sum_array
    mov  r15, rax
    mov  rsi, pfx_sum
    mov  rdx, pfx_sumlen
    call print_str
    mov  rsi, arr0_s
    mov  rdx, arr0_slen
    call print_str
    mov  rsi, s_n_eq
    mov  rdx, s_n_eqlen
    call print_str
    mov  rax, r13
    call print_uint_noeol
    mov  rsi, s_eq
    mov  rdx, s_eqlen
    call print_str
    mov  rax, r15
    call print_uint

    ; sum_array([1,2,3,4,5], n=5) = 15
    lea  rdi, [arr1]
    mov  r13, 5
    mov  rsi, r13
    call sum_array
    mov  r15, rax
    mov  rsi, pfx_sum
    mov  rdx, pfx_sumlen
    call print_str
    mov  rsi, arr1_s
    mov  rdx, arr1_slen
    call print_str
    mov  rsi, s_n_eq
    mov  rdx, s_n_eqlen
    call print_str
    mov  rax, r13
    call print_uint_noeol
    mov  rsi, s_eq
    mov  rdx, s_eqlen
    call print_str
    mov  rax, r15
    call print_uint

    ; sum_array([10,20,30,40], n=4) = 100
    lea  rdi, [arr2]
    mov  r13, 4
    mov  rsi, r13
    call sum_array
    mov  r15, rax
    mov  rsi, pfx_sum
    mov  rdx, pfx_sumlen
    call print_str
    mov  rsi, arr2_s
    mov  rdx, arr2_slen
    call print_str
    mov  rsi, s_n_eq
    mov  rdx, s_n_eqlen
    call print_str
    mov  rax, r13
    call print_uint_noeol
    mov  rsi, s_eq
    mov  rdx, s_eqlen
    call print_str
    mov  rax, r15
    call print_uint

; ── All done ─────────────────────────────────────────────────
    mov rsi, done_s
    mov rdx, done_slen
    call print_str

    mov rax, 60             ; sys_exit
    xor rdi, rdi            ; status 0
    syscall

; ──────────────────────────────────────────────────────────────
; print_str — sys_write(stdout, rsi, rdx)
;   Saves rax, rdi. Syscall clobbers rcx, r11.
; ──────────────────────────────────────────────────────────────
print_str:
    push rax
    push rdi
    mov  rax, 1
    mov  rdi, 1
    syscall
    pop  rdi
    pop  rax
    ret

; ──────────────────────────────────────────────────────────────
; print_uint — print rax as unsigned decimal + newline
; ──────────────────────────────────────────────────────────────
print_uint:
    call print_uint_noeol
    push rsi
    push rdx
    mov  rsi, nl
    mov  rdx, 1
    call print_str
    pop  rdx
    pop  rsi
    ret

; ──────────────────────────────────────────────────────────────
; print_uint_noeol — print rax as unsigned decimal, no newline
;   Preserves: rbx, rcx, rdx, rdi
; ──────────────────────────────────────────────────────────────
print_uint_noeol:
    push rbx
    push rcx
    push rdx
    push rdi

    test rax, rax
    jnz  .nonzero
    lea  rsi, [numbuf]
    mov  byte [rsi], '0'
    mov  rdx, 1
    call print_str
    jmp  .done

.nonzero:
    mov  rbx, 10
    xor  rcx, rcx
    lea  rdi, [numbuf + 23]
.digit:
    xor  rdx, rdx
    div  rbx
    add  dl, '0'
    mov  [rdi], dl
    dec  rdi
    inc  rcx
    test rax, rax
    jnz  .digit
    inc  rdi
    mov  rsi, rdi
    mov  rdx, rcx
    call print_str

.done:
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret
