; ============================================================
; toolkit.asm — Task 6: String & Array Toolkit for Log Cleaning
; BIT 4220 Assembly Programming | x86-64 Linux NASM
; ============================================================
;
; Themed as a log-cleaning utility for a prepaid utility meter
; helpdesk.  Five sample device logs are pre-loaded; the user
; selects one and applies any combination of operations.
;
; PROCEDURES
;   to_upper  (buf: rdi)            in-place a-z → A-Z
;   str_rev   (buf: rdi)            in-place string reversal
;   char_count(buf: rdi)            writes 4 global counters
;   kw_search (hay: rdi, nd: rsi)   → rax (offset or -1)
;   copy_str  (dst: rdi, src: rsi)  NUL-terminated copy (helper)
;
; CALLING CONVENTION  (System V AMD64 ABI)
;   Callee-saved : rbx, rbp, r12–r15, rsp
;   Caller-saved : rax, rcx, rdx, rsi, rdi, r8–r11
; ============================================================

section .data

; ── Sample log strings (read-only) ──────────────────────────
log1        db  "ERR: meter fault at 09:42 -- device #mtr-001", 0
log2        db  "warn: low credit balance detected (5 units left)", 0
log3        db  "INFO: RECHARGE OK -- 100 KWH ADDED 2024-06-21", 0
log4        db  0                        ; empty string (edge case)
log5        db  "Critical: Volt.spike=245V exceeded threshold!!!", 0

log_tbl     dq  log1, log2, log3, log4, log5

; ── Banner ───────────────────────────────────────────────────
banner_s:
    db 0x0A
    db "=====================================================", 0x0A
    db "  Task 6: String & Array Toolkit -- Log Cleaner    ", 0x0A
    db "  BIT 4220 Assembly Programming                    ", 0x0A
    db "=====================================================", 0x0A
banner_len  equ $ - banner_s

; ── Log select menu ──────────────────────────────────────────
mhdr_s:
    db 0x0A, "  Select a log to process:", 0x0A
mhdr_len    equ $ - mhdr_s

ml1_s       db  "    1)  ERR: meter fault at 09:42 -- device #mtr-001", 0x0A
ml1_len     equ $ - ml1_s
ml2_s       db  "    2)  warn: low credit balance detected (5 units left)", 0x0A
ml2_len     equ $ - ml2_s
ml3_s       db  "    3)  INFO: RECHARGE OK -- 100 KWH ADDED 2024-06-21", 0x0A
ml3_len     equ $ - ml3_s
ml4_s       db  "    4)  [empty string]", 0x0A
ml4_len     equ $ - ml4_s
ml5_s       db  "    5)  Critical: Volt.spike=245V exceeded threshold!!!", 0x0A
ml5_len     equ $ - ml5_s
ml0_s       db  "    0)  Exit", 0x0A
ml0_len     equ $ - ml0_s
mprompt_s   db  "  Choice: "
mprompt_len equ $ - mprompt_s

; ── Current log display ──────────────────────────────────────
scurr_s:
    db 0x0A, "  Current log: "
scurr_len   equ $ - scurr_s

; ── Operations menu ──────────────────────────────────────────
ohdr_s:
    db 0x0A
    db "  Choose an operation:", 0x0A
    db "    1)  to_upper   -- convert a-z letters to A-Z", 0x0A
    db "    2)  reverse    -- reverse string in place", 0x0A
    db "    3)  char count -- letters / digits / spaces / specials", 0x0A
    db "    4)  search     -- find a keyword in the log", 0x0A
    db "    0)  Back to log select", 0x0A
ohdr_len    equ $ - ohdr_s
oprompt_s   db  "  Choice: "
oprompt_len equ $ - oprompt_s

; ── Before / after labels ────────────────────────────────────
sbefore_s   db  "  Before: "
sbefore_len equ $ - sbefore_s
safter_s    db  "  After:  "
safter_len  equ $ - safter_s

