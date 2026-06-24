# Task 7: File-Based Sensor Data Parser
## BIT 4220 Assembly Programming — Group Work

---

## Overview

An IoT gateway stores energy-meter readings one per line in a plain text
file.  This program reads the file using Linux system calls, parses the
decimal numbers, and prints a summary: record count, sum, minimum, maximum,
and integer average.

---

## Files

| File | Purpose |
|------|---------|
| `parser.asm` | File parser: sys_open → sys_read → parse → sys_write |
| `readings.txt` | Sample input: 9 energy readings |
| `run.sh` | Build + run all three test scenarios |
| `SYSCALL_TRACE.md` | System-call explanation with register usage (deliverable b) |
| `BUFFER_LAYOUT.md` | Buffer layout and parse-state diagrams (deliverable c) |
| This README | Overview + testing evidence (deliverables a, d) |

---

## Quick Start

```bash
chmod +x run.sh
./run.sh
```

Or manually inside the Docker container:
```bash
nasm -f elf64 parser.asm -o parser.o
ld parser.o -o parser
./parser readings.txt
```

---

## Testing Evidence

### TEST 1 — Normal file (`readings.txt`)

Input file contents:
```
23
17
45
8
91
34
62
7
55
```

Program output:
```
=== Sensor Data Parser ===
File:     readings.txt
Records:  9
Sum:      342
Min:      7
Max:      91
Average:  38
```

Verified manually: 23+17+45+8+91+34+62+7+55 = 342; min=7; max=91; 342÷9=38 ✓

---

### TEST 2 — Empty file

```bash
> empty.txt          # create zero-byte file
./parser empty.txt
```

Output:
```
=== Sensor Data Parser ===
File:     empty.txt
Records:  0
  (no numeric readings found)
```

The parse loop exits immediately (0 bytes read).  No sum/min/max/average
is printed since dividing by zero would fault.

---

### TEST 3 — Missing file

```bash
./parser missing.txt
```

Output:
```
Error: cannot open file.
```

`sys_open` returns a negative value (−2 = ENOENT on Linux).
The program detects `rax < 0` via `test rax, rax; js .open_error`,
prints the error message, and exits with code 2.

---

## Design Notes

### Single sys_read assumption

The parser reads the entire file in one `sys_read(fd, filebuf, 4096)`
call.  This is correct for sensor logs that fit in 4096 bytes.
A production implementation would loop on `sys_read` until it returns 0.

### Multi-digit parsing

Numbers are accumulated digit by digit: `r12 = r12 × 10 + (byte − '0')`.
The sentinel value r12 = −1 (0xFFFF…) distinguishes "no digits seen yet"
from "reading = 0".  Any non-digit byte (newline, space, colon) commits the
pending number and resets the accumulator.

### Integer average

`div rbx` (sum ÷ count) performs unsigned 64-bit division and produces the
floor of the average.  For readings.txt: ⌊342 ÷ 9⌋ = 38.

---

## Deliverables Checklist

- [x] **a)** `parser.asm` + `readings.txt` + `run.sh`
- [x] **b)** System-call trace and register usage: `SYSCALL_TRACE.md`
- [x] **c)** Buffer layout diagram: `BUFFER_LAYOUT.md`
- [x] **d)** Testing evidence: missing file, empty file, normal file (this README)
