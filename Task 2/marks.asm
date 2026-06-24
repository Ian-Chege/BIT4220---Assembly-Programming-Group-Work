; ============================================================
; marks.asm — Task 2: Student Marks Processor (x86-64 Linux)
; BIT 4220 Assembly Programming | Group Work Session 1
; ============================================================
;
; WHAT THIS PROGRAM DOES
;   - Stores an array of 10 student marks in memory.
;   - Computes total, average, highest and lowest using a loop.
;   - Counts how many marks fall into each classification band.
;   - Demonstrates SIX addressing modes (tagged in comments below).
;
; CLASSIFICATION BANDS
;   Fail        :   0 - 39
;   Pass        :  40 - 49
;   Credit      :  50 - 69
;   Distinction :  70 - 100
;
; ADDRESSING MODES USED (see TECHNICAL_NOTES.md for full explanation):
;   [IMM]  immediate  - a literal value baked into the instruction
;   [REG]  register   - operand is a CPU register
;   [DIR]  direct     - operand is a fixed, named memory location
;   [IND]  indirect   - address is held in a register: [reg]
;   [IDX]  indexed    - displacement + index register: [label + reg]
;   [BAS]  based      - base register + displacement: [reg + disp]
; ============================================================

section .data
    ; ── The marks array (deliverable: at least 10 marks) ──────
    ; Chosen to hit every boundary in the test plan: 0,39,40,69,70,100.
    marks   db  0, 39, 40, 55, 69, 70, 85, 100, 45, 60
    nmarks  equ $ - marks          ; assembler computes the count = 10

    ; ── Output labels (text + its length via $ - label) ───────
    hdr     db  "=== Task 2: Student Marks Processor ===", 0x0A
    hdrlen  equ $ - hdr

    m_ind   db  "marks[0] via INDIRECT [rbx]      = "
    m_indl  equ $ - m_ind
    m_bas   db  "marks[5] via BASED    [rbx+5]    = "
    m_basl  equ $ - m_bas

    m_tot   db  "Total mark .................. "
    m_totl  equ $ - m_tot
    m_avg   db  "Average mark ................ "
    m_avgl  equ $ - m_avg
    m_hi    db  "Highest mark ................ "
    m_hil   equ $ - m_hi
    m_lo    db  "Lowest mark ................. "
    m_lol   equ $ - m_lo

    m_fail  db  "Fail        (0-39) .......... "
    m_faill equ $ - m_fail
    m_pass  db  "Pass        (40-49) ......... "
    m_passl equ $ - m_pass
    m_cred  db  "Credit      (50-69) ......... "
    m_credl equ $ - m_cred
    m_dist  db  "Distinction (70-100) ........ "
    m_distl equ $ - m_dist

    nl      db  0x0A

section .bss
    ; Classification counters (direct-addressed memory variables).
    cnt_fail  resq 1
    cnt_pass  resq 1
    cnt_cred  resq 1
    cnt_dist  resq 1

    numbuf    resb 24              ; scratch space for number->text

section .text
    global _start

_start:
    ; ── Print header ──────────────────────────────────────────
    mov rsi, hdr
    mov rdx, hdrlen
    call print_str

    ; ====================================================================
    ; ADDRESSING-MODE DEMONSTRATION (indirect + based)
    ; ====================================================================
    lea rbx, [marks]               ; [REG]/[IMM] load base ADDRESS of array

    mov rsi, m_ind                 ; print the label FIRST...
    mov rdx, m_indl
    call print_str
    movzx rax, byte [rbx]          ; [IND] indirect: byte at address in rbx
    call print_uint                ; ...then the value (marks[0] = 0)

    mov rsi, m_bas
    mov rdx, m_basl
    call print_str
    movzx rax, byte [rbx + 5]      ; [BAS] based: base rbx + displacement 5
    call print_uint                ; prints marks[5] = 70

    ; ====================================================================
    ; MAIN LOOP — total, highest, lowest, classification (indexed access)
    ; ====================================================================
    xor rcx, rcx                   ; [IMM] index i = 0
    xor r8,  r8                    ; [REG] total accumulator = 0
    xor r9,  r9                    ; highest = 0
    mov r10, 255                   ; [IMM] lowest = 255 (sentinel)
    mov r11, nmarks                ; [IMM] loop count = 10