; ── char_count display labels ────────────────────────────────
sletters_s   db  "  Letters:  "
sletters_len  equ $ - sletters_s
sdigits_s    db  "  Digits:   "
sdigits_len   equ $ - sdigits_s
sspaces_s    db  "  Spaces:   "
sspaces_len   equ $ - sspaces_s
sspecials_s  db  "  Specials: "
sspecials_len equ $ - sspecials_s
stotal_s     db  "  Total:    "
stotal_len    equ $ - stotal_s

; ── Keyword search display ───────────────────────────────────
skwprompt_s   db  "  Keyword: "
skwprompt_len equ $ - skwprompt_s
sfound1_s     db  '  Found "', 0
sfound1_len   equ $ - sfound1_s - 1      ; exclude NUL (using print_zstr)
sfound2_s     db  0x22, " at offset "    ; closing quote + label
sfound2_len   equ $ - sfound2_s
snfound1_s    db  "  ", 0x22             ; leading two spaces + open quote
snfound1_len  equ $ - snfound1_s
snfound2_s    db  0x22, " not found in log.", 0x0A
snfound2_len  equ $ - snfound2_s

; ── Miscellaneous ────────────────────────────────────────────
sinvalid_s   db  "  Invalid choice.", 0x0A
sinvalid_len equ $ - sinvalid_s
sbye_s       db  0x0A, "  Goodbye.", 0x0A, 0x0A
sbye_len     equ $ - sbye_s
nl           db  0x0A

section .bss
    workbuf      resb 256    ; mutable working copy of current log
    snapbuf      resb 256    ; snapshot before each op (for before/after display)
    keybuf       resb 64     ; keyword entered by user
    cnt_letters  resq 1      ; char_count: letter total
    cnt_digits   resq 1      ; char_count: digit total
    cnt_spaces   resq 1      ; char_count: space total
    cnt_specials resq 1      ; char_count: special-character total
    numbuf       resb 24     ; scratch buffer for print_uint_noeol

section .text
    global _start

; ──────────────────────────────────────────────────────────────
; to_upper(buf: rdi)
;
; Scans NUL-terminated string byte by byte.  For each byte in
; ['a'..'z'] subtracts 32 to shift to the uppercase range ['A'..'Z'].
; All other bytes (digits, punctuation, NUL) are unchanged.
;
; No callee-saved registers needed: only rdi (pointer) and eax
; (current byte) are used, both caller-saved.
; ──────────────────────────────────────────────────────────────
to_upper:
.tu_loop:
    movzx eax, byte [rdi]
    test  eax, eax
    jz    .tu_done
    cmp   eax, 'a'
    jb    .tu_next
    cmp   eax, 'z'
    ja    .tu_next
    sub   eax, 32             ; 'a'(97) - 32 = 'A'(65)
    mov   [rdi], al
.tu_next:
    inc   rdi
    jmp   .tu_loop
.tu_done:
    ret

; ──────────────────────────────────────────────────────────────
; str_rev(buf: rdi)
;
; Reverses the NUL-terminated string buf in place using a
; two-pointer swap: left starts at buf[0], right at buf[len-1];
; bytes are exchanged and the pointers advance inward until they
; meet or cross.
;
; Callee-saved: rbx (left pointer), r12 (right pointer).
; Caller-saved: rdx (length counter), al/cl (swap bytes).
; ──────────────────────────────────────────────────────────────
str_rev:
    push rbx
    push r12
    xor  rdx, rdx            ; length = 0
.sr_flen:
    cmp  byte [rdi + rdx], 0
    je   .sr_rev
    inc  rdx
    jmp  .sr_flen
.sr_rev:
    test rdx, rdx
    jz   .sr_done            ; empty string — nothing to reverse
    mov  rbx, rdi            ; left  pointer = &buf[0]
    lea  r12, [rdi + rdx - 1]; right pointer = &buf[len-1]
.sr_swap:
    cmp  rbx, r12
    jge  .sr_done            ; pointers crossed — done
    mov  al,  [rbx]          ; al = left byte
    mov  cl,  [r12]          ; cl = right byte
    mov  [rbx], cl
    mov  [r12], al
    inc  rbx
    dec  r12
    jmp  .sr_swap
