; ============================================================
; alu.asm — Task 3: Mini ALU for Embedded Billing Device
; BIT 4220 Assembly Programming | x86-64 Linux
; ============================================================
;
; WHAT THIS PROGRAM DOES
;   Menu-driven ALU simulator modelling a prepaid utility meter's
;   low-level computation module.  Two 8-bit inputs (A, B: 0-255)
;   are read from the keyboard using Linux sys_read, then the
;   chosen operation is performed on AL / BL so x86 sets flags
;   exactly as they would appear in an 8-bit embedded register.
;   RFLAGS is captured with PUSHFQ immediately after each op and
;   the five most relevant bits are decoded and printed.
;
; OPERATIONS
;   Arithmetic : ADD (A+B), SUB (A-B), MUL (A*B), DIV (A/B)
;   Logical    : AND (A&B), OR (A|B), XOR (A^B), NOT (~A)
;   Shift      : SHL (A<<1),  SHR (A>>1)
;
; FLAGS DECODED
;   CF (bit  0) – Carry / Borrow    : unsigned overflow or borrow
;   PF (bit  2) – Parity            : even popcount in result's low byte
;   ZF (bit  6) – Zero              : result == 0
;   SF (bit  7) – Sign              : result MSB is 1 (negative in 2's-comp)
;   OF (bit 11) – Signed Overflow   : result exceeds signed range
;
; BUILD & RUN
;   nasm -f elf64 alu.asm -o alu.o && ld alu.o -o alu && ./alu
;   Or use:  ./run.sh
; ============================================================

section .data

hex_chars   db  "0123456789abcdef"

banner      db  0x0A
            db  "============================================", 0x0A
            db  "  Prepaid Meter ALU Simulator  v1.0       ", 0x0A
            db  "  BIT 4220 — Task 3                       ", 0x0A
            db  "============================================", 0x0A
bannerlen   equ $ - banner

menu_txt    db  0x0A
            db  "  --- Arithmetic ---    --- Logical/Shift ---", 0x0A
            db  "  1) ADD   A + B        5) AND   A & B      ", 0x0A
            db  "  2) SUB   A - B        6) OR    A | B      ", 0x0A
            db  "  3) MUL   A * B        7) XOR   A ^ B      ", 0x0A
            db  "  4) DIV   A / B        8) NOT   ~A         ", 0x0A
            db  "                        9) SHL   A << 1     ", 0x0A
            db  "                       10) SHR   A >> 1     ", 0x0A
            db  "  0) Exit", 0x0A
            db  0x0A
            db  "Choice: "
menutxtlen  equ $ - menu_txt

p_a         db  0x0A, "  Enter A (0-255): "
p_alen      equ $ - p_a

p_b         db  "  Enter B (0-255): "
p_blen      equ $ - p_b

res_lbl     db  0x0A, "  Result  : "
res_lbllen  equ $ - res_lbl

hex_lbl     db  "  (0x"
hex_lbllen  equ $ - hex_lbl

rparen      db  ")", 0x0A
rparenlen   equ $ - rparen

flg_hdr     db  "  Flags   : "
flg_hdrlen  equ $ - flg_hdr

lbl_cf      db  "CF="
lbl_cflen   equ $ - lbl_cf

lbl_pf      db  "  PF="
lbl_pflen   equ $ - lbl_pf

lbl_zf      db  "  ZF="
lbl_zflen   equ $ - lbl_zf

lbl_sf      db  "  SF="
lbl_sflen   equ $ - lbl_sf

lbl_of      db  "  OF="
lbl_oflen   equ $ - lbl_of

nl          db  0x0A

msg_div0    db  0x0A, "  ERROR: Division by zero!", 0x0A
msg_div0len equ $ - msg_div0

msg_oflow   db  "  *** SIGNED OVERFLOW (OF=1) — result exceeds 8-bit signed range ***", 0x0A
msg_oflowl  equ $ - msg_oflow

msg_inv     db  0x0A, "  Invalid choice. Please enter 0-10.", 0x0A
msg_invlen  equ $ - msg_inv

msg_bye     db  0x0A, "  Meter session ended. Goodbye!", 0x0A, 0x0A
msg_byelen  equ $ - msg_bye

; Informational notes for operations whose flag semantics need explanation
msg_div_note db  "  (DIV: CF/OF/SF/ZF/PF are UNDEFINED — values shown are CPU-specific)", 0x0A
msg_divnoteln equ $ - msg_div_note

msg_not_note db  "  (NOT does not modify flags; TEST rax,rax run after to reflect result)", 0x0A
msg_notnoteln equ $ - msg_not_note

msg_mul_note db  "  (MUL: CF=OF=1 because product > 255; PF/ZF/SF undefined per Intel ABI)", 0x0A
msg_mulnoteln equ $ - msg_mul_note

section .bss
    inbuf   resb 32         ; keyboard input buffer (1 byte at a time)
    hexbuf  resb 4          ; 2 hex digits scratch
    numbuf  resb 24         ; decimal-to-ASCII conversion scratch

section .text
    global _start

; ────────────────────────────────────────────────────────────────
_start:
    mov rsi, banner
    mov rdx, bannerlen
    call print_str

; ────────────────────────────────────────────────────────────────
menu_loop:
    mov rsi, menu_txt
    mov rdx, menutxtlen
    call print_str

    call read_uint              ; choice → rax

    cmp rax, 10
    ja  .bad_choice

    ; compare-chain dispatch  (rax validated 0-10)
    cmp rax, 0
    je  .op_exit
    cmp rax, 1
    je  .op_add
    cmp rax, 2
    je  .op_sub
    cmp rax, 3
    je  .op_mul
    cmp rax, 4
    je  .op_div
    cmp rax, 5
    je  .op_and
    cmp rax, 6
    je  .op_or
    cmp rax, 7
    je  .op_xor
    cmp rax, 8
    je  .op_not
    cmp rax, 9
    je  .op_shl
    jmp .op_shr                 ; must be 10

.bad_choice:
    mov rsi, msg_inv
    mov rdx, msg_invlen
    call print_str
    jmp menu_loop

.op_exit:
    mov rsi, msg_bye
    mov rdx, msg_byelen
    call print_str
    mov rax, 60                 ; sys_exit
    xor rdi, rdi                ; status 0
    syscall

; ── Two-operand operations ───────────────────────────────────────

.op_add:
    call get_ab                 ; rax=A (0-255), rbx=B (0-255)
    add al, bl                  ; 8-bit ADD — CF set on unsigned carry
    movzx rax, al               ; zero-extend result for printing
    pushfq
    pop r12                     ; r12 = RFLAGS after ADD
    call show_result
    jmp menu_loop

.op_sub:
    call get_ab
    sub al, bl                  ; 8-bit SUB — CF set on borrow (A < B)
    movzx rax, al
    pushfq
    pop r12
    call show_result
    jmp menu_loop

.op_mul:
    call get_ab
    mul bl                      ; 8-bit: AX = AL * BL; CF=OF=1 if AH != 0
    pushfq
    pop r12
    movzx rax, ax               ; full 16-bit product in rax for printing
    call show_result
    ; MUL of two ≤255 values: if product > 255, AH≠0 → CF=OF=1
    test r12, (1 << 11)
    jz  .mul_no_note
    mov rsi, msg_mul_note
    mov rdx, msg_mulnoteln
    call print_str
.mul_no_note:
    jmp menu_loop

.op_div:
    call get_ab
    test bl, bl                 ; divisor == 0?
    jnz .div_ok
    mov rsi, msg_div0
    mov rdx, msg_div0len
    call print_str
    jmp menu_loop
.div_ok:
    xor ah, ah                  ; AX = A (AH already 0 from get_a AND 0xFF)
    div bl                      ; AL = AX/BL (quotient), AH = remainder
    movzx rax, al               ; quotient for display
    pushfq
    pop r12
    call show_result
    mov rsi, msg_div_note       ; DIV flags are undefined
    mov rdx, msg_divnoteln
    call print_str
    jmp menu_loop

.op_and:
    call get_ab
    and al, bl                  ; CF=OF=0 always; ZF,SF,PF reflect result
    movzx rax, al
    pushfq
    pop r12
    call show_result
    jmp menu_loop

.op_or:
    call get_ab
    or  al, bl
    movzx rax, al
    pushfq
    pop r12
    call show_result
    jmp menu_loop

.op_xor:
    call get_ab
    xor al, bl
    movzx rax, al
    pushfq
    pop r12
    call show_result
    jmp menu_loop

; ── Single-operand operations ────────────────────────────────────

.op_not:
    call get_a                  ; rax = A (0-255)
    not al                      ; flip all 8 bits; does NOT touch RFLAGS
    and rax, 0xFF               ; keep 8-bit result, clear upper bits
    test rax, rax               ; sets ZF/SF/PF; clears CF/OF
    pushfq
    pop r12
    call show_result
    mov rsi, msg_not_note
    mov rdx, msg_notnoteln
    call print_str
    jmp menu_loop

.op_shl:
    call get_a
    shl al, 1                   ; CF = bit shifted out; OF reflects sign change
    movzx rax, al
    pushfq
    pop r12
    call show_result
    jmp menu_loop

.op_shr:
    call get_a
    shr al, 1                   ; CF = bit shifted out (logical shift, fills 0)
    movzx rax, al
    pushfq
    pop r12
    call show_result
    jmp menu_loop

; ────────────────────────────────────────────────────────────────
; get_ab — prompt and read A (→ rax) and B (→ rbx), both masked to 8 bits
; ────────────────────────────────────────────────────────────────
get_ab:
    call get_a                  ; rax = A (0-255)
    push rax                    ; save A across the B prompt

    mov rsi, p_b
    mov rdx, p_blen
    call print_str
    call read_uint              ; rax = B
    and rax, 0xFF
    mov rbx, rax                ; B → rbx

    pop rax                     ; A → rax
    ret

; ────────────────────────────────────────────────────────────────
; get_a — prompt and read A, return in rax masked to 8 bits
; ────────────────────────────────────────────────────────────────
get_a:
    mov rsi, p_a
    mov rdx, p_alen
    call print_str
    call read_uint
    and rax, 0xFF
    ret

; ────────────────────────────────────────────────────────────────
; show_result — print decimal + hex of rax, then decode flags in r12
;   Uses r13 to save the result across nested print calls.
;   r13 is callee-saved (System V ABI); we push/pop it explicitly.
; ────────────────────────────────────────────────────────────────
show_result:
    push r13
    mov r13, rax                ; save result

    ; "  Result  : <decimal>  (0x<hex>)"
    mov rsi, res_lbl
    mov rdx, res_lbllen
    call print_str

    mov rax, r13
    call print_uint_noeol       ; decimal, no newline

    mov rsi, hex_lbl
    mov rdx, hex_lbllen
    call print_str

    mov rax, r13
    call print_hex_byte         ; low 8 bits as 2 hex chars

    mov rsi, rparen
    mov rdx, rparenlen          ; includes newline
    call print_str

    ; signed-overflow warning
    test r12, (1 << 11)         ; OF = bit 11
    jz  .sr_no_oflow
    mov rsi, msg_oflow
    mov rdx, msg_oflowl
    call print_str
.sr_no_oflow:

    ; "  Flags   : CF=x  PF=x  ZF=x  SF=x  OF=x"
    mov rsi, flg_hdr
    mov rdx, flg_hdrlen
    call print_str

    mov rsi, lbl_cf
    mov rdx, lbl_cflen
    call print_str
    mov rax, r12
    and rax, 1                  ; CF = bit 0
    call print_bit

    mov rsi, lbl_pf
    mov rdx, lbl_pflen
    call print_str
    mov rax, r12
    shr rax, 2
    and rax, 1                  ; PF = bit 2
    call print_bit

    mov rsi, lbl_zf
    mov rdx, lbl_zflen
    call print_str
    mov rax, r12
    shr rax, 6
    and rax, 1                  ; ZF = bit 6
    call print_bit

    mov rsi, lbl_sf
    mov rdx, lbl_sflen
    call print_str
    mov rax, r12
    shr rax, 7
    and rax, 1                  ; SF = bit 7
    call print_bit

    mov rsi, lbl_of
    mov rdx, lbl_oflen
    call print_str
    mov rax, r12
    shr rax, 11
    and rax, 1                  ; OF = bit 11
    call print_bit

    mov rsi, nl
    mov rdx, 1
    call print_str

    pop r13
    ret

; ────────────────────────────────────────────────────────────────
; print_bit — write ASCII '0' or '1' depending on rax (0 = '0', else '1')
; ────────────────────────────────────────────────────────────────
print_bit:
    push rdi
    lea rdi, [inbuf]            ; 1-byte scratch in existing buffer
    test rax, rax
    jnz .pb_one
    mov byte [rdi], '0'
    jmp .pb_write
.pb_one:
    mov byte [rdi], '1'
.pb_write:
    mov rsi, rdi
    mov rdx, 1
    call print_str
    pop rdi
    ret

; ────────────────────────────────────────────────────────────────
; print_hex_byte — print low 8 bits of rax as exactly 2 hex digits
; ────────────────────────────────────────────────────────────────
print_hex_byte:
    push rbx
    push rcx
    lea rbx, [hexbuf]
    movzx rax, al               ; isolate low byte

    mov rcx, rax
    shr rcx, 4                  ; high nibble
    and rcx, 0xF
    lea rdx, [hex_chars]
    movzx rcx, byte [rdx + rcx]
    mov [rbx], cl

    mov rcx, rax
    and rcx, 0xF                ; low nibble
    movzx rcx, byte [rdx + rcx]
    mov [rbx + 1], cl

    mov rsi, rbx
    mov rdx, 2
    call print_str
    pop rcx
    pop rbx
    ret

; ────────────────────────────────────────────────────────────────
; print_uint_noeol — print rax as unsigned decimal, NO trailing newline
; ────────────────────────────────────────────────────────────────
print_uint_noeol:
    push rbx
    push rcx
    push rdx
    push rdi

    test rax, rax
    jnz .pun_nonzero
    lea rsi, [numbuf]
    mov byte [rsi], '0'
    mov rdx, 1
    call print_str
    jmp .pun_done

.pun_nonzero:
    mov rbx, 10
    xor rcx, rcx                ; digit count
    lea rdi, [numbuf + 23]      ; build string right-to-left
.pun_digit:
    xor rdx, rdx
    div rbx                     ; rdx = digit, rax = quotient
    add dl, '0'
    mov [rdi], dl
    dec rdi
    inc rcx
    test rax, rax
    jnz .pun_digit
    inc rdi                     ; rdi → first digit
    mov rsi, rdi
    mov rdx, rcx
    call print_str

.pun_done:
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret

; ────────────────────────────────────────────────────────────────
; print_str — sys_write(stdout, rsi, rdx)
;   Saves and restores rax and rdi. Syscall clobbers rcx and r11.
; ────────────────────────────────────────────────────────────────
print_str:
    push rax
    push rdi
    mov rax, 1                  ; sys_write
    mov rdi, 1                  ; fd = stdout
    syscall
    pop rdi
    pop rax
    ret

; ────────────────────────────────────────────────────────────────
; read_uint — read ASCII decimal digits from stdin, return value in rax
;   Reads one byte at a time until newline or EOF.
;   Non-digit characters are silently skipped (handles CR, spaces).
;   Syscall clobbers rcx and r11, so multiplier is an immediate.
; ────────────────────────────────────────────────────────────────
read_uint:
    push rbx
    push rsi
    push rdi

    xor rbx, rbx                ; accumulator = 0

.ru_next:
    mov rax, 0                  ; sys_read
    mov rdi, 0                  ; fd = stdin
    lea rsi, [inbuf]
    mov rdx, 1
    syscall                     ; clobbers rcx, r11 — so we use imul below
    test rax, rax
    jle .ru_done                ; EOF or error

    movzx rax, byte [inbuf]
    cmp al, 0x0A                ; LF — end of input
    je  .ru_done
    cmp al, 0x0D                ; CR — ignore
    je  .ru_next
    cmp al, '0'
    jb  .ru_next                ; skip non-digit
    cmp al, '9'
    ja  .ru_next

    sub al, '0'                 ; digit value 0-9
    push rax                    ; save digit
    imul rbx, rbx, 10          ; accum * 10  (no rdx clobber unlike MUL)
    pop rax
    add rbx, rax                ; accum = accum*10 + digit
    jmp .ru_next

.ru_done:
    mov rax, rbx                ; return value

    pop rdi
    pop rsi
    pop rbx
    ret
