# Task 8: Debugging and Reverse Engineering a Faulty Assembly Program
## BIT 4220 Assembly Programming — Group Work

---

## Overview

A meter-readings analyser is supplied in broken form.  The task is to:

1. Run the buggy binary and observe wrong output.
2. Use GDB, objdump, and readelf to locate the faults without reading comments.
3. Produce a corrected version (`fixed.asm`) that passes all checks.
4. Document each bug: symptom → root cause → fix → evidence.

---

## Files

| File | Purpose |
|------|---------|
| `buggy.asm` | Faulty analyser with 5 planted bugs |
| `fixed.asm` | Corrected version — all 5 bugs resolved |
| `debug.gdb` | GDB batch script: break at `_start`, step through init + first loop body |
| `run.sh` | Build both, compare output, run GDB + objdump + readelf |
| `BUGS.md` | Full bug table: symptom / root cause / fix / binary evidence |
| `REVERSE_ENGINEERING.md` | RE walk-through: readelf → objdump → GDB, no source needed |
| This README | Overview + before/after evidence + deliverables checklist |

---

## Quick Start

```bash
chmod +x run.sh
./run.sh
```

---

## Before / After Evidence

### Buggy output

```
=== Readings Analyser (BUGGY) ===
Sum:     691489734726
Min:     0
Max:     0
Average: 1
```

### Fixed output

```
=== Readings Analyser (FIXED) ===
Sum:     287
Min:     7
Max:     91
Average: 35
```

Array: `{23, 17, 45, 8, 91, 34, 62, 7}` — sum=287, min=7, max=91, ⌊287÷8⌋=35 ✓

---

## The Five Bugs at a Glance

| # | Buggy code | Fixed code | Effect of bug |
|---|-----------|-----------|---------------|
| 1 | `mov rcx, 1` | `xor rcx, rcx` | Skips arr[0]=23; off-by-one |
| 2 | `xor r9, r9` | `mov r9, 0x7FFFFFFFFFFFFFFF` | Min sentinel = 0; always wins |
| 3 | `[arr + rcx*4]` | `[arr + rcx*8]` | Wrong stride; reads garbage bytes |
| 4 | `div r8` | `div rbx` | Divides sum÷sum; average always 1 |
| 5 | `jge .no_max` | `jle .no_max` | Inverted branch; max never updated |

Full analysis in **BUGS.md**.  RE methodology in **REVERSE_ENGINEERING.md**.

---

## Debugging Tools Used

### GDB batch inspection

```bash
gdb -batch -x debug.gdb ./buggy
```

Reveals at init: `rcx=1` (Bug 1) and `r9=0` (Bug 2).  
After first load: `r12` contains a garbage value (Bug 3 — stride ×4).

### objdump disassembly

```bash
objdump -d -M intel buggy
```

Key findings:
- `[rcx*4+0x402000]` vs expected `[rcx*8+...]` — confirms Bug 3  
- `jge .no_max` vs `jle` in fixed — confirms Bug 5

### readelf section headers

```bash
readelf -S buggy
```

Confirms binary structure: `.text` / `.data` / `.bss` at expected addresses;
no dynamic linker, direct syscalls only.

---

## Deliverables Checklist

- [x] **a)** Buggy and fixed source files: `buggy.asm`, `fixed.asm`
- [x] **b)** Bug identification table with root causes: `BUGS.md`
- [x] **c)** Debugging session evidence (GDB + objdump): `run.sh` output, `BUGS.md §Evidence`
- [x] **d)** Reverse engineering analysis: `REVERSE_ENGINEERING.md`
- [x] **e)** Before/after output comparison: this README