.sr_done:
    pop  r12
    pop  rbx
    ret

; ──────────────────────────────────────────────────────────────
; char_count(buf: rdi)
;
; Scans buf and classifies each byte into one of four groups:
;   letters  : A-Z, a-z
;   digits   : 0-9
;   spaces   : 0x20 (ASCII space)
;   specials : anything else (punctuation, colons, brackets …)
;
; Results are written to the global BSS variables:
;   cnt_letters, cnt_digits, cnt_spaces, cnt_specials
;
; No callee-saved registers needed: only rdi and eax are used.
; ──────────────────────────────────────────────────────────────
char_count:
    mov  qword [cnt_letters],  0
    mov  qword [cnt_digits],   0
    mov  qword [cnt_spaces],   0
    mov  qword [cnt_specials], 0
.cc_loop:
    movzx eax, byte [rdi]
    test  eax, eax
    jz    .cc_done
    inc   rdi
    cmp   eax, 'A'
    jb    .cc_chk_lower
    cmp   eax, 'Z'
    jbe   .cc_letter
.cc_chk_lower:
    cmp   eax, 'a'
    jb    .cc_chk_digit
    cmp   eax, 'z'
    jbe   .cc_letter
.cc_chk_digit:
    cmp   eax, '0'
    jb    .cc_chk_space
    cmp   eax, '9'
    jbe   .cc_digit
.cc_chk_space:
    cmp   eax, ' '
    je    .cc_space
    inc   qword [cnt_specials]
    jmp   .cc_loop
.cc_letter:
    inc   qword [cnt_letters]
    jmp   .cc_loop
.cc_digit:
    inc   qword [cnt_digits]
    jmp   .cc_loop
.cc_space:
    inc   qword [cnt_spaces]
    jmp   .cc_loop
.cc_done:
    ret

; ──────────────────────────────────────────────────────────────
; kw_search(hay: rdi, needle: rsi) → rax
;
; Brute-force O(|hay| × |needle|) substring search.
; Outer loop advances a position i through the haystack.
; Inner loop compares needle[0..len-1] with hay[i..i+len-1].
; Returns byte offset of first match, or -1 if not found.
; Returns 0 for an empty needle (found at position 0).
;
; Callee-saved: rbx (outer index i), r12 (needle length).
; Caller-saved: rcx (inner offset j), al/dl (comparison bytes).
; ──────────────────────────────────────────────────────────────
kw_search:
    push rbx
    push r12
    xor  r12, r12            ; needle length = 0
.ks_nlen:
    cmp  byte [rsi + r12], 0
    je   .ks_nlen_done
    inc  r12
    jmp  .ks_nlen
.ks_nlen_done:
    test r12, r12
    jz   .ks_found_zero      ; empty needle: return 0
    xor  rbx, rbx            ; outer index i = 0
.ks_outer:
    cmp  byte [rdi + rbx], 0 ; end of haystack?
    je   .ks_notfound
    xor  rcx, rcx            ; inner offset j = 0
.ks_inner:
    cmp  rcx, r12
    je   .ks_found           ; all needle bytes matched
    lea  r8,  [rdi + rbx]        ; r8 = &hay[i]  (r8: caller-saved)
    mov  al,  [r8 + rcx]        ; hay[i+j]
    mov  dl,  [rsi + rcx]        ; needle[j]
    cmp  al,  dl
    jne  .ks_next_pos
    inc  rcx
    jmp  .ks_inner
.ks_next_pos:
    inc  rbx
    jmp  .ks_outer
.ks_notfound:
    mov  rax, -1
    jmp  .ks_done
.ks_found_zero:
    xor  rax, rax
    jmp  .ks_done
.ks_found:
    mov  rax, rbx
.ks_done:
    pop  r12
    pop  rbx
    ret

