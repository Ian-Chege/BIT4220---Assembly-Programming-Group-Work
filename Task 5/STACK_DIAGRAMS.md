# Task 5 — Stack Frame Diagrams
## BIT 4220 Assembly Programming

Stack grows **downward** (toward lower addresses).
Each `CALL` pushes the 8-byte return address; each `PUSH r` decrements RSP by 8.
Addresses are relative to the top-of-stack at function entry.

---

## 1. factorial — Recursive Stack Frames

`factorial` pushes **rbx** on entry to preserve the caller's copy.
For `factorial(5)` there are **six nested frames** before the base case unwinds.

```
HIGH ADDRESS
───────────────────────────────────────────────────────────────────────
  Caller (_start or outer factorial)
───────────────────────────────────────────────────────────────────────

[factorial(5) frame — outermost]
  RSP+8:  return address to _start        (pushed by CALL factorial)
  RSP+0:  saved rbx = 5                   (PUSH rbx; rbx ← rdi=5)
          ↓ CALL factorial(4) pushes next return address below

[factorial(4) frame]
  RSP+8:  return address to factorial(5)+offset
  RSP+0:  saved rbx = 4                   (rbx ← rdi=4)
          ↓ CALL factorial(3)

[factorial(3) frame]
  RSP+8:  return address to factorial(4)+offset
  RSP+0:  saved rbx = 3
          ↓ CALL factorial(2)

[factorial(2) frame]
  RSP+8:  return address to factorial(3)+offset
  RSP+0:  saved rbx = 2
          ↓ CALL factorial(1)

[factorial(1) frame — BASE CASE]
  RSP+8:  return address to factorial(2)+offset
  RSP+0:  saved rbx = 1
          cmp rdi, 1 → JLE .base → mov rax, 1 → POP rbx → RET

LOW ADDRESS
───────────────────────────────────────────────────────────────────────
```

**Unwind sequence** after factorial(1) returns rax=1:

```
factorial(2) resumes:  imul rax, rbx  → rax = 1 × 2 = 2
                       pop rbx (restores rbx=2 to caller's rbx)
                       ret

factorial(3) resumes:  imul rax, rbx  → rax = 2 × 3 = 6
factorial(4) resumes:  imul rax, rbx  → rax = 6 × 4 = 24
factorial(5) resumes:  imul rax, rbx  → rax = 24 × 5 = 120
```

**Memory cost**: each frame costs **16 bytes** (8 ret-addr + 8 saved rbx).
For n=12: 12 × 16 = 192 bytes of stack. For n=10000: ~160 KB → likely stack overflow.

---

## 2. str_len — No Stack Frame (leaf function)

`str_len` uses only the caller-saved registers rax and rdi.
It makes no `CALL`, so it never pushes a new return address.
The stack layout during execution is flat:

```
HIGH ADDRESS
───────────────────────────────────────────────────────────────────────
  Caller (_start)
  RSP+8:  ... caller's frame above ...
  RSP+0:  return address (pushed by CALL str_len)    ← RSP on entry
           ── str_len executes here, RSP never changes ──
  (RET pops RSP+0 back into RIP)
───────────────────────────────────────────────────────────────────────
LOW ADDRESS
```

Registers modified: **rax** (counter, return value), **rdi** (unchanged — base addr used in address calculation but rdi itself is not modified by our loop since we index with rax).

---

## 3. max3 — No Stack Frame (leaf function)

All three arguments (rdi, rsi, rdx) and the return value (rax) are **caller-saved**.
No callee-saved register is touched, so no PUSH/POP is needed.

```
HIGH ADDRESS
───────────────────────────────────────────────────────────────────────
  Caller (_start)
  RSP+0:  return address (pushed by CALL max3)       ← RSP on entry
           ── max3 executes; RSP unchanged ──
  (RET pops RSP+0 into RIP)
───────────────────────────────────────────────────────────────────────
LOW ADDRESS
```

Execution trace for max3(10, 30, 20):
```
  Entry:     rdi=10, rsi=30, rdx=20
  mov rax, rdi    → rax = 10   (assume a is max)
  cmp rsi, rax    → 30 > 10    → NOT taken (JLE skipped)
  mov rax, rsi    → rax = 30   (b is larger)
  cmp rdx, rax    → 20 < 30    → JLE taken (c is not larger)
  Return:    rax = 30  ✓
```

---

## 4. uint_to_dec — One Saved Register (rbx)

`uint_to_dec` saves **rbx** because it uses rbx as a working write pointer
(decrementing through the scratch area).  All other registers it uses
(rax, rcx, rdx, r8, r9) are caller-saved.

```
HIGH ADDRESS
───────────────────────────────────────────────────────────────────────
  Caller (_start)
  RSP+8:  return address (pushed by CALL uint_to_dec) ← RSP before PUSH
  RSP+0:  saved rbx = <caller's rbx value>             ← RSP after PUSH rbx
           ── function body executes ──
  (POP rbx restores; RET pops return address)
───────────────────────────────────────────────────────────────────────
LOW ADDRESS
```

**Algorithm walkthrough** for n=255:
```
  r9 = buf (start of output buffer)
  rbx = buf + 20  (tail of scratch workspace)
  [rbx] = 0       (NUL terminator planted)

  Iteration 1:  rax=255 ÷ 10 → quot=25, rem=5   → [--rbx]='5'  r8=1
  Iteration 2:  rax=25  ÷ 10 → quot=2,  rem=5   → [--rbx]='5'  r8=2
  Iteration 3:  rax=2   ÷ 10 → quot=0,  rem=2   → [--rbx]='2'  r8=3
  (rax == 0: stop loop)

  Scratch after loop:  ... '2' '5' '5' \0
                            ↑ rbx

  Copy loop (rcx=3):  copies '2','5','5' to buf[0..2]
  buf[3] = 0

  Return:  rax = 3 (digit count)
```

---

## 5. sum_array — No Stack Frame (leaf function)

Only caller-saved registers used: rax (accumulator), rsi (count), rdi (array pointer), rcx (index).

```
HIGH ADDRESS
───────────────────────────────────────────────────────────────────────
  Caller (_start)
  RSP+0:  return address (pushed by CALL sum_array)  ← RSP on entry
           ── sum_array executes; RSP unchanged ──
  (RET pops RSP+0 into RIP)
───────────────────────────────────────────────────────────────────────
LOW ADDRESS
```

**Memory access pattern** for arr=[1,2,3,4,5], n=5:
```
  Iteration 0:  rax += [arr + 0×8]  = 1   → rax = 1
  Iteration 1:  rax += [arr + 1×8]  = 2   → rax = 3
  Iteration 2:  rax += [arr + 2×8]  = 3   → rax = 6
  Iteration 3:  rax += [arr + 3×8]  = 4   → rax = 10
  Iteration 4:  rax += [arr + 4×8]  = 5   → rax = 15
  rcx(5) == rsi(5): JB not taken → exit
  Return: rax = 15  ✓
```

---

## Stack Depth Summary

| Procedure | Saved registers | Bytes per call | Recursive? | Max depth |
|-----------|----------------|----------------|------------|-----------|
| factorial | rbx | 16 | Yes | n frames |
| str_len | none | 8 (ret addr only) | No | 1 |
| max3 | none | 8 | No | 1 |
| uint_to_dec | rbx | 16 | No | 1 |
| sum_array | none | 8 | No | 1 |

The only procedure with unbounded stack growth is `factorial`.  Every
recursive call adds 16 bytes.  For n=10,000 that is ~160 KB — the
Linux default stack size is 8 MB, so overflow would happen around n≈500,000
on a typical system, but for academic purposes n≤20 is the safe range.
