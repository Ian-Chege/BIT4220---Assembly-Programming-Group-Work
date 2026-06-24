; ============================================================
; buggy.asm — Task 8: Faulty Meter-Readings Analyser
; BIT 4220 Assembly Programming | x86-64 Linux NASM
;
; Computes sum, min, max and average of 8 sensor readings.
; Contains FIVE planted bugs — see BUGS.md for the full table.
;
; BUG SUMMARY
;   Bug 1  loop index starts at 1 — skips first element (arr[0]=23)
;   Bug 2  min initialised to 0  — 0 always wins against real readings
;   Bug 3  wrong array stride (×4 instead of ×8) — reads garbage bytes
;   Bug 4  average divides by sum (r8) instead of count (rbx) — result=1
;   Bug 5  max comparison inverted (jge instead of jle) — max stays 0
; ============================================================

section .data

arr         dq  23, 17, 45, 8, 91, 34, 62, 7   ; 8 sensor readings
arrlen      equ 8

s_banner:
    db 0x0A, "=== Readings Analyser (BUGGY) ===", 0x0A
s_bannerlen equ $ - s_banner
s_sum       db "Sum:     "
s_sumlen    equ $ - s_sum
s_min       db "Min:     "
s_minlen    equ $ - s_min
s_max       db "Max:     "
s_maxlen    equ $ - s_max
s_avg       db "Average: "
s_avglen    equ $ - s_avg
nl          db  0x0A

section .bss
    numbuf  resb 24

section .text
    global _start

print_str:
    push rax
    push rdi
    mov  rax, 1
    mov  rdi, 1
    syscall
    pop  rdi
    pop  rax
    ret

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
.dig:
    xor  rdx, rdx
    div  rbx
    add  dl, '0'
    mov  [rdi], dl
    dec  rdi
    inc  rcx
    test rax, rax
    jnz  .dig
    inc  rdi
    mov  rsi, rdi
    mov  rdx, rcx
    call print_str
.done:
    pop  rdi
    pop  rdx
    pop  rcx
    pop  rbx
    ret

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

_start:
    ; ── Initialise stats ──────────────────────────────────
    mov  rbx, arrlen        ; count = 8  (used as divisor for average)
    xor  r8,  r8            ; sum   = 0
    xor  r9,  r9            ; BUG 2: min = 0  (should be large sentinel)
    xor  r10, r10           ; max   = 0  (seeded from first record)
    mov  rcx, 1             ; BUG 1: index starts at 1  (should be 0)

    ; ── Process each reading ──────────────────────────────
.loop:
    mov  r12, [arr + rcx*4] ; BUG 3: stride ×4 reads wrong offsets
                             ;        correct: [arr + rcx*8]

    add  r8,  r12           ; sum += reading

    cmp  r12, r9            ; update min?
    jge  .no_min
    mov  r9,  r12
.no_min:
    cmp  r12, r10           ; update max?
    jge  .no_max            ; BUG 5: jge skips when new > current
                             ;        correct: jle (skip when new <= current)
    mov  r10, r12
.no_max:
    inc  rcx
    cmp  rcx, arrlen
    jl   .loop

    ; ── Print results ─────────────────────────────────────
    mov  rsi, s_banner
    mov  rdx, s_bannerlen
    call print_str

    mov  rsi, s_sum
    mov  rdx, s_sumlen
    call print_str
    mov  rax, r8
    call print_uint

    mov  rsi, s_min
    mov  rdx, s_minlen
    call print_str
    mov  rax, r9
    call print_uint

    mov  rsi, s_max
    mov  rdx, s_maxlen
    call print_str
    mov  rax, r10
    call print_uint

    mov  rsi, s_avg
    mov  rdx, s_avglen
    call print_str
    mov  rax, r8
    xor  rdx, rdx
    div  r8                 ; BUG 4: divides sum by sum → result always 1
                            ;        correct: div rbx  (sum / count)
    call print_uint

    mov  rax, 60
    xor  rdi, rdi
    syscall