; ──────────────────────────────────────────────────────────────
; copy_str(dst: rdi, src: rsi)
;   Copies NUL-terminated string from rsi to rdi, including NUL.
;   Uses only al (rax low byte) — caller-saved, no push required.
; ──────────────────────────────────────────────────────────────
copy_str:
.cps_loop:
    mov  al,  [rsi]
    mov  [rdi], al
    test al,  al
    jz   .cps_done
    inc  rdi
    inc  rsi
    jmp  .cps_loop
.cps_done:
    ret

; ──────────────────────────────────────────────────────────────
; print_str — sys_write(1, rsi, rdx)
;   Saves rax and rdi around the syscall.
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
; print_zstr — print NUL-terminated string at rsi
;   Computes length then calls print_str.
;   Saves rbx (string pointer — callee-saved).
;   Uses rdx (length counter — caller-saved).
; ──────────────────────────────────────────────────────────────
print_zstr:
    push rbx
    mov  rbx, rsi
    xor  rdx, rdx
.pz_loop:
    cmp  byte [rbx + rdx], 0
    je   .pz_print
    inc  rdx
    jmp  .pz_loop
.pz_print:
    test rdx, rdx
    jz   .pz_done
    mov  rsi, rbx
    call print_str
.pz_done:
    pop  rbx
    ret

; ──────────────────────────────────────────────────────────────
; print_uint — print rax as unsigned decimal followed by newline
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
;   Saves rbx, rcx, rdx, rdi.
; ──────────────────────────────────────────────────────────────
print_uint_noeol:
    push rbx
    push rcx
    push rdx
    push rdi
    test rax, rax
    jnz  .pun_nonzero
    lea  rsi, [numbuf]
    mov  byte [rsi], '0'
    mov  rdx, 1
    call print_str
    jmp  .pun_done
.pun_nonzero:
    mov  rbx, 10
    xor  rcx, rcx
    lea  rdi, [numbuf + 23]
.pun_digit:
    xor  rdx, rdx
    div  rbx
    add  dl, '0'
    mov  [rdi], dl
    dec  rdi
    inc  rcx
    test rax, rax
    jnz  .pun_digit
    inc  rdi
    mov  rsi, rdi
    mov  rdx, rcx
    call print_str
.pun_done:
    pop  rdi
    pop  rdx
    pop  rcx
    pop  rbx
    ret

; ──────────────────────────────────────────────────────────────
; read_uint — read unsigned decimal integer from stdin → rax
;
; Reads one byte at a time so that exactly one line of input is
; consumed per call — required for correct behaviour when stdin
; is a pipe (a bulk sys_read would swallow multiple lines).
;
; Reads until '\n' or EOF.  Non-digit bytes before the first digit
; are skipped (handles any leading whitespace); non-digit bytes
; after digits terminate the parse.  Returns 0 for an empty line.
;
; Callee-saved: rbx (raw byte), r12 (accumulator).
; Caller-saved: rdi (stdin fd 0) — clobbered by syscall setup.
; ──────────────────────────────────────────────────────────────
read_uint:
    push rbx
    push r12
    xor  r12, r12            ; result = 0
.ru_loop:
    sub  rsp, 8              ; single-byte scratch on stack
    mov  rax, 0              ; sys_read
    mov  rdi, 0              ; stdin
    mov  rsi, rsp
    mov  rdx, 1
    syscall
    cmp  rax, 0
    jle  .ru_eof             ; EOF or error
    movzx ebx, byte [rsp]
    add  rsp, 8
    cmp  ebx, 0x0A           ; newline → end of input
    je   .ru_done
    cmp  ebx, '0'
    jb   .ru_loop            ; skip non-digit (whitespace etc.)
    cmp  ebx, '9'
    ja   .ru_loop            ; skip non-digit
    sub  ebx, '0'
    imul r12, r12, 10
    add  r12, rbx
    jmp  .ru_loop
.ru_eof:
    add  rsp, 8              ; balance the sub before returning
.ru_done:
    mov  rax, r12
    pop  r12
    pop  rbx
    ret

