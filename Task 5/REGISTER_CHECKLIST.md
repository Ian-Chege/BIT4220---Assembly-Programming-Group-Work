# Task 5 — Register Preservation Checklist
## BIT 4220 Assembly Programming

Under the **System V AMD64 ABI** (the Linux calling convention):

| Register class | Registers | Who owns them |
|---------------|-----------|---------------|
| Callee-saved ("non-volatile") | rbx, rbp, r12, r13, r14, r15, rsp | The **called function** must preserve these — caller can rely on them being unchanged after the call returns |
| Caller-saved ("volatile") | rax, rcx, rdx, rsi, rdi, r8, r9, r10, r11 | The **caller** must save these if needed — the called function may freely clobber them |
| Return value | rax | Written by callee; read by caller |
| Arguments | rdi, rsi, rdx, rcx, r8, r9 | Written by caller before CALL; read by callee |

---

## Checklist per Procedure

### 1. factorial(n: rdi) → rax

| Register | Used for | ABI class | Saved? | How |
|----------|----------|-----------|--------|-----|
| rdi | input n | arg / caller-saved | not needed | overwritten |
| rbx | saved copy of n (survives recursive CALL) | callee-saved | **YES** | PUSH rbx / POP rbx |
| rax | return value (n!) | return / caller-saved | not applicable | return value |

**Why rbx?**  After `CALL factorial`, rax holds (n-1)! — but we need n to compute `n × (n-1)!`.
We cannot keep n in rdi because the recursive CALL sets rdi = n-1.
We choose rbx because it is callee-saved, meaning the recursive call will not touch it.

```
factorial:
    push rbx        ← save caller's rbx
    mov  rbx, rdi   ← rbx = n  (will survive the recursive CALL)
    ...
    call factorial  ← rax = (n-1)!  rbx still = n
    imul rax, rbx   ← rax = n!
    pop  rbx        ← restore caller's rbx
    ret
```

---

### 2. str_len(str: rdi) → rax

| Register | Used for | ABI class | Saved? | How |
|----------|----------|-----------|--------|-----|
| rdi | base address of string | arg / caller-saved | not needed | rdi not modified by loop |
| rax | byte offset / return value | caller-saved | not applicable | return value |

No callee-saved registers are touched.  No PUSH/POP required.

---

### 3. max3(a: rdi, b: rsi, c: rdx) → rax

| Register | Used for | ABI class | Saved? | How |
|----------|----------|-----------|--------|-----|
| rdi | first argument a | arg / caller-saved | not needed | read-only |
| rsi | second argument b | arg / caller-saved | not needed | read-only |
| rdx | third argument c | arg / caller-saved | not needed | read-only |
| rax | running maximum / return value | caller-saved | not applicable | return value |

No callee-saved registers are touched.  No PUSH/POP required.

---

### 4. uint_to_dec(n: rdi, buf: rsi) → rax

| Register | Used for | ABI class | Saved? | How |
|----------|----------|-----------|--------|-----|
| rdi | n (consumed by DIV) | arg / caller-saved | not needed | overwritten |
| rsi | buf start | arg / caller-saved | not needed | overwritten |
| r9 | saved buf start (persists past DIV) | caller-saved | not needed | r9 is caller-saved; callee may clobber |
| rbx | write pointer (decremented right-to-left) | callee-saved | **YES** | PUSH rbx / POP rbx |
| rax | quotient → digit count (return value) | caller-saved | not applicable | return value |
| rdx | remainder from DIV | caller-saved | not needed | clobbered by DIV |
| rcx | divisor 10 / copy counter | caller-saved | not needed | freely set |
| r8 | digit count | caller-saved | not needed | freely set |

**Why rbx?**  The right-to-left write pointer must survive the inner `DIV rcx` loop.
`DIV` clobbers rdx (remainder) and rax (quotient), so we cannot use those.
r9 through r11 are caller-saved and safe to use freely, which is why r9 is used
for the buf-start copy without pushing it.  rbx is pushed because it is callee-saved
and we must not corrupt the caller's rbx value.

---

### 5. sum_array(arr: rdi, n: rsi) → rax

| Register | Used for | ABI class | Saved? | How |
|----------|----------|-----------|--------|-----|
| rdi | base pointer to array | arg / caller-saved | not needed | read-only |
| rsi | element count n | arg / caller-saved | not needed | used as bound in CMP |
| rax | accumulator / return value | caller-saved | not applicable | return value |
| rcx | loop index i | caller-saved | not needed | freely clobbered |

No callee-saved registers are touched.  No PUSH/POP required.

---

## Driver Register Usage

The driver (`_start` in driver.asm) uses callee-saved registers to hold
values across multiple library and print calls:

| Register | Holds |
|----------|-------|
| r12 | string address (str_len tests) or first test input (max3/u2d) |
| r13 | second test input (max3) or element count (sum_array) |
| r14 | third test input (max3) |
| r15 | return value saved for printing after print helpers run |

Because r12–r15 are callee-saved, every procedure call and every `print_str` /
`print_uint` call in the driver preserves them automatically — no explicit saves
in the driver body are needed.

---

## ABI Compliance Summary

| Procedure | Callee-saved regs pushed | Correct? |
|-----------|--------------------------|---------|
| factorial | rbx | ✓ |
| str_len | (none needed) | ✓ |
| max3 | (none needed) | ✓ |
| uint_to_dec | rbx | ✓ |
| sum_array | (none needed) | ✓ |
| print_uint_noeol (driver) | rbx, rcx, rdx, rdi | ✓ (saves all it clobbers) |
