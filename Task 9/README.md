# Task 9: Inline Assembly and Performance Tuning
## BIT 4220 Assembly Programming — Group Work

---

## Overview

Compares a plain C array-sum loop against a hand-written inline assembly
version.  Both are benchmarked at `-O2` (compiler-optimised) and `-O0`
(unoptimised) to show when inline asm matters and when it doesn't.

---

## Files

| File | Purpose |
|------|---------|
| `sum.c` | Three implementations + benchmark harness |
| `run.sh` | Build both binaries, run benchmarks, show disassembly |
| `BENCHMARK.md` | Results table, disassembly comparison, analysis |
| This README | Overview + build commands + trade-off summary |

---

## Quick Start

```bash
chmod +x run.sh
./run.sh
```

Manual build inside the container:
```bash
gcc -O2 -o sum_opt  sum.c   # optimised
gcc -O0 -o sum_nopt sum.c   # unoptimised baseline
./sum_opt
./sum_nopt
```

---

## Key Results

| Scenario | C loop | Inline ASM | Winner |
|----------|--------|-----------|--------|
| `-O2` (optimised) | ~881 µs/rep | ~914 µs/rep | **Equal** |
| `-O0` (unoptimised) | ~3607 µs/rep | ~918 µs/rep | **ASM ~4×** |

At `-O2` gcc produces nearly identical machine code to the hand-written
loop — the compiler is that good.  At `-O0` the compiler spills every
variable to the stack each iteration; inline asm is unaffected.

---

## Trade-off Analysis

| Dimension | C loop | Inline Assembly |
|-----------|--------|----------------|
| **Speed** | Matches asm with `-O2`; 4× slower at `-O0` | Consistent regardless of opt level |
| **Readability** | Clear intent; any C programmer can read it | Hard to read; requires asm knowledge |
| **Portability** | Compiles on x86, ARM, RISC-V unchanged | x86-64 only; must rewrite for other ISAs |
| **Debugging** | Source-level GDB, sanitisers, valgrind | Only register/disasm inspection; no sanitisers |
| **Maintenance** | Compiler handles ABI changes automatically | Clobber lists must be updated manually |

**Recommendation:** use C with `-O2` for almost everything.  Reach for
inline asm only when you need hardware-specific instructions (SIMD, AES-NI,
CRC32) or when the compiler backend cannot be trusted (safety-critical,
embedded with restricted optimisation).

---

## Deliverables Checklist

- [x] **a)** C source file: `sum.c`
- [x] **b)** Build commands: `run.sh` and this README
- [x] **c)** Benchmark table and discussion: `BENCHMARK.md`
- [x] **d)** Trade-off analysis: above table + `BENCHMARK.md §Key Observations`
