# Why Overflow Matters in Real Systems
## BIT 4220 Task 3 — Short Discussion

---

## What Is Overflow?

A CPU performs arithmetic in a fixed number of bits.  An **arithmetic overflow**
occurs when the mathematically correct result cannot be represented in that
fixed width.  There are two distinct kinds:

| Kind | Flag | Triggers when |
|------|------|---------------|
| **Unsigned overflow** (carry) | CF | The result exceeds the maximum *unsigned* value (e.g. > 255 for 8-bit) |
| **Signed overflow** | OF | The result exceeds the signed range (e.g. > 127 or < −128 for 8-bit) |

The CPU always computes the bit pattern correctly — it is the *programmer's*
responsibility to check the flags and decide whether the result is valid.

---

## Real-World Consequences

### 1. Prepaid Utility Meters (this task's context)
A meter stores a credit balance as a 16-bit unsigned counter (0–65535 units).
If the billing firmware subtracts usage using an unsigned 16-bit register and
the balance drops below zero, **CF is set**.  Code that ignores CF wraps the
counter to 65535, giving the customer unlimited free electricity.  Conversely,
failing to check CF during a top-up could allow the counter to roll back to 0
from 65535, locking out a paying customer.

### 2. ArianE 5 Rocket (1996) — Historic Case Study
The Ariane 5 launcher used software ported from Ariane 4.  A 64-bit floating-
point horizontal velocity was converted to a 16-bit signed integer.  The value
exceeded 32767 (the 16-bit maximum), causing a signed overflow.  The exception
was not handled; the inertial reference system shut itself down, the rocket
self-destructed 37 seconds after launch, and the mission ($500 M payload)
was lost entirely.

### 3. Integer Overflow in Security (CVE pattern)
A web server allocates a buffer:
```c
size_t total = num_items * sizeof(item);   // 16-bit on legacy system
char *buf = malloc(total);
```
If `num_items = 300` and `sizeof(item) = 300`, the 16-bit product wraps to
`300 × 300 mod 65536 = 90000 mod 65536 = 24464`.  `malloc` allocates only
24 KB; the subsequent copy writes 90 KB, causing a **heap buffer overflow**
that an attacker can exploit to gain arbitrary code execution.

### 4. Network Protocol Counters
TCP sequence numbers are 32-bit and intentionally wrap around (RFC 793 §3.3).
Implementations must treat `SEQ_A < SEQ_B` as a *modular* comparison.  Early
BSD TCP implementations used a plain `<` on the 32-bit number without handling
wrap-around, making connections fail after ≈ 4 GB had been transferred — a
number that was hypothetical in 1981 but routine by the 1990s.

---

## How x86 Assembly Lets You Detect Overflow

```nasm
add al, bl          ; perform 8-bit addition
jo  overflow_signed ; jump if OF=1  (signed overflow)
jc  overflow_carry  ; jump if CF=1  (unsigned carry)
```

For multiplication where the product might not fit in the low register:

```nasm
mul bl              ; AX = AL * BL
jc  product_gt_255  ; CF=1 means AH != 0 → product > 255
```

For subtraction / comparisons in the meter context:

```nasm
sub ax, cx          ; deduct usage from balance
jc  balance_negative ; CF=1: balance went below 0 — reject top-up
```

---

## Overflow vs. Wrapping — A Design Choice

Some domains *intentionally* use wrapping:
- **CRC and checksum algorithms** rely on modular 32/64-bit arithmetic.
- **Cryptographic primitives** (SHA, AES key schedule) depend on carry-free
  modular reduction.
- **Ring buffers** use `index & (SIZE-1)` (a power-of-two mask) so the index
  wraps without a branch.

In these cases CF is either ignored or is part of the algorithm.  The
programmer explicitly chooses wrap semantics.

In **safety-critical** or **security-critical** code (billing, allocation,
network lengths) overflow must be *detected and rejected* rather than ignored
or wrapped.

---

## Summary

> **Overflow is not an edge case — it is an expected condition that every
> low-level computation involving bounded integers must anticipate.**

The x86 CPU provides CF and OF precisely so programmers can make this
decision.  The ALU simulator in `alu.asm` exposes both flags after every
operation so that their behaviour across different inputs can be explored
interactively — exactly the kind of flag awareness required in firmware for
devices like prepaid utility meters.