.loop:
    movzx rax, byte [marks + rcx]  ; [IDX] indexed: displacement 'marks' + index rcx

    add r8, rax                    ; [REG] total += mark

    cmp rax, r9                    ; highest?
    jbe .not_high
    mov r9, rax                    ; [REG] highest = mark
.not_high:
    cmp rax, r10                   ; lowest?
    jae .not_low
    mov r10, rax                   ; [REG] lowest = mark
.not_low:

    ; ── classify into bands ──
    cmp rax, 40                    ; [IMM] compare against literal 40
    jb  .is_fail
    cmp rax, 50
    jb  .is_pass
    cmp rax, 70
    jb  .is_cred
    inc qword [cnt_dist]           ; [DIR] direct: increment named counter
    jmp .next
.is_fail:
    inc qword [cnt_fail]           ; [DIR]
    jmp .next
.is_pass:
    inc qword [cnt_pass]           ; [DIR]
    jmp .next
.is_cred:
    inc qword [cnt_cred]           ; [DIR]
.next:
    inc rcx                        ; i++
    cmp rcx, r11                   ; [REG] compare index with count
    jb  .loop

    ; ====================================================================
    ; PRINT RESULTS  (r8=total, r9=highest, r10=lowest survive printing)
    ; ====================================================================
    mov rsi, m_tot
    mov rdx, m_totl
    call print_str
    mov rax, r8                    ; [REG] total
    call print_uint

    mov rsi, m_avg
    mov rdx, m_avgl
    call print_str
    mov rax, r8                    ; average = total / count
    xor rdx, rdx
    mov rbx, nmarks                ; [IMM] divisor = 10
    div rbx                        ; rax = total / 10
    call print_uint

    mov rsi, m_hi
    mov rdx, m_hil
    call print_str
    mov rax, r9                    ; [REG] highest
    call print_uint

    mov rsi, m_lo
    mov rdx, m_lol
    call print_str
    mov rax, r10                   ; [REG] lowest
    call print_uint

    mov rsi, m_fail
    mov rdx, m_faill
    call print_str
    mov rax, [cnt_fail]            ; [DIR]
    call print_uint

    mov rsi, m_pass
    mov rdx, m_passl
    call print_str
    mov rax, [cnt_pass]            ; [DIR]
    call print_uint

    mov rsi, m_cred
    mov rdx, m_credl
    call print_str
    mov rax, [cnt_cred]            ; [DIR]
    call print_uint

    mov rsi, m_dist
    mov rdx, m_distl
    call print_str
    mov rax, [cnt_dist]            ; [DIR]
    call print_uint

    ; ── Exit cleanly ──────────────────────────────────────────
    mov rax, 60                    ; [IMM] syscall: exit
    xor rdi, rdi                   ; [REG] status 0
    syscall

; ====================================================================
; HELPER: print_str  —  write(1, rsi, rdx)
;   in:  rsi = address, rdx = length
;   note: 'syscall' clobbers rcx and r11 (Linux ABI) — safe here because
;         we only print AFTER the main loop has finished using them.
; ====================================================================
print_str:
    mov rax, 1                     ; [IMM] sys_write
    mov rdi, 1                     ; [IMM] fd = stdout
    syscall
    ret

; ====================================================================
; HELPER: print_uint  —  print rax as decimal, followed by newline
;   in:  rax = unsigned value
;   uses: rax,rcx,rdx,rsi,rdi  (preserves rbx; does NOT touch r8/r9/r10/r11)
; ====================================================================
print_uint:
    push rbx                       ; caller uses rbx as the array base pointer
    mov rbx, 10                    ; [IMM] divisor (base 10)
    xor rcx, rcx                   ; digit counter
    lea rdi, [numbuf + 23]         ; [BAS] point at end of buffer
.next_digit:
    xor rdx, rdx
    div rbx                        ; rax /= 10 ; rdx = remainder digit
    add dl, '0'                    ; [IMM] turn digit into ASCII
    mov [rdi], dl                  ; [IND] store digit at address in rdi
    dec rdi
    inc rcx
    test rax, rax
    jnz .next_digit                ; loop until value is 0
    inc rdi                        ; rdi -> first (most significant) digit

    mov rsi, rdi                   ; address of digit string
    mov rdx, rcx                   ; how many digits
    mov rax, 1                     ; sys_write
    mov rdi, 1                     ; stdout
    syscall

    mov rsi, nl                    ; trailing newline
    mov rdx, 1
    mov rax, 1
    mov rdi, 1
    syscall
    pop rbx                        ; restore caller's base pointer
    ret
