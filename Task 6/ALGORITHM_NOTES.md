# Task 6 — Algorithm Notes and Memory Diagrams
## BIT 4220 Assembly Programming

---

## 1. to_upper — Lowercase-to-Uppercase Conversion

### Algorithm

Walk a pointer through the NUL-terminated string one byte at a time.
For each byte in the range `['a', 'z']` (ASCII 97–122) subtract 32,
which maps it into the range `['A', 'Z']` (ASCII 65–90).
All other bytes are left unchanged.

**Why 32?** In ASCII the difference between a lowercase and its uppercase
counterpart is exactly bit 5 (2⁵ = 32).  Subtracting 32 clears bit 5,
producing the uppercase form.

```
ASCII 'a' = 0110 0001  (97)
            - 0010 0000  (32)
            = 0100 0001  (65) = 'A'
```

### Memory diagram — string "warn" before and after

```
Address:  buf+0  buf+1  buf+2  buf+3  buf+4
BEFORE:    'w'    'a'    'r'    'n'     0x00
            77     61     72     6E      00

           ↓ sub each by 32 if in [0x61, 0x7A]

AFTER:     'W'    'A'    'R'    'N'     0x00
            57     41     52     4E      00
```

### Assembly pattern

```nasm
to_upper:
    movzx eax, byte [rdi]    ; load byte at current position
    test  eax, eax           ; NUL → done
    jz    .done
    cmp   eax, 'a'           ; below 'a'? not lowercase
    jb    .next
    cmp   eax, 'z'           ; above 'z'? not lowercase
    ja    .next
    sub   eax, 32            ; clear bit 5 → uppercase
    mov   [rdi], al          ; write back
.next:
    inc   rdi                ; advance pointer
    jmp   to_upper
```

### Complexity

O(n) where n = string length.  One pass, constant work per byte.

---

## 2. str_rev — In-Place String Reversal

### Algorithm

Use two pointers, `left` starting at the first character and `right`
starting at the last (one byte before the NUL terminator).
Swap the bytes at `left` and `right`, then advance `left` and retreat
`right`.  Stop when the pointers meet or cross.

### Memory diagram — reversing "Hello"

```
Step 0 (initial):
  Index:  0     1     2     3     4
  Byte:  'H'   'e'   'l'   'l'   'o'  '\0'
          ↑                        ↑
         left                   right

Step 1: swap [0] ↔ [4]  →  'o' 'e' 'l' 'l' 'H'
  left → 1        right → 3

Step 2: swap [1] ↔ [3]  →  'o' 'l' 'l' 'e' 'H'
  left → 2        right → 2

Step 3: left >= right → STOP
```

Final result: `"olleH"` (NUL at position 5 is unchanged)

### Assembly pattern

```nasm
    ; find length → rdx
    xor  rdx, rdx
.flen:  cmp byte [rdi + rdx], 0 ; scan for NUL
        jz  .rev
        inc rdx  ;  jmp .flen

    ; set up two pointers (both callee-saved)
    mov  rbx, rdi            ; left  = buf
    lea  r12, [rdi + rdx-1] ; right = buf + len - 1

.swap:
    cmp  rbx, r12            ; left >= right?
    jge  .done
    mov  al, [rbx]           ; al = byte at left
    mov  cl, [r12]           ; cl = byte at right
    mov  [rbx], cl
    mov  [r12], al
    inc  rbx
    dec  r12
    jmp  .swap
```

### Complexity

O(n) where n = string length.  Length scan + n/2 swaps.

---

## 3. char_count — Character Category Counter

### Algorithm

Walk the string once; for each byte classify it into one of four groups:

| Group | Byte range | ASCII values |
|-------|-----------|-------------|
| Letter | A-Z or a-z | 65–90 or 97–122 |
| Digit | 0-9 | 48–57 |
| Space | 0x20 | 32 |
| Special | anything else | punctuation, colons, brackets … |

Each count is stored in a dedicated 8-byte BSS variable.

### Decision tree (one iteration)

```
byte = buf[i]
        │
   byte == 0x00 ?──Yes──► DONE
        │ No
   'A' <= byte <= 'Z' ?──Yes──► cnt_letters++
        │ No
   'a' <= byte <= 'z' ?──Yes──► cnt_letters++
        │ No
   '0' <= byte <= '9' ?──Yes──► cnt_digits++
        │ No
   byte == ' ' ?──────Yes──► cnt_spaces++
        │ No
   cnt_specials++
```

