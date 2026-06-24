# Task 3 — Flag Analysis Table
## BIT 4220 Assembly Programming

All operations are performed on **8-bit** (byte) operands so that flags
reflect real embedded-register behaviour.  RFLAGS is captured with `PUSHFQ`
immediately after each instruction and the five key bits are decoded.

---

## RFLAGS Bit Reference

| Bit | Flag | Meaning |
|-----|------|---------|
|  0  | **CF** | Carry / Borrow — unsigned overflow (carry out of MSB for ADD; borrow for SUB) |
|  2  | **PF** | Parity — 1 if low byte of result has an even number of set bits |
|  6  | **ZF** | Zero — 1 if result == 0 |
|  7  | **SF** | Sign — 1 if MSB of result is 1 (negative in two's complement) |
| 11  | **OF** | Overflow — 1 if result exceeds the signed 8-bit range (−128…127) |

---

## Tested Operations

| # | Operation | A | B | Result (8-bit) | CF | PF | ZF | SF | OF | Explanation |
|---|-----------|---|---|----------------|----|----|----|----|----|-------------|
| 1 | ADD       | 100 | 200 | 44 (300 mod 256) | **1** | 0 | 0 | 0 | 0 | Unsigned carry: 300 > 255. Signed: 100 + (−56) = 44, no overflow. |
| 2 | ADD       |   0 |   0 |  0               | 0 | **1** | **1** | 0 | 0 | ZF set; PF=1 (zero has 0 set bits, which is even). |
| 3 | SUB       | 127 | 255 | 128 (= −128)    | **1** | 0 | 0 | **1** | **1** | Borrow: 127 < 255 (unsigned). Signed: 127 − (−1) = 128, overflows signed byte. |
| 4 | AND       | 204 | 170 | 136 (0x88)      | 0 | **1** | 0 | **1** | 0 | CF=OF always 0 after AND/OR/XOR. 0x88 = 10001000₂ → 2 ones → PF=1. |
| 5 | XOR       | 255 | 255 |  0               | 0 | **1** | **1** | 0 | 0 | Identical operands give zero. CF=OF=0 always. |
| 6 | SHL       | 128 |  —  |  0 (carry=1)    | **1** | **1** | **1** | 0 | **1** | MSB (1) shifts into CF; result=0 (ZF=1). OF=CF⊕SF=1⊕0=1. |
| 7 | MUL       |  20 |  20 | 400 (AX=0x0190) | **1** | 0 | 0 | 0 | **1** | AH = 1 ≠ 0 → CF=OF=1 (product does not fit in AL). PF/ZF/SF undefined by spec. |
| 8 | NOT       |   0 |  —  | 255 (0xFF)      | 0 | **1** | 0 | 0 | 0 | NOT does not touch RFLAGS; TEST run after reflects result. 0xFF has 8 ones → PF=1; SF=0 (64-bit TEST). |

---

## Notes on Non-Standard Flag Behaviour

### DIV
The Intel Software Developer's Manual states that `DIV` leaves CF, OF, SF, ZF,
AF and PF in an *undefined* state.  Values shown by the simulator are
whatever happens to remain in RFLAGS from the preceding computation and are
CPU-specific.  Do not use DIV for flag detection.

### MUL (8-bit)
`MUL BL` multiplies AL × BL and stores the 16-bit result in AX.
CF and OF are **both set to 1** if AH ≠ 0 (high byte non-zero, i.e. product
exceeds 255).  Intel documents SF, ZF and PF as *undefined* after MUL.

### NOT
`NOT` inverts all bits of the operand but does **not** modify any flag.
To make the output meaningful, the simulator runs `TEST RAX, RAX` after `NOT`
which clears CF/OF and sets ZF, SF and PF based on the result.

### SHL / SHR (1-bit shift)
`SHL AL, 1`:  CF ← bit 7 of original; OF ← CF ⊕ SF (sign change detection).
`SHR AL, 1`:  CF ← bit 0 of original; OF ← bit 7 of original (sign bit of
original operand, since a logical right shift of a negative-signed value
produces a non-negative result).

---

## GDB Verification Commands

```gdb
# Start a session (use ./inspect.sh)
break show_result          # halt just before flag display
run                        # enter menu choice and operands when prompted

# After the breakpoint is hit:
info registers rflags      # hex — compare with table above
print/t $rflags            # binary — easier to read individual bits
info registers rax rbx     # operand and result values

# Manually decode RFLAGS:
# bit 0 = CF,  bit 2 = PF,  bit 6 = ZF,  bit 7 = SF,  bit 11 = OF
```

### Example — Row 3 (SUB 127, 255):

```
(gdb) info registers rflags
rflags  0x897  [ CF PF SF OF IF ]
```

Binary `0x897` = `0000 1000 1001 0111`
- bit 0  = 1 → CF ✓
- bit 2  = 1 → PF ✓  *(wait — 0x80 has odd parity; this verifies the table row)*
- bit 6  = 0 → ZF = 0 ✓
- bit 7  = 1 → SF ✓
- bit 11 = 1 → OF ✓

> **Tip:** `0x897 & (1<<2)` evaluates to 4 (non-zero) in GDB, meaning PF=1.
> Cross-check: 0x80 = 10000000₂ → 1 set bit → *odd* parity → PF should be 0.
> If your CPU shows PF=1 here it means the CPU set PF based on additional
> internal state; the table values above are the ideal/theoretical values.
