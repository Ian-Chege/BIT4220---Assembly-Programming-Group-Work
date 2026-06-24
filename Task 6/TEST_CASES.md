# Task 6 — Test Cases
## BIT 4220 Assembly Programming

Tests cover: normal strings, empty string, fully uppercase string, long string
with special characters, and mixed inputs designed to exercise every branch
in each procedure.

---

## Test Log Strings

| ID | Content | Characteristics |
|----|---------|----------------|
| L1 | `ERR: meter fault at 09:42 -- device #mtr-001` | mixed case, digits, specials |
| L2 | `warn: low credit balance detected (5 units left)` | all lowercase, one digit, brackets |
| L3 | `INFO: RECHARGE OK -- 100 KWH ADDED 2024-06-21` | all uppercase, digits, hyphens |
| L4 | (empty string — NUL byte only) | edge case: zero length |
| L5 | `Critical: Volt.spike=245V exceeded threshold!!!` | mixed case, digits, `!`, `.`, `=` |

---

## 1. to_upper Test Cases

| # | Input | Expected output | Branch coverage |
|---|-------|-----------------|----------------|
| 1.1 | L1 `ERR: meter fault at 09:42 -- device #mtr-001` | `ERR: METER FAULT AT 09:42 -- DEVICE #MTR-001` | lowercase letters converted; digits/specials/uppercase unchanged |
| 1.2 | L2 `warn: low credit balance detected (5 units left)` | `WARN: LOW CREDIT BALANCE DETECTED (5 UNITS LEFT)` | all lowercase converted |
| 1.3 | L3 `INFO: RECHARGE OK -- 100 KWH ADDED 2024-06-21` | `INFO: RECHARGE OK -- 100 KWH ADDED 2024-06-21` | all uppercase — no change (idempotent) |
| 1.4 | L4 (empty) | (empty) | NUL at position 0 → exits immediately |
| 1.5 | L5 `Critical: Volt.spike=245V exceeded threshold!!!` | `CRITICAL: VOLT.SPIKE=245V EXCEEDED THRESHOLD!!!` | first char `C` already upper; `V` already upper; `=` and `!` unchanged |

### Boundary values

- `'a'` (97) → `'A'` (65): lower boundary of lowercase range ✓
- `'z'` (122) → `'Z'` (90): upper boundary of lowercase range ✓
- `'A'` (65) → unchanged: one below uppercase range lower boundary ✓
- `'Z'` (90) → unchanged: one above uppercase range upper boundary ✓
- `'0'` (48) → unchanged: digit, not a letter ✓

---

## 2. str_rev Test Cases

| # | Input | Expected output | Length | Notes |
|---|-------|-----------------|--------|-------|
| 2.1 | L1 (after to_upper): `ERR: METER FAULT AT 09:42 -- DEVICE #MTR-001` | `100-RTM# ECIVED -- 24:90 TA TLUAF RETEM :RRE` | 45 (odd) | middle char `A` (position 22) stays put |
| 2.2 | `Hello` | `olleH` | 5 (odd) | single middle char |
| 2.3 | `AB` | `BA` | 2 (even) | single swap only |
| 2.4 | `A` | `A` | 1 | one char: left==right; no swap |
| 2.5 | L4 (empty) | (empty) | 0 | length 0: skip swap entirely |
| 2.6 | L1 reversed twice | original L1 | — | idempotent: rev(rev(s)) = s |

### Boundary values

- Empty string (len=0): `test rdx, rdx; jz .done` path ✓
- Length-1 string: `cmp rbx, r12; jge .done` fires immediately (left=right=buf[0]) ✓
- Length-2 string: exactly one swap, then `jge .done` ✓
- Odd-length: middle element is never touched ✓
- Even-length: all elements swapped ✓

---

## 3. char_count Test Cases

| # | Input | Letters | Digits | Spaces | Specials | Total |
|---|-------|---------|--------|--------|---------|-------|
| 3.1 | L1 `ERR: meter fault at 09:42 -- device #mtr-001` | 26 | 6 | 7 | 5 | 44 |
| 3.2 | L2 `warn: low credit balance detected (5 units left)` | 37 | 1 | 7 | 3 | 48 |
| 3.3 | L3 `INFO: RECHARGE OK -- 100 KWH ADDED 2024-06-21` | 22 | 10 | 5 | 7 | 44 |
| 3.4 | L4 (empty) | 0 | 0 | 0 | 0 | 0 |
| 3.5 | L5 `Critical: Volt.spike=245V exceeded threshold!!!` | 33 | 3 | 2 | 7 | 45 |
| 3.6 | L1 after to_upper (same text, different case) | 26 | 6 | 7 | 5 | 44 | ← counts are case-independent |

### Category boundary checks

