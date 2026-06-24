; ============================================================
; portfolio.asm — Task 10: IoT Sensor Log Analyser
; BIT 4220 Assembly Programming | Group Work
;
; Theme: IoT / Embedded Data Processing
;
; Integrates three prior modules:
;   Task 7 — file I/O  (sys_open / sys_read / sys_close)
;   Task 6 — keyword search  (scan each line for "TEMP:")
;   Task 8 — statistics engine  (count / sum / min / max / avg)
;
; Usage:  ./portfolio sensors.log
; ============================================================

; ── syscall numbers ──────────────────────────────────────────
SYS_READ    equ 0
SYS_WRITE   equ 1
SYS_OPEN    equ 2
SYS_CLOSE   equ 3
SYS_EXIT    equ 60
O_RDONLY    equ 0

section .data

s_banner    db 0x0A, "=== IoT Sensor Log Analyser ===", 0x0A
s_bannerlen equ $ - s_banner

s_file      db "File:    "
s_filelen   equ $ - s_file

s_records   db "Records: "
s_reclen    equ $ - s_records

s_sum       db "Sum:     "
s_sumlen    equ $ - s_sum

s_min       db "Min:     "
s_minlen    equ $ - s_min

s_max       db "Max:     "
s_maxlen    equ $ - s_max

s_avg       db "Average: "
s_avglen    equ $ - s_avg

s_nodata    db "  (no TEMP readings found)", 0x0A
s_nodatalen equ $ - s_nodata

s_err       db "Error: cannot open file.", 0x0A
s_errlen    equ $ - s_err

nl          db  0x0A

section .bss
    filebuf resb 4096
    numbuf  resb 24

section .text
    global _start

; ── print_str ────────────────────────────────────────────────
; in:  rsi = pointer, rdx = length
print_str:
    push rax
    push rdi
    mov  rax, SYS_WRITE
    mov  rdi, 1
    syscall
    pop  rdi
    pop  rax
    ret

; ── print_filename ───────────────────────────────────────────
; Prints a null-terminated string followed by newline.
; in:  rdi = pointer to null-terminated string
print_filename:
    push rbx
    push rcx
    xor  rcx, rcx
.pfn_len:
    cmp  byte [rdi + rcx], 0
    je   .pfn_print
    inc  rcx
    jmp  .pfn_len
.pfn_print:
    mov  rsi, rdi
    mov  rdx, rcx
    call print_str
    mov  rsi, nl
    mov  rdx, 1
    call print_str
    pop  rcx
    pop  rbx
    ret

; ── print_uint_noeol ─────────────────────────────────────────
; in:  rax = unsigned 64-bit integer
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

; ── print_uint ───────────────────────────────────────────────
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

; ════════════════════════════════════════════════════════════
; _start
; Register map:
;   r15 = argv[1] (filename)
;   r13 = bytes read into filebuf
;   r14 = current index into filebuf
;   rbx = record count
;   r8  = sum
;   r9  = min  (init = INT64_MAX)
;   r10 = max
; ════════════════════════════════════════════════════════════
_start:

    ; ── Check argc ────────────────────────────────────────
    mov  rax, [rsp]          ; argc
    cmp  rax, 2
    jl   .usage_error

    ; ── Open file (Task 7 pattern) ────────────────────────
    mov  r15, [rsp + 16]     ; argv[1]
    mov  rax, SYS_OPEN
    mov  rdi, r15
    xor  rsi, rsi            ; O_RDONLY
    xor  rdx, rdx
    syscall
    test rax, rax
    js   .open_error

    ; ── Read entire file into filebuf ─────────────────────
    mov  r12, rax            ; save fd
    mov  rax, SYS_READ
    mov  rdi, r12
    lea  rsi, [filebuf]
    mov  rdx, 4096
    syscall
    test rax, rax
    jns  .read_ok
    xor  rax, rax
