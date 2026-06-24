# Task 2 — Student Marks Processor (x86-64 NASM, Linux)

A command-line routine that processes an array of 10 marks held in memory:
computes total / average / highest / lowest, classifies each mark, and prints
the counts. Demonstrates six addressing modes.

## Contents

| File | Purpose |
|------|---------|
| `marks.asm` | The NASM program (deliverable a). |
| `run.sh` | Build & run any `.asm` file. |
| `inspect.sh` | Dump symbols, bytes, disassembly and the marks array. |
| `MEMORY_MAP.md` | Deliverable (b) — variables, arrays, offsets. |
| `TECHNICAL_NOTES.md` | Task 3 (addressing modes) + deliverable (c) (indexing vs C/Python). |
| `TEST_CASES.md` | Deliverable (d) — boundary tests (0, 39, 40, 69, 70, 100). |

Build environment is shared with Task 1 (see `../Dockerfile`). If you haven't
set it up yet: `brew install colima docker && colima start`.

## Run it

```bash
./run.sh marks.asm
```

Expected output:

```
=== Task 2: Student Marks Processor ===
marks[0] via INDIRECT [rbx]      = 0
marks[5] via BASED    [rbx+5]    = 70
Total mark .................. 563
Average mark ................ 56
Highest mark ................ 100
Lowest mark ................. 0
Fail        (0-39) .......... 2
Pass        (40-49) ......... 2
Credit      (50-69) ......... 3
Distinction (70-100) ........ 3
```

## Inspect memory (for the memory map + screenshots)

```bash
./inspect.sh marks.asm
```

Prints the symbol table (addresses/offsets), the raw `.data` bytes, the
disassembly (where you can see each addressing mode), and the 10 marks dumped
straight from memory.

## How it works (short version)

1. `marks` is 10 bytes in `.data`. A single loop walks it with **indexed**
   addressing `[marks + rcx]`.
2. Running total in `r8`, highest in `r9`, lowest in `r10` (**register** mode).
3. Each mark is compared against literal thresholds (**immediate** mode) and the
   matching counter in `.bss` is incremented (**direct** mode).
4. A short demo block shows **indirect** `[rbx]` and **based** `[rbx + 5]`.
5. `print_uint` converts a number to ASCII by repeated division by 10.

Full detail in `TECHNICAL_NOTES.md` and `MEMORY_MAP.md`.

## Deliverables checklist

- [x] (a) Working NASM program — `marks.asm`
- [x] (b) Memory map — `MEMORY_MAP.md`
- [x] (c) Assembly vs C/Python indexing commentary — `TECHNICAL_NOTES.md`
- [x] (d) Boundary test cases — `TEST_CASES.md`
- [ ] Screenshots (if required by your submission) — run `./inspect.sh` and capture
