# Task 8 — Bug Table
## BIT 4220 Assembly Programming | Group Work

---

## The Five Planted Bugs

| # | Location | Buggy instruction | Fixed instruction | Symptom | Root cause |
|---|----------|-------------------|-------------------|---------|------------|
| 1 | `_start` init | `mov rcx, 1` | `xor rcx, rcx` | arr[0]=23 is never added to the sum | Loop index starts at 1; off-by-one skips first element |
| 2 | `_start` init | `xor r9, r9` | `mov r9, 0x7FFFFFFFFFFFFFFF` | Min always prints 0 | Min sentinel = 0 always beats real readings (23, 17, 8, 7…) |
| 3 | `.loop` load | `[arr + rcx*4]` | `[arr + rcx*8]` | Sum = 691 489 734 726 (garbage) | Array elements are 8-byte qwords; stride ×4 reads into the middle of elements and padding |
| 4 | average `div` | `div r8` | `div rbx` | Average always prints 1 | Divides sum÷sum (self-division) — result is always exactly 1 unless sum=0 |
| 5 | `.no_max` branch | `jge .no_max` | `jle .no_max` | Max always prints 0 | Condition inverted: "jump if new ≥ current" skips the update when a larger element is found; only updates when a smaller value appears, which never happens since max starts at 0 |

---

## Interaction Effects

Bugs 3 and 1 interact: with stride ×4 AND index starting at 1, the load at
`rcx=1` reads `[arr + 4]`, which falls inside the 8-byte `arr[0]` qword
(bytes 4–11 of it), not at `arr[1]`.  The resulting garbage value (~86 billion)
dominates the sum.

Bugs 2 and 5 both corrupt min and max independently; either one alone would
zero out its respective stat.

Bug 4 is entirely independent: even if Bugs 1–3 were fixed and the correct
sum (287) was computed, dividing by r8=287 gives 287÷287 = 1, still wrong.

---

## Evidence from Binary

### GDB snapshot at entry — exposes Bugs 1 & 2

After the five-instruction init sequence (`mov rbx,8 / xor r8,r8 / xor r9,r9 /
xor r10,r10 / mov rcx,1`):

```
rcx = 0x1          ← BUG 1: should be 0x0
r9  = 0x0          ← BUG 2: should be 0x7FFFFFFFFFFFFFFF
```

### objdump — exposes Bug 3 & Bug 5

Buggy loop body (at `40109b`):
```
mov    r12,QWORD PTR [rcx*4+0x402000]   ← BUG 3: scale = 4, not 8
...
jge    4010b6 <_start.no_max>            ← BUG 5: should be jle
```

Fixed loop body (at `4010a0`):
```
mov    r12,QWORD PTR [rcx*8+0x402000]   ✓ scale = 8
...
jle    4010bb <_start.no_max>            ✓ correct comparison
```

Also in the fixed binary:
```
movabs r9,0x7fffffffffffffff             ✓ proper min sentinel
```

### Observed output comparison

| Stat | Buggy | Fixed | Expected |
|------|-------|-------|----------|
| Sum | 691 489 734 726 | 287 | 287 |
| Min | 0 | 7 | 7 |
| Max | 0 | 91 | 91 |
| Average | 1 | 35 | 35 |

Array: `{23, 17, 45, 8, 91, 34, 62, 7}` — sum=287, min=7, max=91, ⌊287÷8⌋=35.