### Memory layout of counters (BSS section)

```
Label         Offset   Size   Description
──────────────────────────────────────────────────
cnt_letters   +0       8 B    running letter count
cnt_digits    +8       8 B    running digit count
cnt_spaces    +16      8 B    running space count
cnt_specials  +24      8 B    running special count
```

Each counter is a 64-bit quadword (`resq 1`), allowing string lengths
up to 2⁶⁴ − 1 without overflow.

### Example — counting log1 original string

```
"ERR: meter fault at 09:42 -- device #mtr-001"

Character walk:
  E R R : [sp] m e t e r [sp] f a u l t [sp] a t [sp] 0 9 : 4 2 [sp] - - [sp] d e v i c e [sp] # m t r - 0 0 1

Result:
  Letters:  26  (ERR + meter + fault + at + device + mtr)
  Digits:    6  (09, 42, 001)
  Spaces:    7
  Specials:  5  (: -- # -)
  Total:    44
```

### Complexity

O(n).  Exactly one pass; constant-time lookup per byte.

---

## 4. kw_search — Brute-Force Substring Search

### Algorithm

The naive (brute-force) string search:

```
for i = 0 to len(haystack)-1:
    match = true
    for j = 0 to len(needle)-1:
        if haystack[i+j] != needle[j]:
            match = false
            break
    if match:
        return i
return -1
```

**Time complexity**: O(|hay| × |needle|).  For short log strings and short
keywords this is faster in practice than KMP or Boyer-Moore because the
constant is smaller and there is no preprocessing overhead.

### Memory diagram — searching "fault" in "ERR: meter fault"

```
Haystack: E  R  R  :  ' '  m  e  t  e  r  ' '  f  a  u  l  t
Index:    0  1  2  3   4   5  6  7  8  9   10  11 12 13 14 15

Needle: f a u l t
Len:    5

i=0: hay[0..4] = "ERR: " ≠ "fault"  → mismatch at j=0 ('E'≠'f')
i=1: hay[1..5] = "RR: m" → mismatch j=0
...
i=11: hay[11..15] = "fault" == "fault"  → MATCH → return 11
```

### Register mapping during search

```
rdi + rbx + rcx  would need THREE registers for hay[i+j]
↓ (x86-64 SIB allows only base+index, so we pre-add)

lea r8, [rdi + rbx]    ; r8 = &hay[i]
mov al,  [r8 + rcx]    ; hay[i+j]   (base=r8, index=rcx)
mov dl,  [rsi + rcx]   ; needle[j]  (base=rsi, index=rcx)
```

### Register roles during kw_search

```
Register  ABI class       Role
─────────────────────────────────────────────────────────
rdi       caller-saved    haystack base address
rsi       caller-saved    needle base address
rbx       CALLEE-SAVED    outer loop index i  ← PUSHED
r12       CALLEE-SAVED    needle length        ← PUSHED
rcx       caller-saved    inner offset j
r8        caller-saved    hay + i  (temporary pointer)
al (rax)  caller-saved    byte from hay[i+j]
dl (rdx)  caller-saved    byte from needle[j]
rax       return value    result (offset or -1)
```

### Return values

| Situation | Return value in rax |
|-----------|-------------------|
| Match found at position i | i (0-indexed byte offset) |
| No match found | -1 (= 0xFFFFFFFFFFFFFFFF) |
| Empty needle | 0 (vacuously found at position 0) |

---

## 5. copy_str — NUL-Terminated String Copy

### Algorithm

Walk two pointers (dst and src) in lock-step, copying one byte at a time
from src to dst until the NUL terminator has been copied.

```nasm
.loop:
    mov al, [rsi]         ; load byte from src
    mov [rdi], al         ; store byte to dst
    test al, al           ; is it NUL?
    jz  .done             ; yes: both pointers now past their NUL → done
    inc rdi
    inc rsi
    jmp .loop
```

Only `al` (the low byte of `rax`) is used — `rax` is caller-saved, so no
push/pop is required.

---

## Summary Table

| Procedure | Strategy | Complexity | Callee-saved regs |
|-----------|----------|-----------|-------------------|
| to_upper | Single scan + in-place patch | O(n) | none |
| str_rev | Two-pointer swap | O(n) | rbx, r12 |
| char_count | Single scan + range tests | O(n) | none |
| kw_search | Brute-force nested loop | O(n×m) | rbx, r12 |
| copy_str | Sequential byte copy | O(n) | none |
