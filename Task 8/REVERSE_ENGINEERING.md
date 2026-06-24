# Task 8 — Reverse Engineering Notes
## BIT 4220 Assembly Programming | Group Work

---

## Objective

Determine what `buggy` does by static analysis (objdump + readelf) without
reading the source, then verify with GDB — the standard RE workflow.

---

## Step 1: Section survey (`readelf -S buggy`)

```
[1] .text   PROGBITS  0x401000   (executable code)
[2] .data   PROGBITS  0x402000   (initialised data)
[3] .bss    NOBITS    0x402088   (zero-initialised data)
```

No dynamic imports (`readelf -d` shows nothing).  The binary is statically
linked and makes direct syscalls — typical of hand-written NASM.

.data starts at 0x402000 and .bss at 0x402088 = 0x402000 + 0x88 (136 bytes).
That accounts for 8×8 = 64 bytes of qword data, ~35 bytes of string literals,
and a few padding bytes.

---

## Step 2: Disassembly walk-through (`objdump -d -M intel buggy`)

### Helper routines (0x401000–0x401087)

Two clearly-bounded leaf functions before `_start`:

**`print_str` (0x401000)** — pushes rax/rdi, sets rax=1 (sys_write), rdi=1
(stdout), syscalls with caller-supplied rsi/rdx, pops and returns.
Pure output helper with no side-effects.

**`print_uint_noeol` (0x401008)** — takes rax = unsigned integer, converts to
decimal digits by repeated `div rbx` (rbx=10) into a local buffer built right-
to-left, then calls `print_str`.  Handles zero as a special case.

**`print_uint` (0x401080)** — thin wrapper: calls `print_uint_noeol` then
appends a newline via `print_str`.

### `_start` (0x401088)

**Init block:**
```
mov  ebx, 0x8     ; loop bound (8 elements)
xor  r8,  r8      ; accumulator (sum)
xor  r9,  r9      ; candidate min
xor  r10, r10     ; candidate max
mov  ecx, 0x1     ; loop index — NOTE: starts at 1, not 0
```

**Loop body (0x40109b):**
```
mov  r12, [rcx*4 + 0x402000]   ; load from .data base
add  r8,  r12                   ; sum += element
cmp  r12, r9 / jge .no_min      ; if r12 < r9: r9 = r12
cmp  r12, r10 / jge .no_max     ; if r12 < r10: r10 = r12  (inverted!)
inc  rcx
cmp  rcx, 8 / jl .loop
```

RE conclusion: this is a min/max/sum loop over an integer array stored at
0x402000.  The array contains 8 elements.  Inspecting .data at that address
with GDB confirms they are qword values: `23 17 45 8 91 34 62 7`.

**Print block:** four calls to `print_str` (labels) + `print_uint` (values)
for sum, min, max, and average.  The average computes `div r8` (sum ÷ sum)
rather than `div rbx` (sum ÷ count).

---

## Step 3: GDB dynamic trace

```
(gdb) x/8gd arr
0x402000: 23   17
0x402010: 45   8
0x402020: 91   34
0x402030: 62   7
```

Stepping through the first loop iteration with `rcx=1` and scale ×4:
address = 0x402000 + 1×4 = 0x402004 — this is bytes 4–11 of the first qword
(value 23 = 0x0000000000000017).  Bytes 4–7 are `0x00000017`; read as a qword
they include the upper 4 bytes of the next element, producing a huge garbage
value (~86 billion), consistent with the observed Sum=691 489 734 726.

---

## Step 4: Bug identification summary

From static analysis alone (no source code required):

| Bug | How identified |
|-----|---------------|
| Off-by-one index | `mov ecx, 0x1` at init vs. expected `xor ecx, ecx` |
| Zero min sentinel | `xor r9, r9` at init — 0 will never be updated by real data |
| Wrong stride | `rcx*4` in load — array elements are qwords (8 bytes); confirmed by .data layout |
| Inverted max branch | `jge .no_max` — skips update when r12 ≥ r10, i.e. exactly when a larger element is found |
| Self-division | `div r8` after accumulation — r8 holds the sum, not the count |

All five bugs are detectable purely from the disassembly + a short GDB
inspection of the data section.  No source code was needed.
