# BIT 4220 Assembly Programming — Group Work
# Task 10: Final Technical Report
# IoT Sensor Log Analyser — Portfolio Demonstration

---

## 1. Introduction

### 1.1 Theme

This portfolio demonstrates how x86-64 assembly programming applies to
**IoT/embedded data processing** — a domain where low-level code remains
relevant because firmware, edge gateways, and microcontrollers often lack
a C runtime, OS services, or the memory budget for high-level language
overhead.

The deliverable is a single self-contained NASM program (`portfolio.asm`)
that implements an IoT gateway utility: it reads a raw sensor log file,
filters entries by field keyword, and computes a statistical summary.  No
C library, no dynamic linker, no runtime — only direct Linux system calls.

### 1.2 Motivation

Modern IoT edge nodes are constrained devices.  A gateway might run a
minimal Linux kernel with a 256 KB filesystem image.  In such environments:

- A C runtime adds ~50–200 KB of overhead.
- Dynamic linking requires a loader that may not exist.
- Hand-crafted assembly can fit in 4 KB, boot in microseconds, and make
  a fixed number of syscalls that are easy to audit.

This program could realistically run on an embedded Linux board (Raspberry Pi,
BeagleBone, custom ARM SoC running an x86 emulator layer) as a lightweight
log processor alongside a network daemon.

### 1.3 Portfolio Integration

Three prior assignments are integrated:

| Module | Origin | Role in Portfolio |
|--------|--------|------------------|
| File I/O | Task 7 | Open, read, and close the sensor log file |
| Keyword search | Task 6 | Filter log lines that contain "TEMP:" |
| Statistics engine | Task 8 | Compute count, sum, min, max, average |

---

## 2. System Architecture

### 2.1 Program Flow

```
argv[1] (filename)
      │
      ▼
  sys_open ──── error? ──► print error, exit 2
      │
      ▼
  sys_read (up to 4096 bytes into filebuf)
      │
      ▼
  sys_close
      │
      ▼
  Scan loop ─────────────────────────────────────────────────────
  │                                                              │
  │  for each byte position r14 in [0, bytes_read):             │
  │    if filebuf[r14..r14+4] == "TEMP:" ?                      │
  │      yes → parse decimal number, update stats, skip line    │
  │      no  → advance one byte                                 │
  │                                                             │
  └─────────────────────────────────────────────────────────────┘
      │
      ▼
  Print results (count / sum / min / max / average)
      │
      ▼
  sys_exit 0
```

### 2.2 Register Map

| Register | Role | Lifecycle |
|----------|------|-----------|
| `r15` | `argv[1]` — filename pointer | Entire program |
| `r12` | File descriptor (then freed) | Open → close block only |
| `r13` | Bytes read from file | After sys_read |
| `r14` | Scan index into filebuf | Scan loop |
| `rbx` | Record count | Stats accumulation |
| `r8`  | Running sum | Stats accumulation |
| `r9`  | Running min (init INT64_MAX) | Stats accumulation |
| `r10` | Running max (init 0) | Stats accumulation |
| `rcx` | Digit accumulator (per record) | parse_digit inner loop |
| `rdx` | Digit count (per record) | parse_digit inner loop |

Callee-saved registers (`rbx`, `r12–r15`) are used for long-lived state;
caller-saved registers (`rax`, `rcx`, `rdx`, `rdi`, `rsi`) are used for
transient per-call values, consistent with the System V AMD64 ABI.

### 2.3 Memory Layout

```
Section   Address      Size    Contents
.text     0x401000     ~0x3C0  print_str, print_filename,
                               print_uint_noeol, print_uint, _start
.data     0x402000     0x8C    String literals (banner, labels, error msg, newline)
.bss      0x40208C     0x1018  filebuf (4096 B) + numbuf (24 B)
```

Total binary footprint: approximately 4.5 KB (including ELF headers).
Runtime heap: zero — no dynamic allocation.
Stack usage: only a few push/pop pairs inside helper functions (~64 bytes).

---

## 3. Module Integration Details

### 3.1 Task 7 — File I/O Pattern

The file-open/read/close sequence is lifted directly from Task 7:

```nasm
mov  r15, [rsp + 16]     ; argv[1]
mov  rax, SYS_OPEN       ; syscall 2
mov  rdi, r15
xor  rsi, rsi            ; O_RDONLY = 0
xor  rdx, rdx
syscall
test rax, rax
js   .open_error         ; negative return → ENOENT / EACCES
mov  r12, rax            ; save fd

mov  rax, SYS_READ       ; syscall 0
mov  rdi, r12
lea  rsi, [filebuf]
mov  rdx, 4096
syscall
; … error clamp …
mov  r13, rax            ; bytes read

mov  rax, SYS_CLOSE      ; syscall 3
mov  rdi, r12
syscall
```

