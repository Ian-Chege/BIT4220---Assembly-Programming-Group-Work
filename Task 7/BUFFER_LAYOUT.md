# Task 7 — Buffer Layout Diagram
## BIT 4220 Assembly Programming

---

## BSS Section Layout

```
.bss
┌─────────────────────────────────────────────────────────────────┐
│  filebuf   (4096 bytes)                                         │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  [raw file bytes copied here by sys_read]                │   │
│  │  Offset: +0           +4095                              │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  numbuf    (24 bytes)                                           │
│  ┌────────────────────────────────┐                            │
│  │  [ASCII digits for print_uint] │                            │
│  │  Offset: +0     +23            │                            │
│  └────────────────────────────────┘                            │
└─────────────────────────────────────────────────────────────────┘
```

---

## filebuf Contents — readings.txt (36 bytes)

After `sys_read(fd, filebuf, 4096)` returns 36:

```
Byte offset:  0    1    2    3    4    5    6    7
Hex:         32   33   0A   31   37   0A   34   35
ASCII:       '2'  '3'  '\n' '1'  '7'  '\n' '4'  '5'

Byte offset:  8    9   10   11   12   13   14   15
Hex:         0A   38   0A   39   31   0A   33   34
ASCII:       '\n' '8'  '\n' '9'  '1'  '\n' '3'  '4'

Byte offset: 16   17   18   19   20   21   22   23
Hex:         0A   36   32   0A   37   0A   35   35
ASCII:       '\n' '6'  '2'  '\n' '7'  '\n' '5'  '5'

Byte offset: 24   25   ...  35
Hex:         0A   (remaining bytes uninitialised — not read)
ASCII:       '\n'
```

**Numbers encoded**: `23\n17\n45\n8\n91\n34\n62\n7\n55\n`

---

## Parse State Machine — one number per line

The parser maintains a single accumulator register (`r12`) to build
multi-digit numbers as it scans bytes left to right:

```
              byte in filebuf[r14]
                       │
               ┌───────▼───────┐
               │ '0' ≤ b ≤ '9' │──Yes──► r12 = r12 × 10 + (b - '0')
               └───────┬───────┘
                       │ No
               ┌───────▼───────┐
               │  r12 == -1 ?  │──Yes──► skip (no number pending)
               └───────┬───────┘
                       │ No
                 commit r12 → do_record
                 reset r12 = -1
```

**Trace for the first line "23\n"**:

```
r14=0: b='2'(0x32): digit → r12 was -1 → r12=0; then r12=0×10+2=2
r14=1: b='3'(0x33): digit → r12=2×10+3=23
r14=2: b='\n'(0x0A): separator → r12≠-1 → record 23; r12=-1
```

---

## numbuf — Decimal Conversion Scratch Buffer

`print_uint_noeol` converts a 64-bit integer to ASCII right-to-left in
`numbuf`, then prints the relevant slice:

```
After printing "342":

Address:  numbuf+21  numbuf+22  numbuf+23
Byte:        '3'       '4'        '2'
              ↑
          rsi points here (start of the digit string)
          rdx = 3  (character count)

sys_write(1, numbuf+21, 3) → writes "342"
```

The buffer is 24 bytes to accommodate the longest 64-bit decimal value
(20 digits: 18,446,744,073,709,551,615) plus a small safety margin.

---

## Stack Layout During sys_open / sys_read / sys_close

In `_start`, no local variables are allocated on the stack.
The layout on entry to `_start` (set by the OS loader):

```
Higher address
┌─────────────────────────────┐
│  envp[n] (NUL)              │
│  ...                        │
│  envp[0]                    │
│  argv[2] = NULL             │
│  argv[1] = "readings.txt"  ◄── [rsp+16]   → saved to r15
│  argv[0] = "./parser"       ◄── [rsp+8]
│  argc    = 2                ◄── [rsp]      (read first)
└─────────────────────────────┘  ← RSP on _start entry
Lower address
```

The `CALL` instruction is never used to reach `_start`; the kernel
`execve` sets RSP directly, so there is no return address on the stack.
`RSP` is 16-byte aligned by the ABI at `_start` entry.
