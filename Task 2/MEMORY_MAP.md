# Memory Map — `marks.asm`

*Task 2, Deliverable (b).* Addresses are the actual link-time addresses produced
by `ld` (regenerate with `./inspect.sh marks.asm`). The program has three
sections: `.text` (code), `.data` (initialised data), `.bss` (uninitialised
data).

## Section overview

| Section | Start address | Size (bytes) | Holds |
|---------|---------------|--------------|-------|
| `.text` | `0x401000` | 566 (`0x236`) | the instructions |
| `.data` | `0x402000` | 361 (`0x169`) | marks array + label strings |
| `.bss`  | `0x40216C` | 60 (`0x3C`) | counters + number buffer |

## The marks array (`.data`, base `0x402000`)

Ten 1-byte values (`db`), so each element is exactly **offset = index** from the
start of the array.

| Index | Offset | Address    | Value (dec) | Value (hex) |
|-------|--------|------------|-------------|-------------|
| `[0]` | +0     | `0x402000` | 0   | `0x00` |
| `[1]` | +1     | `0x402001` | 39  | `0x27` |
| `[2]` | +2     | `0x402002` | 40  | `0x28` |
| `[3]` | +3     | `0x402003` | 55  | `0x37` |
| `[4]` | +4     | `0x402004` | 69  | `0x45` |
| `[5]` | +5     | `0x402005` | 70  | `0x46` |
| `[6]` | +6     | `0x402006` | 85  | `0x55` |
| `[7]` | +7     | `0x402007` | 100 | `0x64` |
| `[8]` | +8     | `0x402008` | 45  | `0x2D` |
| `[9]` | +9     | `0x402009` | 60  | `0x3C` |

`nmarks` is **not** stored in memory — it is an assemble-time constant
(`nmarks equ $ - marks` = 10) baked directly into instructions as an immediate.

## Label strings (`.data`)

Each is a run of ASCII bytes; the matching `*_l`/`len_*` constant is its length.

| Symbol  | Address    | Bytes |
|---------|------------|-------|
| `marks` | `0x402000` | 10 |
| `hdr`   | `0x40200A` | 40 |
| `m_ind` | `0x402032` | 35 |
| `m_bas` | `0x402055` | 35 |
| `m_tot` | `0x402078` | 30 |
| `m_avg` | `0x402096` | 30 |
| `m_hi`  | `0x4020B4` | 30 |
| `m_lo`  | `0x4020D2` | 30 |
| `m_fail`| `0x4020F0` | 30 |
| `m_pass`| `0x40210E` | 30 |
| `m_cred`| `0x40212C` | 30 |
| `m_dist`| `0x40214A` | 30 |
| `nl`    | `0x402168` | 1 |

## Variables (`.bss`, base `0x40216C`)

Uninitialised at assemble time (all zero), written at run time.

| Symbol     | Address    | Offset from `.bss` | Size | Purpose |
|------------|------------|--------------------|------|---------|
| `cnt_fail` | `0x40216C` | +0  | 8 (`resq 1`) | count of Fail marks |
| `cnt_pass` | `0x402174` | +8  | 8 | count of Pass marks |
| `cnt_cred` | `0x40217C` | +16 | 8 | count of Credit marks |
| `cnt_dist` | `0x402184` | +24 | 8 | count of Distinction marks |
| `numbuf`   | `0x40218C` | +32 | 24 (`resb 24`) | scratch buffer for number→text |

## How instructions reach this memory

- `[marks + rcx]` — start address `0x402000` (the displacement) **plus** the
  index in `rcx`. Element `[3]` = `0x402000 + 3` = `0x402003`.
- `[rbx]` / `[rbx + 5]` — `rbx` holds the base `0x402000`; add the displacement
  for based access.
- `[cnt_fail]` — a fixed absolute address (`0x40216C`) encoded in the instruction.

See `TECHNICAL_NOTES.md` for how each addressing mode maps to these accesses.
