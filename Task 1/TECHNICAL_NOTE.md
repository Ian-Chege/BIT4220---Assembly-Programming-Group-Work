# Technical Note: How the CPU Represents Data

*Task 1, Deliverable (c) — BIT 4220 Assembly Programming.*
*Approx. two pages. Evidence drawn from `sizes.asm` in this repository.*

---

## 1. Everything is bits

At the lowest level a computer stores only **bits** — values that are either `0`
or `1`. Bits are grouped into **bytes** of 8 bits. One byte can hold 2⁸ = 256
different patterns, i.e. the values 0–255. A byte has no inherent "meaning"; the
*same* pattern can be read as a number, a letter, or part of a larger value. How
it is interpreted depends entirely on what the program does with it. The rest of
this note covers the four interpretations the toolkit demonstrates.

---

## 2. Binary and hexadecimal

**Binary (base 2)** is how the hardware physically stores data, but long runs of
1s and 0s are hard for humans to read. **Hexadecimal (base 16)** is a compact
shorthand: each hex digit maps to exactly 4 bits (a "nibble"), so two hex digits
describe one byte exactly.

| Binary      | Hex   | Decimal |
|-------------|-------|---------|
| `0000 0001` | `0x01`| 1       |
| `0100 0001` | `0x41`| 65      |
| `1111 1111` | `0xFF`| 255     |

Because two hex digits = one byte, programmers read memory dumps in hex. In
`sizes.asm` we write the byte `0x41`; that is the bit pattern `01000001`, and the
debugger confirms the stored byte is `0x41`.

---

## 3. ASCII: numbers that mean letters

Text is stored as numbers using a lookup table. **ASCII** assigns each character
a number 0–127. Printable letters sit in a convenient block:

| Char | `A` | `B` | `C` | `D` | … |
|------|-----|-----|-----|-----|---|
| Hex  | `0x41` | `0x42` | `0x43` | `0x44` | … |
| Dec  | 65  | 66  | 67  | 68  | … |

This is why `sizes.asm` stores the *number* `0x41` but prints the *letter* `A` —
the `write` system call hands the byte to the terminal, which looks it up in the
ASCII table. **The byte never changed; only the interpretation did.** This single
idea — that data has no type until something interprets it — underpins reverse
engineering and digital forensics.

---

## 4. Data sizes: byte, word, doubleword

x86 works with data in fixed sizes. NASM declares them with `db` / `dw` / `dd`:

| Term        | Bits | Bytes | NASM | Example value |
|-------------|------|-------|------|---------------|
| Byte        | 8    | 1     | `db` | `0x41`        |
| Word        | 16   | 2     | `dw` | `0x4241`      |
| Doubleword  | 32   | 4     | `dd` | `0x44434241`  |
| Quadword    | 64   | 8     | `dq` | (a full register) |

Larger sizes simply hold more bytes, letting the CPU move and compute on more
data per instruction. A 64-bit register such as `rax` holds a quadword.

---

## 5. Little-endian storage (the key result)

When a value spans more than one byte, the CPU must choose an order to store
those bytes in memory. x86 is **little-endian**: it stores the *least
significant* byte at the *lowest* address — effectively "backwards" from how we
write the number.

We declared:

```asm
myDword  dd  0x44434241     ; value as written, high byte → low byte: 44 43 42 41
```

But `objdump` and `gdb` show it stored in memory as:

```
0x402093:  0x41  0x42  0x43  0x44      ; lowest byte (0x41) first
```

So the bytes appear in the order `41 42 43 44`. Reading those as ASCII
left-to-right spells **`ABCD`** — which is exactly what the program prints. The
"reversal" is not a bug; it is the defining behaviour of a little-endian machine,
and recognising it is essential when inspecting memory dumps or network packets
(many network protocols, by contrast, are big-endian).

**Evidence (from `./inspect.sh sizes.asm`):**

```
Contents of section .data:
 ...
 402090 41414241 424344    AABABCD       <- 41 | 4142 | 41424344
```

---

## 6. Two's complement: storing negative numbers

The interpretations above cover non-negative values. To represent **signed**
(possibly negative) integers, x86 uses **two's complement**. In an *n*-bit value
the top bit is the sign (1 = negative). To negate a number you flip every bit and
add 1.

Example in a single byte:

| Value | Binary      | Hex   |
|-------|-------------|-------|
| `+1`  | `0000 0001` | `0x01`|
| `0`   | `0000 0000` | `0x00`|
| `-1`  | `1111 1111` | `0xFF`|
| `-128`| `1000 0000` | `0x80`|

Two's complement is used because ordinary binary addition then "just works" for
both positive and negative numbers — the CPU needs no separate subtraction logic,
and there is only one representation of zero. An 8-bit two's-complement byte
therefore covers −128 to +127 (instead of 0 to 255 for an unsigned byte). The
identical byte `0xFF` is `255` when read as unsigned but `−1` when read as signed
— another illustration that meaning comes from interpretation, not from the bits.

---

## 7. Why this matters

| Field | Why low-level representation matters |
|-------|--------------------------------------|
| Reverse engineering | Reading raw bytes/registers to understand unknown code |
| Digital forensics | Recovering and interpreting data from memory/disk images |
| Exploit analysis | Crafting and reading byte-exact payloads and addresses |
| Firmware inspection | Decoding binary blobs with no source available |
| Debugging | Understanding what a program *actually* stored vs. intended |

Every one of these skills rests on the same foundation this toolkit demonstrates:
a byte is just a pattern, and **binary, hex, ASCII, signedness, and endianness are
all just different ways of reading the same bits.**
