# Task 5: Secure Procedure Library
## BIT 4220 Assembly Programming — Group Work

---

## Overview

A reusable **stack-based procedure library** for a prepaid utility meter
control system.  Five general-purpose routines are compiled into a separate
object file (`procedures.o`) and linked with a driver (`driver.o`) that
exercises every routine with multiple test inputs.

The two-file design demonstrates:
- `global` / `extern` declarations for separate compilation
- The System V AMD64 ABI calling convention
- Correct callee-saved register management (PUSH/POP of rbx)
- Recursive stack frame construction and unwinding

---

## Files

| File | Purpose |
|------|---------|
| `procedures.asm` | Library: factorial, str_len, max3, uint_to_dec, sum_array |
| `driver.asm` | Test driver: calls each procedure with multiple inputs |
| `run.sh` | Assemble both files, link, and run inside Docker |
| `STACK_DIAGRAMS.md` | ASCII stack frame diagrams for every procedure |
| `REGISTER_CHECKLIST.md` | Register preservation checklist per procedure |
| `SECURITY_REFLECTION.md` | Stack buffer overflow + infinite recursion discussion |
| This README | Quick start, build details, ABI summary, procedure reference |

---

## Quick Start

```bash
chmod +x run.sh
./run.sh
```

Expected output:

```
============================================
  Task 5: Procedure Library Test Driver
  BIT 4220 -- Stack-Based Function Calls
============================================

--- factorial (recursive) ---
  factorial(0) = 1
  factorial(1) = 1
  factorial(5) = 120
  factorial(10) = 3628800
  factorial(12) = 479001600

--- str_len ---
  str_len("") = 0
  str_len("Hello") = 5
  str_len("BIT4220") = 7
  str_len("Control Flow") = 12

--- max3 ---
  max3(10, 20, 30) = 30
  max3(30, 20, 10) = 30
  max3(10, 30, 20) = 30
  max3(7, 7, 7) = 7

--- uint_to_dec ---
  uint_to_dec(0) = "0"  (1 chars)
  uint_to_dec(42) = "42"  (2 chars)
  uint_to_dec(255) = "255"  (3 chars)
  uint_to_dec(65535) = "65535"  (5 chars)

--- sum_array ---
  sum_array([], n=0) = 0
  sum_array([1,2,3,4,5], n=5) = 15
  sum_array([10,20,30,40], n=4) = 100

All tests complete.
```

---

## Build Details

### Two-file separate compilation

```bash
# Step 1 — assemble the library
nasm -f elf64 procedures.asm -o procedures.o

# Step 2 — assemble the driver
nasm -f elf64 driver.asm -o driver.o

# Step 3 — link both objects into one executable
ld procedures.o driver.o -o driver
```

`ld` resolves cross-file symbol references:
- `driver.asm` declares `extern factorial` etc.; NASM emits undefined-symbol
  references in `driver.o`.
- `procedures.asm` declares `global factorial` etc.; NASM emits exported symbols
  in `procedures.o`.
- `ld` matches them at link time, filling in the call targets.

This is exactly how C libraries work: the `.c` file becomes a `.o`, the header
provides `extern` declarations, and the linker glues them together.

---

## Calling Convention Reference (System V AMD64 ABI)

```
Integer argument registers (in order): rdi, rsi, rdx, rcx, r8, r9
Return value:                          rax
Callee-saved (procedure must preserve): rbx, rbp, r12–r15, rsp
Caller-saved (may be freely clobbered): rax, rcx, rdx, rsi, rdi, r8–r11
Stack alignment: RSP must be 16-byte aligned immediately before CALL
```

---

## Procedure Reference

### 1. `factorial(n: rdi) → rax`

Returns n! computed recursively.  Base case: n ≤ 1 returns 1.
**Safe range**: n ≤ 20 (20! = 2,432,902,008,176,640,000 fits in 64 bits).

```
Callee-saved: rbx  ← stores n across the recursive CALL
Stack depth:  n frames × 16 bytes each
```

### 2. `str_len(str: rdi) → rax`

Counts bytes from `str` until the first NUL byte (exclusive).
Returns 0 for an empty string.  No registers need saving (leaf function).

### 3. `max3(a: rdi, b: rsi, c: rdx) → rax`

Returns the largest of three signed 64-bit integers.
Uses `CMP` and conditional `JLE` — no branches on CMOV needed.
No registers need saving (leaf function).

### 4. `uint_to_dec(n: rdi, buf: rsi) → rax`

Converts unsigned 64-bit `n` to a decimal ASCII string in `buf`.
`buf` must be at least 21 bytes (20 digits + NUL).  Returns digit count.

```
Callee-saved: rbx  ← working write pointer (decremented right-to-left)
Algorithm:    divide-by-10 loop; digits stored right-to-left in buf tail;
              then forward-copied to buf[0..]
```

### 5. `sum_array(arr: rdi, n: rsi) → rax`

Sums `n` consecutive signed 64-bit integers starting at `arr`.
`arr` must be 8-byte aligned.  Returns 0 when n = 0 (leaf function).

---

## Stack Frame Diagrams

See `STACK_DIAGRAMS.md` for detailed ASCII diagrams of each procedure's
stack layout, including the full recursive unwinding trace for factorial(5).

---

## Register Preservation

See `REGISTER_CHECKLIST.md` for a table of every register each procedure
uses, its ABI class, and whether it is saved/restored.

---

## Security Reflection

See `SECURITY_REFLECTION.md` for a discussion of:
- **Stack buffer overflow**: how an undersized `decbuf` could corrupt the return address
- **Infinite recursion**: how a missing or incorrect base case exhausts the stack
- Mitigations for both risks in embedded billing firmware

---

## Deliverables Checklist

- [x] **a)** Source code: `procedures.asm` (library) + `driver.asm` (test driver)
- [x] **b)** Stack frame diagrams: `STACK_DIAGRAMS.md` (ASCII, all 5 procedures)
- [x] **c)** Register preservation checklist: `REGISTER_CHECKLIST.md`
- [x] **d)** Security reflection: `SECURITY_REFLECTION.md` (overflow + recursion)
- [x] All 20 test cases pass; output verified against expected values
