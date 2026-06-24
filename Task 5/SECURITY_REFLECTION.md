# Task 5 — Security Reflection: Unsafe Stack Practices
## BIT 4220 Assembly Programming

This document examines two critical security risks that arise from improper
use of the call stack in assembly programs, with concrete examples drawn
from this task's own code.

---

## 1. Stack Buffer Overflow

### What it is

A stack buffer overflow occurs when data written to a local buffer on the
stack extends beyond the buffer's allocated size, overwriting adjacent stack
memory — including the **saved return address**.

### Why it matters

The return address tells `RET` where to jump after a function exits.  If an
attacker controls the overflowing data, they can replace the return address
with an address of their choosing, redirecting execution to arbitrary code
(a technique called **return-oriented programming**, or ROP).

### Example from this task

`uint_to_dec` writes into `decbuf`, a 22-byte BSS buffer:

```nasm
section .bss
    decbuf  resb 22     ; 21 digits + NUL terminator
```

The procedure uses the **tail** of this buffer as a scratch area and then
copies the result to `buf[0..]`.  The maximum unsigned 64-bit decimal value
is 18,446,744,073,709,551,615 — exactly **20 digits**.  So 21 bytes of data
plus one NUL byte = 22 bytes total.  The buffer is just barely safe.

If the buffer were only 18 bytes, converting n=18446744073709551615 would
write 20 digits, overflowing by 3 bytes.  On the stack those 3 bytes would
land in the caller's saved registers or return address, corrupting the control flow.

### Vulnerable pattern

```nasm
; UNSAFE: buf is 10 bytes but n can produce up to 20 digits
uint_to_dec_unsafe:
    push rbx
    mov  r9, rsi          ; buf = 10 bytes on stack
    lea  rbx, [r9 + 20]  ; writes PAST the buffer end!
    ...
```

A caller allocating only 10 bytes for a "decimal string" buffer is a classic
off-by-N vulnerability.  In C: `char buf[10]; sprintf(buf, "%llu", n);` — the
same bug.

### Mitigation

- Always size buffers to hold the worst-case output plus the NUL terminator.
- For 64-bit unsigned: 20 digits + NUL = 21 bytes minimum; use 22 for safety.
- In production code: pass the buffer length as a parameter and check it before writing.
- Use operating system or compiler stack-canary protections (`-fstack-protector`
  in GCC/Clang; in kernel code, `CONFIG_STACKPROTECTOR`).

---

## 2. Infinite Recursion (Stack Overflow by Exhaustion)

### What it is

Every `CALL` pushes a return address (8 bytes) and typically one or more
callee-saved registers (8 bytes each) onto the stack.  If a function calls
itself without a correct base case, the stack grows without bound until the
operating system raises a segmentation fault (`SIGSEGV`) by detecting an
access beyond the stack's mapped region.

### Example from this task

`factorial` has a well-formed base case:

```nasm
factorial:
    push rbx            ; 8 bytes per frame
    mov  rbx, rdi
    cmp  rdi, 1
    jle  .base          ; ← base case: n ≤ 1 returns immediately
    dec  rdi
    call factorial      ; ← recursive call only when n > 1
    ...
.base:
    mov  rax, 1
    pop  rbx
    ret
```

For n=5, depth = 5 frames × 16 bytes = 80 bytes of stack.  Safe.

### Vulnerable mutation: missing or wrong base case

```nasm
factorial_bad:
    push rbx
    mov  rbx, rdi
    ; BUG: base case omitted — or placed after the recursive call
    dec  rdi
    call factorial_bad  ; ← always recurses, never terminates
    imul rax, rbx
    pop  rbx
    ret
```

With the base case missing:
- factorial_bad(5) calls factorial_bad(4) calls ... factorial_bad(-9999999...) ...
- Each frame consumes 16 bytes.
- Linux default stack limit: 8 MB → overflow after ~500,000 frames.
- The OS kills the process with SIGSEGV.

A second vulnerable pattern: passing a **negative** n to a signed recursive
factorial that decrements n toward zero — if the base case tests `n == 0`
instead of `n <= 1`, a negative input never hits the base case.

```nasm
factorial_signed_bug:
    cmp  rdi, 0
    je   .base      ; ← only catches n==0, not n<0
    dec  rdi        ; n=-1 → n=-2 → n=-3 → forever
    call factorial_signed_bug
    ...
```

Our implementation uses `JLE` (jump if less-or-equal) which correctly handles
n ≤ 1, including negative inputs.

### Mitigation

- Every recursive procedure must have a **proven base case** that is
  reachable from every possible input.
- Validate inputs at the call site: for unsigned factorial, assert n ≤ 20
  before calling.
- In production embedded systems: set a maximum recursion depth counter and
  return an error code when exceeded, rather than risking a stack overflow
  that could corrupt firmware state.
- Consider **tail-call optimisation** or iterative rewriting for deep recursion:

```nasm
; Iterative factorial — O(n) iterations, O(1) stack
factorial_iter:
    mov  rax, 1
    test rdi, rdi
    jle  .done
.loop:
    imul rax, rdi
    dec  rdi
    jnz  .loop
.done:
    ret
```

The iterative version uses no stack past the return address itself, making
stack overflow impossible for any finite n.

---

## 3. Additional Risks (Brief)

### Return address overwrite via strcpy/memcpy

If a procedure copies user input into a fixed-size local buffer without
bounds checking (the classic `gets()`-style vulnerability), an oversized
input overwrites the return address.  In assembly the risk is direct:
nothing prevents a `MOV [rsp-N], al` loop from running past its allocated
region.

### Unbalanced PUSH/POP (broken stack alignment)

The System V ABI requires RSP to be 16-byte aligned at the point of a CALL.
An extra or missing PUSH/POP misaligns the stack.  Certain SSE/AVX
instructions (`MOVAPS`, `MOVDQA`) fault with `#GP` on misaligned stack
access, producing a crash that looks unrelated to the real cause.

### Callee-saved register corruption

If a procedure uses a callee-saved register (rbx, r12–r15) without pushing
and popping it, the caller's value is silently overwritten.  This is not a
security vulnerability per se, but in embedded systems it can corrupt a
running meter total or accumulator value, producing incorrect billing output —
a correctness risk with real-world financial consequences.

---

## Summary Table

| Risk | Root cause | Consequence | Mitigation |
|------|-----------|-------------|------------|
| Stack buffer overflow | Buffer sized too small for worst-case input | Return address overwrite → arbitrary code execution | Size buffers for worst-case + NUL; add bounds check |
| Infinite recursion | Missing or unreachable base case | Stack exhaustion → SIGSEGV | Proven base case; input validation; use iterative form |
| Callee-saved corruption | Missing PUSH/POP for rbx/r12-r15 | Silent data corruption | Follow ABI; audit every callee-saved register use |
| Misaligned stack | Unbalanced PUSH/POP or odd-length alloca | SSE fault; wrong argument passing | Maintain 16-byte alignment; verify with GDB |