**Adaptation from Task 7:** the parse loop that followed `sys_close` in
Task 7 accumulated all digits it encountered.  Here the loop is replaced
by the keyword-gated scan (§3.2), so only TEMP readings are counted.

### 3.2 Task 6 — Keyword Search Pattern

Task 6's `kw_search` procedure used a two-pointer brute-force scan (outer
loop over the haystack, inner loop matching the needle character by character).
The portfolio inlines a specialised version for the fixed 5-character keyword
`"TEMP:"`, which is faster and simpler than a general-purpose search:

```nasm
; check 5 bytes at current position
lea  rdi, [filebuf + r14]
cmp  byte [rdi],   'T'
jne  .advance_one
cmp  byte [rdi+1], 'E'
jne  .advance_one
cmp  byte [rdi+2], 'M'
jne  .advance_one
cmp  byte [rdi+3], 'P'
jne  .advance_one
cmp  byte [rdi+4], ':'
jne  .advance_one
; match confirmed — extract number
```

Because the keyword is short and fixed, five `cmp`/`jne` instructions
short-circuit on the first mismatch — no inner loop register needed.

**Adaptation from Task 6:** the general `kw_search` returned a match offset;
here the scan loop's `r14` already holds the current position, so an explicit
return value is replaced by a fall-through into the number parser.

### 3.3 Task 8 — Statistics Engine

The statistics block (min/max/sum/count + average at end) is taken verbatim
from Task 8 `fixed.asm` with one register renaming (`rcx` → `rcx` is the
same, but the loaded value comes from the digit accumulator rather than
from `[arr + rcx*8]`):

```nasm
inc  rbx           ; count++
add  r8, rcx       ; sum += val
cmp  rcx, r9       ; min update (Task 8 Fix 2: INT64_MAX sentinel)
jge  .no_min
mov  r9, rcx
.no_min:
cmp  rcx, r10      ; max update (Task 8 Fix 5: jle = skip when ≤)
jle  .no_max
mov  r10, rcx
.no_max:
```

**Adaptation from Task 8:** the data source changes from an in-memory `dq`
array (fixed at assemble time) to runtime-parsed values extracted from the
file.  The division at the end uses `div rbx` (count) unchanged.

---

## 4. Testing Evidence

All four test scenarios are run automatically by `run.sh`.

### Test 1 — Normal log file (`sensors.log`)

Input file structure (mixed fields, comment lines ignored naturally):
```
# IoT Sensor Log — Gateway Node A
TIMESTAMP:0001 TEMP:23 HUM:65 PRESS:1013
TIMESTAMP:0002 TEMP:17 HUM:70 PRESS:1015
…
TIMESTAMP:0008 TEMP:7 HUM:77 PRESS:1016
```

Program output:
```
=== IoT Sensor Log Analyser ===
File:    sensors.log
Records: 8
Sum:     287
Min:     7
Max:     91
Average: 35
```

Verified: 23+17+45+8+91+34+62+7 = 287; min=7; max=91; ⌊287÷8⌋=35 ✓

The result cross-checks against Task 8 `fixed.asm` which operates on the
same eight values stored as a `dq` array.  Both programs produce identical
statistics, confirming the integrated parser is correct.

### Test 2 — Empty file

```
=== IoT Sensor Log Analyser ===
File:    empty.log
Records: 0
  (no TEMP readings found)
```

`sys_read` returns 0; the scan loop exits immediately; the zero-count branch
suppresses sum/min/max/avg output and prevents a divide-by-zero fault.

### Test 3 — File with no TEMP readings

```
=== IoT Sensor Log Analyser ===
File:    notemp.log
Records: 0
  (no TEMP readings found)
```

The keyword filter correctly discards lines containing only `HUM:` and
`PRESS:` fields.  The scan advances through the entire file byte-by-byte
without triggering the number parser.

### Test 4 — Missing file

```
Error: cannot open file.
(exited with code 2)
```

`sys_open` returns −2 (ENOENT).  `test rax, rax; js .open_error` detects
the negative return and writes the error message to stderr (fd 2), then
calls `sys_exit(2)` — the POSIX convention for command-line argument errors.

---

## 5. Debugging and Reverse Engineering

### 5.1 Build with DWARF symbols

```bash
nasm -f elf64 -g -F dwarf portfolio.asm -o portfolio.o
```

This embeds source-line mapping so GDB can display `portfolio.asm` line
numbers alongside the disassembly.

### 5.2 Key GDB inspection points

```gdb
break _start.scan          ; entry to scan loop
condition 1 r14 == 18      ; break when first "TEMP:" is found (byte 18)
info registers r14 rbx r8 r9 r10
```

