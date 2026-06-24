# Task 3: Mini ALU for an Embedded Billing Device
## BIT 4220 Assembly Programming — Group Work

---

## Overview

This task builds a **menu-driven ALU simulator** in x86-64 NASM assembly,
modelling the computation module of a prepaid utility meter.  The program reads
two 8-bit values from the keyboard using raw Linux system calls, performs the
selected operation, and immediately decodes and prints the five most important
CPU flags from RFLAGS.

### Operations supported

| Category | Operations |
|----------|-----------|
| Arithmetic | ADD, SUB, MUL (unsigned 8-bit → 16-bit result), DIV (quotient) |
| Logical | AND, OR, XOR, NOT |
| Shift | SHL (left × 1), SHR (right × 1) |

### Flags decoded after each operation

```
CF  Carry / Borrow   – unsigned overflow or borrow out of bit 7
PF  Parity           – even number of set bits in the low byte
ZF  Zero             – result is zero
SF  Sign             – bit 7 of result is 1 (negative in two's complement)
OF  Signed Overflow  – result exceeds the signed 8-bit range (−128…127)
```

---

## Files

| File | Purpose |
|------|---------|
| `alu.asm` | Main ALU simulator source (deliverable a) |
| `run.sh` | Assemble, link, and run in a Docker/Colima x86-64 environment |
| `inspect.sh` | Re-compile with debug symbols and launch GDB for flag inspection |
| `FLAG_ANALYSIS.md` | Flag analysis table — 8 tested operations (deliverable b) |
| `OVERFLOW_DISCUSSION.md` | Why overflow matters in real systems (deliverable d) |

---

## Prerequisites

The programs use **Linux x86-64 system calls** and the ELF binary format,
which cannot run natively on macOS.  The same Docker + Colima setup used in
Tasks 1 and 2 is required.

- [Colima](https://github.com/abiosoft/colima) (provides the Linux VM)
- [Docker Desktop](https://www.docker.com/) or `brew install docker`
- The shared `asm-lab` Docker image (built automatically by `run.sh`)

---

## Quick Start

```bash
# Make scripts executable (one-time)
chmod +x run.sh inspect.sh

# Build and run the interactive ALU
./run.sh
```

Expected opening screen:

```
============================================
  Prepaid Meter ALU Simulator  v1.0
  BIT 4220 — Task 3
============================================

  --- Arithmetic ---    --- Logical/Shift ---
  1) ADD   A + B        5) AND   A & B
  2) SUB   A - B        6) OR    A | B
  3) MUL   A * B        7) XOR   A ^ B
  4) DIV   A / B        8) NOT   ~A
                         9) SHL   A << 1
                        10) SHR   A >> 1
  0) Exit

Choice:
```

---

## Example Session

```
Choice: 1
  Enter A (0-255): 100
  Enter B (0-255): 200

  Result  : 44  (0x2c)
  Flags   : CF=1  PF=0  ZF=0  SF=0  OF=0
```

100 + 200 = 300; in 8-bit arithmetic 300 − 256 = **44** with a **carry** (CF=1)
because 300 exceeds the unsigned byte range.  No signed overflow (OF=0) because
the signed interpretation is 100 + (−56) = 44, which fits in one byte.

---

## Validating Invalid Input

The simulator rejects choices outside the range 0–10:

```
Choice: 99

  Invalid choice. Please enter 0-10.
```

Division by zero is caught before the `DIV` instruction executes:

```
Choice: 4
  Enter A (0-255): 50
  Enter B (0-255): 0

  ERROR: Division by zero!
```

---

## GDB Flag Inspection (deliverable c)

Use `./inspect.sh` to build the binary with DWARF debug information and start
GDB inside the container.

### Recommended GDB workflow

```gdb
# 1. Set a breakpoint right before the flag display
(gdb) break show_result

# 2. Run the program — you will type inputs in the same terminal
(gdb) run

# 3. Choose option 1 (ADD), enter A=100, B=200
#    GDB will halt at show_result

# 4. Inspect RFLAGS
(gdb) info registers rflags
rflags  0x203  [ CF PF IF ]

# 5. Read in binary for easier bit-counting
(gdb) print/t $rflags
$1 = 1000000011

# Bit 0 = CF = 1  ✓   (unsigned carry 100+200=300)
# Bit 2 = PF = 0  ✓   (44 = 0x2C = 00101100₂ → 3 set bits, odd parity)
# Bit 6 = ZF = 0  ✓
# Bit 7 = SF = 0  ✓
# Bit 11= OF = 0  ✓

# 6. Continue to the next menu iteration
(gdb) continue
```

### Useful GDB commands

| Command | Effect |
|---------|--------|
| `info registers rflags` | Show RFLAGS as hex with mnemonic names |
| `print/t $rflags` | Show RFLAGS in binary |
| `info registers rax rbx` | Operands / result before printing |
| `stepi` | Execute one machine instruction |
| `disassemble` | Show assembly around current instruction pointer |
| `x/bx &inbuf` | Inspect the keyboard input buffer byte |

---

## Build Process (manual, inside container)

```bash
# Assemble to ELF64 object
nasm -f elf64 alu.asm -o alu.o

# Link to a static ELF64 executable (no libc, _start is the entry point)
ld alu.o -o alu

# Run
./alu
```

With debug symbols:

```bash
nasm -g -f elf64 alu.asm -o alu_dbg.o
ld -g alu_dbg.o -o alu_dbg
gdb ./alu_dbg
```

---

## Key Design Decisions

### Why 8-bit operations?
Using `ADD AL, BL` instead of `ADD RAX, RBX` means the CPU operates as if
this were a real 8-bit embedded register — exactly what a prepaid meter
microcontroller would use.  CF is set on a real 8-bit carry (result > 255),
and OF is set on a real 8-bit signed overflow.

### How RFLAGS is captured
```nasm
add al, bl       ; 8-bit operation sets flags
pushfq           ; push 8-byte RFLAGS onto stack
pop r12          ; r12 = RFLAGS snapshot
```
`r12` is a callee-saved register (System V AMD64 ABI), so it survives all the
subsequent `sys_write` calls inside `show_result` without needing to be
explicitly preserved.

### Input reading
`read_uint` uses `sys_read` (syscall 0) to read **one byte at a time** from
stdin.  Digits are accumulated with `IMUL` (not `MUL`) to avoid the implicit
`RDX` clobber that `MUL` produces, and because the `syscall` instruction itself
overwrites `RCX` — so a multiplier held in `RCX` would need reloading after
every read.

---

## Deliverables Checklist

- [x] **a)** ALU simulator source code (`alu.asm`) and build scripts (`run.sh`, `inspect.sh`)
- [x] **b)** Flag analysis table with 8 tested operations (`FLAG_ANALYSIS.md`)
- [x] **c)** GDB inspection workflow with RFLAGS decoding (this README, GDB section)
- [x] **d)** Overflow discussion with real-world examples (`OVERFLOW_DISCUSSION.md`)