.read_ok:
    mov  r13, rax            ; bytes read

    ; ── Close fd (Task 7 pattern) ─────────────────────────
    mov  rax, SYS_CLOSE
    mov  rdi, r12
    syscall

    ; ── Initialise statistics (Task 8 pattern) ────────────
    xor  rbx, rbx            ; count = 0
    xor  r8,  r8             ; sum   = 0
    mov  r9,  0x7FFFFFFFFFFFFFFF   ; min = INT64_MAX
    xor  r10, r10            ; max   = 0
    xor  r14, r14            ; index = 0

    ; ── Scan loop: keyword filter + number extraction ─────
    ; (inspired by Task 6 kw_search and Task 7 parse loop)
.scan:
    cmp  r14, r13
    jge  .print_results

    ; need 5 bytes ahead to test "TEMP:"
    mov  rax, r14
    add  rax, 5
    cmp  rax, r13
    ja   .advance_one        ; fewer than 5 bytes left — skip

    ; test T E M P :
    lea  rdi, [filebuf + r14]
    cmp  byte [rdi],   'T'
    jne  .advance_one
    cmp  byte [rdi+1], 'E'
    jne  .advance_one
    cmp  byte [rdi+2], 'M'
    jne  .advance_one
    cmp  byte [rdi+3], 'P'
    jne  .advance_one
    cmp  byte [rdi+4], ':'
    jne  .advance_one

    ; ── Found "TEMP:" — advance past keyword ──────────────
    add  r14, 5

    ; ── Parse decimal digits following the colon ──────────
    xor  rcx, rcx            ; value accumulator
    xor  rdx, rdx            ; digit count
.parse_digit:
    cmp  r14, r13
    jge  .commit
    movzx eax, byte [filebuf + r14]
    cmp  al, '0'
    jb   .commit
    cmp  al, '9'
    ja   .commit
    imul rcx, rcx, 10
    sub  al,  '0'
    movzx rax, al
    add  rcx, rax
    inc  r14
    inc  rdx
    jmp  .parse_digit

.commit:
    test rdx, rdx            ; any digits found?
    jz   .skip_to_nl

    ; ── Update statistics ─────────────────────────────────
    inc  rbx                 ; count++
    add  r8,  rcx            ; sum += val

    cmp  rcx, r9             ; update min? (Task 8 Bug-2 fix: proper sentinel)
    jge  .no_min
    mov  r9,  rcx
.no_min:
    cmp  rcx, r10            ; update max? (Task 8 Bug-5 fix: jle = skip when ≤)
    jle  .no_max
    mov  r10, rcx
.no_max:

    ; ── Skip rest of line after recording value ───────────
.skip_to_nl:
    cmp  r14, r13
    jge  .print_results
    movzx eax, byte [filebuf + r14]
    inc  r14
    cmp  al, 0x0A
    jne  .skip_to_nl
    jmp  .scan

.advance_one:
    inc  r14
    jmp  .scan

    ; ── Print results ─────────────────────────────────────
.print_results:
    mov  rsi, s_banner
    mov  rdx, s_bannerlen
    call print_str

    mov  rsi, s_file
    mov  rdx, s_filelen
    call print_str
    mov  rdi, r15
    call print_filename

    mov  rsi, s_records
    mov  rdx, s_reclen
    call print_str
    mov  rax, rbx
    call print_uint

    test rbx, rbx
    jz   .no_readings

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
    div  rbx                 ; average = sum / count
    call print_uint

    mov  rax, SYS_EXIT
    xor  rdi, rdi
    syscall

.no_readings:
    mov  rsi, s_nodata
    mov  rdx, s_nodatalen
    call print_str
    mov  rax, SYS_EXIT
    xor  rdi, rdi
    syscall

.open_error:
    mov  rax, SYS_WRITE
    mov  rdi, 2              ; stderr
    mov  rsi, s_err
    mov  rdx, s_errlen
    syscall
    mov  rax, SYS_EXIT
    mov  rdi, 2
    syscall

.usage_error:
    mov  rax, SYS_WRITE
    mov  rdi, 2
    mov  rsi, s_err
    mov  rdx, s_errlen
    syscall
    mov  rax, SYS_EXIT
    mov  rdi, 1
    syscall