Expected state after first match commit:
- `r14` has advanced past the digits to the first non-digit character
- `rbx` = 1 (one record found)
- `r8`  = 23 (sum = first reading)
- `r9`  = 23 (min updated from INT64_MAX)
- `r10` = 23 (max updated from 0)

### 5.3 objdump verification

The disassembly of `_start.scan` (shown in run.sh output) confirms:
- `cmp BYTE PTR [rdi], 0x54` — `0x54` = ASCII `'T'` ✓
- `cmp BYTE PTR [rdi+4], 0x3a` — `0x3a` = ASCII `':'` ✓
- `jle` at the max-update branch — correct direction (skip when ≤) ✓
- `div rbx` — divides by count, not sum ✓

---

## 6. Performance and Memory Discussion

### 6.1 Time complexity

The scan is O(n) in the file size — each byte is examined at most once.
The keyword check at each position is O(1) (at most 5 comparisons, first
mismatch exits).  There is no nested loop; the overall algorithm is
equivalent to a single-pass lexer.

For the 8-record test file (~230 bytes), the program makes exactly:
- 1 × sys_open
- 1 × sys_read
- 1 × sys_close
- 4–5 × sys_write (banner + 4 stat lines)
- 1 × sys_exit

A C equivalent using `fopen`/`fscanf`/`printf` would issue dozens of
additional syscalls for buffered I/O setup, locale initialisation, and the
C runtime startup sequence.

### 6.2 Memory usage

| Region | Size | Notes |
|--------|------|-------|
| `.text` (code) | ~960 B | All helpers + `_start` |
| `.data` (strings) | 140 B | Labels, banner, error message |
| `.bss` (buffers) | 4120 B | `filebuf` (4096) + `numbuf` (24) |
| Stack (runtime) | ~128 B | push/pop pairs in helpers |
| **Total** | **~5.5 KB** | vs. ~300 KB for a typical C hello-world |

No heap allocation.  No malloc.  No garbage.  The entire program fits
comfortably in the L1 instruction cache of any modern processor.

### 6.3 Scalability limit

The single `sys_read(fd, filebuf, 4096)` call limits the input to 4096 bytes.
For production use, the read would be wrapped in a loop that appends into a
larger buffer (or processes line by line), and `filebuf` would be in heap
memory allocated via `sys_mmap`.  For the IoT scenario (short periodic logs
from a sensor node), 4096 bytes covers several hundred readings per flush.

---

## 7. Trade-off Analysis

| Dimension | Assembly (this program) | Equivalent C + glibc |
|-----------|------------------------|----------------------|
| **Binary size** | ~4.5 KB | ~700 KB (static) / ~8 KB + 2 MB libc (dynamic) |
| **Startup time** | Microseconds (no runtime init) | Milliseconds (libc `_init`, locale, signal setup) |
| **Syscall count** | 7 (minimal, auditable) | 40–80 (libc buffering, locale, etc.) |
| **Readability** | Low — requires ISA knowledge | High — intent is clear from C source |
| **Portability** | x86-64 Linux only | Recompile for any platform |
| **Debugging** | Register/memory inspection, no sanitisers | Source-level, ASAN, valgrind |
| **Correctness risk** | High — manual ABI, no type safety | Low — compiler enforces types |
| **Maintenance** | Expensive — every change requires asm expertise | Cheap |

**Conclusion:** for a production gateway, write the business logic in C and
let the compiler optimise.  Assembly is justified for the inner loop of a
cryptographic hash, a CRC32 over megabytes of sensor data, or for a bootstrap
stub that runs before the C runtime exists.  This portfolio demonstrates both
the capability and the cost.

---

## 8. Conclusion

The IoT Sensor Log Analyser integrates three independently developed assembly
modules into a cohesive, working program that processes real log data with
measurably low resource consumption.  The integration required:

- Replacing Task 7's digit-accumulating parse loop with a keyword-gated
  version (Task 6 influence) that only commits a record when "TEMP:" precedes
  the number.
- Reusing Task 8's statistics block unchanged, because it was already
  parameterised on a single register value (`rcx`) rather than a fixed array
  address.
- Preserving all error-handling paths from Task 7 (open failure, empty file,
  zero-count divide guard).

The result is a 4.5 KB static binary that starts in microseconds, makes 7
syscalls for a typical run, uses no heap, and produces correct output on all
four test scenarios.  This exemplifies the modern case for hand-written
assembly: not as a replacement for C, but as a precisely controlled tool
for environments where resource budgets and auditability requirements make
high-level abstractions impractical.

---

## References

- Intel 64 and IA-32 Architectures Software Developer's Manual, Vol. 2
- System V AMD64 ABI, Version 1.0
- Linux `man 2` pages: open(2), read(2), write(2), close(2), exit(2)
- NASM 2.x Manual — Effective Addresses, Local Labels, DWARF output
