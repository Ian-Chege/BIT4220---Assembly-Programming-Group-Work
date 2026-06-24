# Task 4: Control Structures Translator
## BIT 4220 Assembly Programming — Group Work

---

## Overview

A programming lecturer wants students to see how common high-level
constructs translate directly into assembly.  This program implements
five classic control structures in x86-64 NASM, themed as a prepaid
utility-meter control module.

Each demo prints annotations showing which branch was taken and why,
so the student can see the instruction pointer's journey in real time.

---

## Files

| File | Purpose |
|------|---------|
| `control.asm` | All five control-structure demos (deliverable a) |
| `run.sh` | Assemble, link, and run in Docker/Colima |
| `PSEUDOCODE.md` | Pseudocode + side-by-side assembly translation (deliverable a) |
| `TEST_CASES.md` | Test cases targeting every branch outcome (deliverable c) |
| This README | Flowcharts and IP discussion (deliverables b, d) |

---

## Quick Start

```bash
chmod +x run.sh
./run.sh
```

---

## Flowcharts

### Demo 1 — IF-ELSE (Balance Classifier)

```
        ┌──────────────────────┐
        │   read balance        │
        └──────────┬───────────┘
                   │
         ┌─────────▼──────────┐
         │  balance >= 200 ?  │──── Yes ──► HIGH
         └─────────┬──────────┘
                   │ No
         ┌─────────▼──────────┐
         │  balance >= 100 ?  │──── Yes ──► NORMAL
         └─────────┬──────────┘
                   │ No
         ┌─────────▼──────────┐
         │  balance >= 50  ?  │──── Yes ──► LOW
         └─────────┬──────────┘
                   │ No
                   ▼
                CRITICAL
```

Assembly: each `?` box is a `CMP` instruction; each branch is a `JGE`.
A "No" edge falls through to the next comparison.

---

### Demo 2 — WHILE (Countdown Loop)

```
        ┌──────────────────┐
        │     N = input     │
        └────────┬─────────┘
                 │
     ┌───────────▼───────────┐  ◄── condition checked HERE
     │      N > 0 ?          │──── No ──► EXIT
     └───────────┬───────────┘
                 │ Yes
        ┌────────▼──────────┐
        │  print N; N -= 1  │
        └────────┬──────────┘
                 │
                 └─────────────────────► (back to condition)
```

Assembly: the diamond maps to `CMP rcx, 0 / JLE .done`.
The loop-back arrow maps to `JMP .top`.

---

### Demo 3 — DO-WHILE (Input Validation)

```
                  ┌──────────────────────────┐
                  │  (body runs first!)       │  ◄── loop starts here
                  ├──────────────────────────┤
                  │  print prompt; read n     │
                  └──────────────┬───────────┘
                                 │
            condition checked ──►│
                  ┌──────────────▼───────────┐
                  │  n < 1  OR  n > 5 ?       │──── No ──► EXIT (accept n)
                  └──────────────┬───────────┘
                                 │ Yes
                                 └────────────────► (back to top of body)
```

Assembly: the body label comes first with no comparison.
`CMP / JB / JA` at the bottom jump back when the condition is true.
The "No" edge falls through — the loop exits.

---

### Demo 4 — FOR (Tariff Rate Table)

```
       ┌───────────────────┐
       │   i = 1  (init)   │
       └─────────┬─────────┘
                 │
    ┌────────────▼────────────┐  ◄── condition checked HERE
    │       i <= N ?           │──── No ──► EXIT
    └────────────┬────────────┘
                 │ Yes
       ┌─────────▼──────────┐
       │  print [i=i] cost   │
       └─────────┬──────────┘
                 │
       ┌─────────▼──────────┐
       │      i++  (incr)    │
       └─────────┬──────────┘
                 │
                 └────────────────────► (back to condition)
```

Assembly:
- Init  : `MOV rcx, 1`
- Cond  : `CMP rcx, rbx / JG .done`
- Body  : print loop
- Incr  : `INC rcx`
- Back  : `JMP .for_top`

---

### Demo 5 — SWITCH (Device Status)