; ──────────────────────────────────────────────────────────────
; read_line(buf: rdi, maxlen: rsi) → rax = byte count (no \n)
;
; Reads one byte at a time, stopping at '\n' or EOF.
; Null-terminates the buffer and returns the character count.
;
; Callee-saved: rbx (buf pointer), r12 (maxlen), r13 (count).
; ──────────────────────────────────────────────────────────────
read_line:
    push rbx
    push r12
    push r13
    mov  rbx, rdi            ; buf
    mov  r12, rsi            ; maxlen
    xor  r13, r13            ; count = 0
.rl_loop:
    cmp  r13, r12
    jge  .rl_done            ; buffer full — stop
    sub  rsp, 8
    mov  rax, 0              ; sys_read
    mov  rdi, 0              ; stdin
    mov  rsi, rsp
    mov  rdx, 1
    syscall
    cmp  rax, 0
    jle  .rl_eof             ; EOF or error
    movzx eax, byte [rsp]
    add  rsp, 8
    cmp  eax, 0x0A           ; newline → stop
    je   .rl_done
    mov  [rbx + r13], al
    inc  r13
    jmp  .rl_loop
.rl_eof:
    add  rsp, 8
.rl_done:
    mov  byte [rbx + r13], 0 ; null-terminate
    mov  rax, r13
    pop  r13
    pop  r12
    pop  rbx
    ret

; ──────────────────────────────────────────────────────────────
; _start — main driver
;
; Register usage across loops (all callee-saved):
;   r12 = log select choice (1-5, kept through ops loop)
;   r13 = operation choice (1-4, set per iteration of ops loop)
;   r15 = kw_search result (offset or -1)
; ──────────────────────────────────────────────────────────────
_start:
    mov  rsi, banner_s
    mov  rdx, banner_len
    call print_str

; ── MAIN LOOP: pick a log ─────────────────────────────────────
.main_loop:
    mov  rsi, mhdr_s
    mov  rdx, mhdr_len
    call print_str
    mov  rsi, ml1_s
    mov  rdx, ml1_len
    call print_str
    mov  rsi, ml2_s
    mov  rdx, ml2_len
    call print_str
    mov  rsi, ml3_s
    mov  rdx, ml3_len
    call print_str
    mov  rsi, ml4_s
    mov  rdx, ml4_len
    call print_str
    mov  rsi, ml5_s
    mov  rdx, ml5_len
    call print_str
    mov  rsi, ml0_s
    mov  rdx, ml0_len
    call print_str
    mov  rsi, mprompt_s
    mov  rdx, mprompt_len
    call print_str
    call read_uint
    mov  r12, rax            ; r12 = log choice (1-5 or 0)

    test r12, r12
    jz   .exit
    cmp  r12, 5
    ja   .bad_log

    ; copy chosen log string into workbuf
    mov  rcx, r12
    dec  rcx                 ; 0-indexed into log_tbl
    mov  rsi, [log_tbl + rcx*8]
    lea  rdi, [workbuf]
    call copy_str

; ── OPS LOOP: pick an operation ───────────────────────────────
.ops_loop:
    ; show current state of workbuf
    mov  rsi, scurr_s
    mov  rdx, scurr_len
    call print_str
    lea  rsi, [workbuf]
    call print_zstr
    mov  rsi, nl
    mov  rdx, 1
    call print_str

    ; show operations menu
    mov  rsi, ohdr_s
    mov  rdx, ohdr_len
    call print_str
    mov  rsi, oprompt_s
    mov  rdx, oprompt_len
    call print_str
    call read_uint
    mov  r13, rax            ; r13 = op choice

    test r13, r13
    jz   .main_loop
    cmp  r13, 1
    je   .op_toupper
    cmp  r13, 2
    je   .op_reverse
    cmp  r13, 3
    je   .op_count
    cmp  r13, 4
    je   .op_search
    mov  rsi, sinvalid_s
    mov  rdx, sinvalid_len
    call print_str
    jmp  .ops_loop