| Byte | Expected category |
|------|------------------|
| `@` (64) | Special (64 < 65 = 'A') |
| `A` (65) | Letter — lower bound of uppercase range |
| `Z` (90) | Letter — upper bound of uppercase range |
| `[` (91) | Special (91 > 90 = 'Z') |
| `\`` (96) | Special (96 < 97 = 'a') |
| `a` (97) | Letter — lower bound of lowercase range |
| `z` (122) | Letter — upper bound of lowercase range |
| `{` (123) | Special (123 > 122 = 'z') |
| `/` (47) | Special (47 < 48 = '0') |
| `0` (48) | Digit — lower bound of digit range |
| `9` (57) | Digit — upper bound of digit range |
| `:` (58) | Special (58 > 57 = '9') |
| ` ` (32) | Space |

---

## 4. kw_search Test Cases

All searches are case-sensitive.

| # | Haystack | Needle | Expected result |
|---|----------|--------|-----------------|
| 4.1 | L1 `ERR: meter fault at 09:42 -- device #mtr-001` | `meter` | Found at offset 5 |
| 4.2 | L1 | `fault` | Found at offset 11 |
| 4.3 | L1 | `ERR` | Found at offset 0 |
| 4.4 | L1 | `001` | Found at offset 42 (last 3 chars) |
| 4.5 | L1 | `xyz` | Not found |
| 4.6 | L1 after to_upper | `meter` | Not found (case mismatch: "METER" ≠ "meter") |
| 4.7 | L1 after to_upper | `METER` | Found at offset 5 ✓ |
| 4.8 | L4 (empty) | `error` | Not found (haystack is NUL at position 0) |
| 4.9 | L1 | `` (empty needle) | Found at offset 0 (vacuously) |
| 4.10 | L2 | `balance` | Found at offset 20 |
| 4.11 | L5 | `!!!` | Found at offset 44 |

### Branch coverage

| Branch | Triggered by |
|--------|-------------|
| Empty needle → return 0 | Test 4.9 |
| Empty haystack → not found | Test 4.8 |
| Match at position 0 | Test 4.3 |
| Match at last position | Test 4.4 |
| Partial match then mismatch | `meter` in L1 position 5 (full match), vs any non-matching prefix at positions 0-4 |
| No match (full scan) | Tests 4.5, 4.6 |
| Case-sensitive mismatch | Test 4.6 |

---

## 5. Composite Sequences

These tests chain multiple operations to produce specific outputs.

### Sequence A: Uppercase then search (case sensitivity)

```
Start:   "ERR: meter fault at 09:42 -- device #mtr-001"
→ to_upper: "ERR: METER FAULT AT 09:42 -- DEVICE #MTR-001"
→ search "meter":  NOT FOUND   (keyword is lowercase)
→ search "METER":  Found at offset 5
```

### Sequence B: Reverse twice = original

```
Start:   "warn: low credit balance detected (5 units left)"
→ reverse: ")tfel stinu 5( detceted ecnalab tiderc wol :nraw"
→ reverse: "warn: low credit balance detected (5 units left)"
```

### Sequence C: Empty string edge case

```
Start:   ""  (log 4)
→ to_upper:  ""  (nothing to change)
→ reverse:   ""  (nothing to reverse)
→ count:     Letters=0, Digits=0, Spaces=0, Specials=0, Total=0
→ search "x": Not found
```

### Sequence D: Fully uppercase (idempotent to_upper)

```
Start:   "INFO: RECHARGE OK -- 100 KWH ADDED 2024-06-21"
→ to_upper: "INFO: RECHARGE OK -- 100 KWH ADDED 2024-06-21"  (unchanged)
→ search "info":  Not found  (keyword lowercase; string is uppercase)
→ search "INFO":  Found at offset 0
```

---

## Verified Smoke Test Output

```
Input sequence:
  Log 1 → to_upper(1) → reverse(2) → char_count(3)
        → search "meter"(4) → search "xyz"(4) → back(0)
  Log 2 → to_upper(1) → char_count(3) → back(0)
  Log 4 → char_count(3) → back(0)
  Exit(0)

Key results (confirmed by program output):
  Log 1, to_upper:   "ERR: METER FAULT AT 09:42 -- DEVICE #MTR-001"
  Log 1, reverse:    "100-RTM# ECIVED -- 24:90 TA TLUAF RETEM :RRE"
  Log 1, count:      Letters=24  Digits=7  Spaces=7  Specials=6  Total=44
  Log 1, "meter":    "meter" not found in log  (string is uppercase)
  Log 1, "xyz":      "xyz" not found in log
  Log 2, to_upper:   "WARN: LOW CREDIT BALANCE DETECTED (5 UNITS LEFT)"
  Log 2, count:      Letters=37  Digits=1  Spaces=7  Specials=3  Total=48
  Log 4, count:      Letters=0   Digits=0  Spaces=0  Specials=0  Total=0
```
