# Task 9 — Benchmark Results & Analysis
## BIT 4220 Assembly Programming | Group Work

---

## Setup

| Parameter | Value |
|-----------|-------|
| Array length | 1 000 000 × `long` (8 MB) |
| Repetitions | 200 |
| Timer | `clock_gettime(CLOCK_MONOTONIC)` |
| Platform | x86-64 Linux (Docker, Ubuntu 24.04) |

---

## Results

### Compiled with `-O2` (optimised)

| Implementation | Result | Total (ms) | Per-rep (µs) |
|---------------|--------|-----------|-------------|
| `sum_c` (C loop) | 499 999 500 000 | 176 | 881 |
| `sum_asm` (inline asm) | 499 999 500 000 | 183 | 914 |

**Speed ratio (C / ASM): ~0.96 — roughly equal (within 5%)**

### Compiled with `-O0` (unoptimised)

| Implementation | Result | Total (ms) | Per-rep (µs) |
|---------------|--------|-----------|-------------|
| `sum_c` (C loop) | 499 999 500 000 | 721 | 3607 |
| `sum_asm` (inline asm) | 499 999 500 000 | 184 | 918 |

**Speed ratio (C / ASM): ~3.9 — inline ASM is ~4× faster**

Both implementations produce the correct result: 499 999 500 000 = N×(N−1)/2.

---

## Why the Results Look This Way

### At `-O2`: essentially the same

The compiler produces a tight loop for `sum_c`:

```asm
; gcc -O2 output for sum_c
xor    eax, eax
.loop:
  add    rax, [rdi]
  add    rdi, 8
  cmp    rdi, rdx       ; end-of-array pointer comparison
  jne    .loop
```

The hand-written inline asm loop (`sum_asm`) is structurally identical:

```asm
; inline asm sum_asm
xor    rax, rax
.loop:
  add    rax, [rdi]
  add    rdi, 8
  dec    rsi
  jnz    .loop
```

The compiler uses a pointer end-sentinel (`cmp rdi, rdx`) while the inline
asm uses a decrement counter (`dec rsi / jnz`).  Both are one load + one
add + two control instructions per iteration.  Modern out-of-order CPUs
execute these at the same throughput, so the 4% gap is noise.

### At `-O0`: inline ASM wins clearly (~4×)

With `-O0` the compiler generates naive code for `sum_c`: each iteration
spills and reloads every variable from the stack (no register allocation),
adding ~10 extra memory operations per element.  The inline asm is
unaffected by the optimisation level — the processor always executes exactly
the instructions we wrote.  This is why the inline asm loop takes ~918 µs
at both `-O0` and `-O2` while the C loop jumps from 881 µs to 3607 µs.

---

## Key Observations

1. **A good compiler matches hand-written asm at `-O2`.**  The gcc output
   for `sum_c` is essentially the same loop our inline asm produces.

2. **Inline asm becomes valuable when the compiler is restrained** (`-O0`,
   embedded toolchains, volatile-heavy code) or when you need instructions
   the compiler won't emit (SIMD, CRC, AES-NI, bit-manipulation extensions).

3. **The decrement-counter vs pointer-sentinel difference is negligible.**
   Both patterns retire at one iteration per clock on modern µarchs.
