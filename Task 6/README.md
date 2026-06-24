# Task 6: String & Array Toolkit for Log Cleaning
## BIT 4220 Assembly Programming — Group Work

---

## Overview

A helpdesk receives text logs from legacy prepaid utility meter devices.
This toolkit provides five byte-level string operations that can be applied
interactively to any of five pre-loaded sample log strings.

Operations demonstrate low-level techniques common in log parsing, packet
inspection and embedded diagnostics: single-scan character classification,
two-pointer in-place reversal, brute-force substring search, and direct
ASCII arithmetic for case conversion.

---

## Files

| File | Purpose |
|------|---------|
| `toolkit.asm` | Source code: all 5 procedures + interactive driver |
| `run.sh` | Assemble, link, and run inside Docker |
| `ALGORITHM_NOTES.md` | Algorithm explanations + memory diagrams (deliverable c) |
| `TEST_CASES.md` | Test cases for all operations (deliverable d) |
| This README | Overview + before/after evidence (deliverables a, b) |

---

## Quick Start

```bash
chmod +x run.sh
./run.sh
```

The program shows a menu of 5 sample logs.  Select a log, then choose any
combination of operations.  The working buffer persists between operations
so effects compound (e.g. to_upper then reverse).

---

## Procedures

| Procedure | Signature | Registers saved |
|-----------|-----------|----------------|
| `to_upper` | `(buf: rdi)` in-place | none (caller-saved only) |
| `str_rev` | `(buf: rdi)` in-place | rbx, r12 |
| `char_count` | `(buf: rdi)` → globals | none |
| `kw_search` | `(hay: rdi, needle: rsi) → rax` | rbx, r12 |
| `copy_str` | `(dst: rdi, src: rsi)` | none |

`char_count` writes results to BSS globals `cnt_letters`, `cnt_digits`,
`cnt_spaces`, `cnt_specials` (each a 64-bit quadword).

---

## Before / After Evidence

### Log 1 — `to_upper`

```
Before: ERR: meter fault at 09:42 -- device #mtr-001
After:  ERR: METER FAULT AT 09:42 -- DEVICE #MTR-001
```

Only the lowercase letters `meter fault at device mtr` changed.
Digits (`09:42`), colons, hyphens, and `#` were untouched.
Uppercase `ERR` was also untouched (already in `['A','Z']`).

### Log 1 — `reverse` (applied after to_upper)

```
Before: ERR: METER FAULT AT 09:42 -- DEVICE #MTR-001
After:  100-RTM# ECIVED -- 24:90 TA TLUAF RETEM :RRE
```

Every character is present; reading the result right-to-left
reconstructs the original. The two-pointer swap exchanged
characters symmetrically around the midpoint at position 22 (`A`),
which was not swapped.

### Log 1 — `char_count` (after to_upper + reverse)

```
Letters:  24
Digits:   7
Spaces:   7
Specials: 6
Total:    44
```

Note: `char_count` is case-insensitive in its categorisation
(both `'A'` and `'a'` count as letters), so `to_upper` does not
change the letter count — only the visual representation.

### Log 1 — `kw_search` (after to_upper)

```
Keyword: meter
"meter" not found in log.
```

```
Keyword: METER
Found "METER" at offset 5
```

This demonstrates that `kw_search` is **case-sensitive**: after
`to_upper` converts the log to uppercase, the lowercase keyword
`"meter"` no longer matches.

### Log 2 — `to_upper`

```
Before: warn: low credit balance detected (5 units left)
After:  WARN: LOW CREDIT BALANCE DETECTED (5 UNITS LEFT)
```

All 37 lowercase letters converted; the digit `5` and the
parentheses `()` were untouched.

### Log 2 — `char_count` (after to_upper)

```
Letters:  37
Digits:   1
Spaces:   7
Specials: 3
Total:    48
```

### Log 4 — empty string (all operations)

```
to_upper:   [no output — nothing to print]
reverse:    [no output — nothing to print]
char_count: Letters=0  Digits=0  Spaces=0  Specials=0  Total=0
search "x": "x" not found in log.
```

---

## Build Details

```bash
# Assemble
nasm -f elf64 toolkit.asm -o toolkit.o

# Link
ld toolkit.o -o toolkit

# Run interactively
./toolkit
```

### Single-byte stdin design

Unlike the menu programs in Tasks 3–5, the `read_uint` and `read_line`
procedures in this toolkit read stdin **one byte at a time** using
`sys_read(0, buf, 1)`.  This is necessary because when stdin is a pipe
(e.g. in CI scripts), a multi-byte `sys_read` can consume several lines
of input in a single call, causing subsequent menu prompts to see EOF.

The cost is one extra syscall per character.  For interactive menu use
with single-digit selections the overhead is imperceptible.

---

## Deliverables Checklist

- [x] **a)** Source code: `toolkit.asm` (5 procedures + interactive driver)
- [x] **b)** Before/after output evidence (this README, "Before / After Evidence" section)
- [x] **c)** Algorithm explanation with memory diagrams: `ALGORITHM_NOTES.md`
- [x] **d)** Test cases with normal, empty, long and mixed-character strings: `TEST_CASES.md`
- [x] All smoke tests pass; output verified against expected values