```
       ┌──────────────────────────┐
       │      read code            │
       └─────────────┬────────────┘
                     │
       ┌─────────────▼────────────┐
       │      code > 4 ?           │──── Yes ──► DEFAULT
       └─────────────┬────────────┘
                     │ No
       ┌─────────────▼────────────┐
       │  JMP [table + code×8]    │  ← single O(1) dispatch
       └──┬──────┬───┬───┬────┬──┘
          │      │   │   │    │
        case0  case1 2   3  case4
          │      │   │   │    │
          └──────┴───┴───┴────┘
                     │
                   DONE
```

The jump table is an array of 8-byte code addresses stored in `.data`.
The linker fills in the absolute virtual addresses at link time.

---

## How the Instruction Pointer Changes

The **instruction pointer (RIP)** is a 64-bit register that always holds
the virtual address of the *next* instruction to fetch and execute.

### Normal sequential execution
```
address  instruction
0x401050  MOV rcx, rax    ; RIP becomes 0x401053 (next)
0x401053  CMP rcx, 0      ; RIP becomes 0x401056
0x401056  JLE 0x401080    ; if taken: RIP ← 0x401080
                           ; if not taken: RIP ← 0x401058
```

### Conditional jumps (IF, WHILE, FOR, DO-WHILE)
`JGE`, `JLE`, `JB`, `JA` etc. test flags set by the most recent
`CMP` and change RIP only if the flags match.  If the condition is
false, RIP advances to the next instruction as normal.

### Unconditional jump (loop-back, break)
`JMP label` always sets RIP to the target address — it is how a
`while` loop returns to its condition check, and how each `case`
in a switch exits after its body.

### Indirect jump (switch jump table)
`JMP [rbx + rax*8]` reads a 64-bit value from memory and loads it
into RIP.  The CPU does not know the target until the memory read
completes — this is why the CPU's branch predictor must *speculate*
on which case will be taken (a vulnerability class exploited by
Spectre attacks in 2018).

### CALL and RET (procedure calls inside demos)
`CALL print_str` pushes `RIP + sizeof(CALL)` onto the stack and
sets RIP to `print_str`.  `RET` pops that saved address back into
RIP, returning control to the instruction after the CALL.

---

## Comparing High-Level and Low-Level Control Flow

| High-level (C/Python) | Assembly mechanism |
|------------------------|-------------------|
| `if (a >= b)` | `CMP a, b` → `JL` (jump if NOT ≥) to else block |
| `while (cond)` | label at top + conditional jump past body |
| `do { } while (cond)` | body first + conditional jump BACK to body |
| `for (i=0; i<N; i++)` | init before loop + while-style loop + INC at bottom |
| `switch (x) { case N: ... }` | jump table (`JMP [table+x*8]`) or compare chain |
| `break` | `JMP` past the end of the loop/switch |
| `continue` | `JMP` to the loop condition check (top of loop) |
| `return` | `RET` — pops return address from stack into RIP |

The key insight: **high-level control structures are an abstraction layer**.
The compiler (or assembler programmer) mechanically converts them into
CMP + conditional JMP sequences.  Reading assembly is therefore the skill
of recognising these patterns in reverse.

---

## Build Details

```bash
# Assemble into ELF64 object file
nasm -f elf64 control.asm -o control.o

# Link: no shared libraries, _start is the entry point
ld control.o -o control

# Run
./control
```

The jump table (`sw_jmptbl dq sw_case0, ...`) requires the linker to fill
in the actual 64-bit virtual addresses of the case labels.  This is handled
via ELF relocation entries created by NASM and resolved by `ld` at link time.
The same mechanism is used by C compilers for dense switch statements.

---

## Deliverables Checklist

- [x] **a)** Source code (`control.asm`) + pseudocode + translation notes (`PSEUDOCODE.md`)
- [x] **b)** ASCII flowchart for each construct (this README)
- [x] **c)** Test cases covering every branch outcome (`TEST_CASES.md`)
- [x] **d)** Instruction-pointer explanation (this README, "How the IP Changes" section)
