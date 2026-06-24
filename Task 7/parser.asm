; ============================================================
; parser.asm — Task 7: File-Based Sensor Data Parser
; BIT 4220 Assembly Programming | x86-64 Linux NASM
; Usage: ./parser <filename>
;
; Opens the named file, reads it into a 4096-byte buffer, parses
; newline-separated unsigned decimal integers, then prints:
;   Records, Sum, Min, Max, Average (integer).
;
; System calls:
;   sys_read  (0)  read(fd, buf, n) → bytes
;   sys_write (1)  write(1, buf, n)
;   sys_open  (2)  open(path, O_RDONLY) → fd
;   sys_close (3)  close(fd)
;   sys_exit  (60) exit(code)
;
; Register map across _start (all callee-saved or unused after parse):
;   r15 = argv[1]  filename pointer
;   r12 = fd (open→close), then accumulator (-1 = no digits pending)
;   r13 = bytes read from file
;   r14 = parse index (0 … r13-1)
;   rbx = record count
;   r8  = sum
;   r9  = min  (seeded from first record)
;   r10 = max  (seeded from first record)
; ============================================================

section .data

s_banner:
    db 0x0A, "=== Sensor Data Parser ===", 0x0A
s_bannerlen equ $ - s_banner
s_file_lbl  db "File:     "
s_file_len  equ $ - s_file_lbl
s_rec_lbl   db "Records:  "
s_rec_len   equ $ - s_rec_lbl
s_sum_lbl   db "Sum:      "
s_sum_len   equ $ - s_sum_lbl
s_min_lbl   db "Min:      "
s_min_len   equ $ - s_min_lbl
s_max_lbl   db "Max:      "
s_max_len   equ $ - s_max_lbl
s_avg_lbl   db "Average:  "
s_avg_len   equ $ - s_avg_lbl
s_norec     db "  (no numeric readings found)", 0x0A
s_norec_len equ $ - s_norec
s_err_open  db "Error: cannot open file.", 0x0A
s_err_len   equ $ - s_err_open
s_usage     db "Usage: parser <filename>", 0x0A
s_usage_len equ $ - s_usage
nl          db 0x0A

section .bss
    filebuf  resb 4096   ; entire file read here in one sys_read
    numbuf   resb 24     ; scratch for decimal-to-ASCII conversion

section .text
    global _start

; ──────────────────────────────────────────────────────────────
; print_str — sys_write(1, rsi, rdx)
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
; ──────────────────────────────────────────────────────────────
print_zstr:
    push rbx
    mov  rbx, rsi
    xor  rdx, rdx
.pz_len:
    cmp  byte [rbx + rdx], 0
    je   .pz_go
    inc  rdx
    jmp  .pz_len
.pz_go:
    test rdx, rdx
    jz   .pz_done
    mov  rsi, rbx
    call print_str
.pz_done:
    pop  rbx
    ret

; ──────────────────────────────────────────────────────────────
; print_uint_noeol — print rax as unsigned decimal, no newline
; ──────────────────────────────────────────────────────────────
print_uint_noeol:
    push rbx
    push rcx
    push rdx
    push rdi
    test rax, rax
    jnz  .pu_nonzero
    lea  rsi, [numbuf]
    mov  byte [rsi], '0'
    mov  rdx, 1
    call print_str
    jmp  .pu_done
.pu_nonzero:
    mov  rbx, 10
    xor  rcx, rcx
    lea  rdi, [numbuf + 23]
.pu_dig:
    xor  rdx, rdx
    div  rbx
    add  dl, '0'
    mov  [rdi], dl
    dec  rdi
    inc  rcx
    test rax, rax
    jnz  .pu_dig
    inc  rdi
    mov  rsi, rdi
    mov  rdx, rcx
    call print_str
.pu_done:
    pop  rdi
    pop  rdx
    pop  rcx
    pop  rbx
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
; do_record — update stats with value in r12
;   Increments rbx (count), adds to r8 (sum),
;   seeds or updates r9 (min) and r10 (max).
;   Clobbers nothing beyond those four registers.
; ──────────────────────────────────────────────────────────────
do_record:
    inc  rbx
    add  r8,  r12
    cmp  rbx, 1
    jne  .dr_rest
    mov  r9,  r12            ; seed min from first value
    mov  r10, r12            ; seed max from first value
    ret