; ── Op 1: to_upper ────────────────────────────────────────────
.op_toupper:
    lea  rdi, [snapbuf]      ; snapshot before
    lea  rsi, [workbuf]
    call copy_str
    lea  rdi, [workbuf]
    call to_upper
    mov  rsi, sbefore_s
    mov  rdx, sbefore_len
    call print_str
    lea  rsi, [snapbuf]
    call print_zstr
    mov  rsi, nl
    mov  rdx, 1
    call print_str
    mov  rsi, safter_s
    mov  rdx, safter_len
    call print_str
    lea  rsi, [workbuf]
    call print_zstr
    mov  rsi, nl
    mov  rdx, 1
    call print_str
    jmp  .ops_loop

; ── Op 2: reverse ─────────────────────────────────────────────
.op_reverse:
    lea  rdi, [snapbuf]
    lea  rsi, [workbuf]
    call copy_str
    lea  rdi, [workbuf]
    call str_rev
    mov  rsi, sbefore_s
    mov  rdx, sbefore_len
    call print_str
    lea  rsi, [snapbuf]
    call print_zstr
    mov  rsi, nl
    mov  rdx, 1
    call print_str
    mov  rsi, safter_s
    mov  rdx, safter_len
    call print_str
    lea  rsi, [workbuf]
    call print_zstr
    mov  rsi, nl
    mov  rdx, 1
    call print_str
    jmp  .ops_loop

; ── Op 3: char_count ──────────────────────────────────────────
.op_count:
    lea  rdi, [workbuf]
    call char_count
    mov  rsi, sletters_s
    mov  rdx, sletters_len
    call print_str
    mov  rax, [cnt_letters]
    call print_uint
    mov  rsi, sdigits_s
    mov  rdx, sdigits_len
    call print_str
    mov  rax, [cnt_digits]
    call print_uint
    mov  rsi, sspaces_s
    mov  rdx, sspaces_len
    call print_str
    mov  rax, [cnt_spaces]
    call print_uint
    mov  rsi, sspecials_s
    mov  rdx, sspecials_len
    call print_str
    mov  rax, [cnt_specials]
    call print_uint
    mov  rsi, stotal_s
    mov  rdx, stotal_len
    call print_str
    mov  rax, [cnt_letters]
    add  rax, [cnt_digits]
    add  rax, [cnt_spaces]
    add  rax, [cnt_specials]
    call print_uint
    jmp  .ops_loop

; ── Op 4: keyword search ──────────────────────────────────────
.op_search:
    mov  rsi, skwprompt_s
    mov  rdx, skwprompt_len
    call print_str
    lea  rdi, [keybuf]
    mov  rsi, 63
    call read_line
    test rax, rax
    jz   .ops_loop           ; empty keyword — skip
    lea  rdi, [workbuf]
    lea  rsi, [keybuf]
    call kw_search
    mov  r15, rax            ; r15 = offset or -1 (callee-saved: safe across prints)
    cmp  r15, -1
    je   .ks_not_found
    ; found: print  Found "keyword" at offset N
    mov  rsi, sfound1_s
    mov  rdx, sfound1_len
    call print_str
    lea  rsi, [keybuf]
    call print_zstr
    mov  rsi, sfound2_s
    mov  rdx, sfound2_len
    call print_str
    mov  rax, r15
    call print_uint
    jmp  .ops_loop
.ks_not_found:
    ; print  "keyword" not found in log.
    mov  rsi, snfound1_s
    mov  rdx, snfound1_len
    call print_str
    lea  rsi, [keybuf]
    call print_zstr
    mov  rsi, snfound2_s
    mov  rdx, snfound2_len
    call print_str
    jmp  .ops_loop

; ── Exit paths ────────────────────────────────────────────────
.bad_log:
    mov  rsi, sinvalid_s
    mov  rdx, sinvalid_len
    call print_str
    jmp  .main_loop

.exit:
    mov  rsi, sbye_s
    mov  rdx, sbye_len
    call print_str
    mov  rax, 60             ; sys_exit
    xor  rdi, rdi
    syscall
