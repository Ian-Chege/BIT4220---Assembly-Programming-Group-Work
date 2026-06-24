; ============================================================
; sizes.asm — Task 1.2: Bytes, Words & Doublewords (x86-64 Linux)
; BIT 4220 Assembly Programming | Group Work Session 1
; ============================================================
;
; GOAL: show the three basic data SIZES the CPU works with, and prove
; that a "number" and a "letter" are the same bytes underneath (ASCII).
;
;   db = define byte       -> 1 byte  (8 bits)
;   dw = define word       -> 2 bytes (16 bits)
;   dd = define doubleword -> 4 bytes (32 bits)
;
; KEY IDEA — ASCII: every letter has a number.
;   0x41 = 65 = 'A'      0x42 = 'B'      0x43 = 'C'      0x44 = 'D'
;
; KEY IDEA — LITTLE-ENDIAN: x86 stores multi-byte numbers BACKWARDS in
; memory (lowest byte first). So the word 0x4241, written big-to-small as
; "42 41", is actually stored in memory as the bytes  41 42  -> prints "AB".
; ============================================================

section .data
    ; ── Headings (plain text we print before each value) ──────
    hdr      db  "=== Task 1.2: data sizes & ASCII ===", 0x0A, 0x0A
    hdrlen   equ $ - hdr

    bmsg     db  "Byte  (db) 0x41         -> ASCII: ", 0
    bmsglen  equ $ - bmsg - 1            ; -1 so we don't print the 0 terminator

    wmsg     db  "Word  (dw) 0x4241       -> ASCII: ", 0
    wmsglen  equ $ - wmsg - 1

    dmsg     db  "Dword (dd) 0x44434241   -> ASCII: ", 0
    dmsglen  equ $ - dmsg - 1

    nl       db  0x0A                     ; a single newline byte

    ; ── The actual DATA, one of each size ─────────────────────
    ; The CPU stores these in little-endian (reversed) order in memory,
    ; which is exactly what makes the letters come out in reading order.
    myByte   db  0x41                     ; in memory: 41             -> "A"
    myWord   dw  0x4241                   ; in memory: 41 42          -> "AB"
    myDword  dd  0x44434241               ; in memory: 41 42 43 44    -> "ABCD"

section .bss
    ; (required by the task spec; unused here)
    unused   resb 1

section .text
    global _start

; ------------------------------------------------------------
; Tiny reminder of the "print" recipe (Linux write syscall):
;   rax = 1   (service: write)
;   rdi = 1   (destination: stdout / the screen)
;   rsi = address of the bytes to print
;   rdx = how many bytes to print
;   syscall   (ask the kernel to do it)
; ------------------------------------------------------------
_start:
    ; ── Print the header ──────────────────────────────────────
    mov rax, 1
    mov rdi, 1
    mov rsi, hdr
    mov rdx, hdrlen
    syscall

    ; ── BYTE: print label, then the 1 byte, then a newline ────
    mov rax, 1
    mov rdi, 1
    mov rsi, bmsg
    mov rdx, bmsglen
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, myByte         ; point at our 1 byte
    mov rdx, 1              ; print 1 byte  -> "A"
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, nl
    mov rdx, 1
    syscall

    ; ── WORD: print label, then the 2 bytes, then a newline ───
    mov rax, 1
    mov rdi, 1
    mov rsi, wmsg
    mov rdx, wmsglen
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, myWord         ; point at our 2 bytes
    mov rdx, 2              ; print 2 bytes -> "AB" (little-endian order)
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, nl
    mov rdx, 1
    syscall

    ; ── DWORD: print label, then the 4 bytes, then a newline ──
    mov rax, 1
    mov rdi, 1
    mov rsi, dmsg
    mov rdx, dmsglen
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, myDword        ; point at our 4 bytes
    mov rdx, 4              ; print 4 bytes -> "ABCD"
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, nl
    mov rdx, 1
    syscall

    ; ── Exit cleanly ──────────────────────────────────────────
    mov rax, 60            ; service: exit
    mov rdi, 0             ; exit code 0 = success
    syscall