.dr_rest:
    cmp  r12, r9
    jge  .dr_no_min
    mov  r9,  r12
.dr_no_min:
    cmp  r12, r10
    jle  .dr_no_max
    mov  r10, r12
.dr_no_max:
    ret

; ──────────────────────────────────────────────────────────────
; _start
; ──────────────────────────────────────────────────────────────
_start:
    ; ── Check argument count ────────────────────────────────
    mov  rax, [rsp]
    cmp  rax, 2
    jl   .usage
    mov  r15, [rsp + 16]     ; r15 = filename (argv[1])

    ; ── sys_open: open(filename, O_RDONLY) ──────────────────
    mov  rax, 2
    mov  rdi, r15
    xor  rsi, rsi            ; O_RDONLY = 0
    xor  rdx, rdx
    syscall
    test rax, rax
    js   .open_error

    mov  r12, rax            ; r12 = fd

    ; ── sys_read: read(fd, filebuf, 4096) ───────────────────
    mov  rax, 0
    mov  rdi, r12
    lea  rsi, [filebuf]
    mov  rdx, 4096
    syscall
    ; clamp negative (I/O error) to zero
    test rax, rax
    jns  .read_ok
    xor  rax, rax
.read_ok:
    mov  r13, rax            ; r13 = bytes read

    ; ── sys_close: close(fd) ────────────────────────────────
    mov  rax, 3
    mov  rdi, r12
    syscall

    ; ── Initialise stats ────────────────────────────────────
    xor  rbx, rbx            ; count = 0
    xor  r8,  r8             ; sum   = 0
    xor  r9,  r9             ; min   (seeded by first record)
    xor  r10, r10            ; max   (seeded by first record)
    mov  r12, -1             ; accumulator sentinel (-1 = no digits pending)
    xor  r14, r14            ; parse index

    ; ── Parse loop ──────────────────────────────────────────
.parse:
    cmp  r14, r13
    jge  .flush
    movzx eax, byte [filebuf + r14]
    inc   r14
    cmp   eax, '0'
    jb    .sep
    cmp   eax, '9'
    ja    .sep
    ; digit: start or extend accumulator
    sub   eax, '0'
    cmp   r12, -1
    jne   .acc
    xor   r12, r12           ; first digit: clear sentinel
.acc:
    imul  r12, r12, 10
    add   r12, rax
    jmp   .parse
.sep:
    ; non-digit: commit pending number if any
    cmp   r12, -1
    je    .parse
    call  do_record
    mov   r12, -1
    jmp   .parse
.flush:
    ; file may end without a trailing newline
    cmp   r12, -1
    je    .print
    call  do_record

    ; ── Output ──────────────────────────────────────────────
.print:
    mov  rsi, s_banner
    mov  rdx, s_bannerlen
    call print_str

    mov  rsi, s_file_lbl
    mov  rdx, s_file_len
    call print_str
    mov  rsi, r15
    call print_zstr
    mov  rsi, nl
    mov  rdx, 1
    call print_str

    mov  rsi, s_rec_lbl
    mov  rdx, s_rec_len
    call print_str
    mov  rax, rbx
    call print_uint

    test rbx, rbx
    jz   .no_records

    mov  rsi, s_sum_lbl
    mov  rdx, s_sum_len
    call print_str
    mov  rax, r8
    call print_uint

    mov  rsi, s_min_lbl
    mov  rdx, s_min_len
    call print_str
    mov  rax, r9
    call print_uint

    mov  rsi, s_max_lbl
    mov  rdx, s_max_len
    call print_str
    mov  rax, r10
    call print_uint

    mov  rsi, s_avg_lbl
    mov  rdx, s_avg_len
    call print_str
    mov  rax, r8
    xor  rdx, rdx
    div  rbx                 ; rax = sum / count  (integer average)
    call print_uint
    jmp  .exit_ok

.no_records:
    mov  rsi, s_norec
    mov  rdx, s_norec_len
    call print_str

.exit_ok:
    mov  rax, 60
    xor  rdi, rdi
    syscall

.usage:
    mov  rsi, s_usage
    mov  rdx, s_usage_len
    call print_str
    mov  rax, 60
    mov  rdi, 1
    syscall

.open_error:
    mov  rsi, s_err_open
    mov  rdx, s_err_len
    call print_str
    mov  rax, 60
    mov  rdi, 2
    syscall
