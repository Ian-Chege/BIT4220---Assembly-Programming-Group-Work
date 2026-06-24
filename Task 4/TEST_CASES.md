# Task 4 — Test Cases
## BIT 4220 Assembly Programming

Each test case targets a distinct branch outcome or boundary value.

---

## Demo 1 — IF-ELSE Test Cases

| # | Input (balance) | Expected branch | Expected output |
|---|----------------|-----------------|-----------------|
| 1 | 255 | `balance >= 200` → true (first if) | `HIGH    (balance >= 200)` |
| 2 | 200 | `balance >= 200` → true (boundary) | `HIGH    (balance >= 200)` |
| 3 | 199 | first false; `balance >= 100` → true | `NORMAL  (100 <= balance < 200)` |
| 4 | 100 | first false; second true (boundary) | `NORMAL  (100 <= balance < 200)` |
| 5 |  99 | first+second false; `balance >= 50` → true | `LOW     (50 <= balance < 100)` |
| 6 |  50 | first+second false; third true (boundary) | `LOW     (50 <= balance < 100)` |
| 7 |  49 | all three conditions false → else | `CRITICAL (balance < 50)` |
| 8 |   0 | all three conditions false → else | `CRITICAL (balance < 50)` |

### Sample Run — Balance = 150
```
  if   balance >= 200 ?  No
  elif balance >= 100 ?  Yes
  --> NORMAL  (100 <= balance < 200)
```

### Sample Run — Balance = 30
```
  if   balance >= 200 ?  No
  elif balance >= 100 ?  No
  elif balance >=  50 ?  No
  else
  --> CRITICAL (balance < 50)
```

---

## Demo 2 — WHILE Test Cases

| # | Input (N) | Iterations | Notes |
|---|-----------|------------|-------|
| 1 | 0 | **0** | Condition false immediately; body never runs |
| 2 | 1 | 1 | Single iteration then exits |
| 3 | 5 | 5 | Typical case |
| 4 | 10 | 10 | Maximum allowed input |

**Test case 1 is the most important**: it proves that a WHILE loop
can execute zero times, distinguishing it from DO-WHILE.

### Sample Run — N = 3
```
  [WHILE N > 0]
    N = 3 -- continue
    N = 2 -- continue
    N = 1 -- continue
  [N = 0 : condition false -- loop exits]
```

### Sample Run — N = 0 (body never executes)
```
  [WHILE N > 0]
  [N = 0 : condition false -- loop exits]
```

---

## Demo 3 — DO-WHILE Test Cases

| # | Input sequence | Repetitions | Notes |
|---|---------------|-------------|-------|
| 1 | `3` | 1 | Valid on first try; loop exits immediately |
| 2 | `0`, `3` | 2 | One invalid entry, then valid |
| 3 | `6`, `0`, `3` | 3 | Two invalids before valid |
| 4 | `1` | 1 | Lower boundary — accepted |
| 5 | `5` | 1 | Upper boundary — accepted |
| 6 | `0` then `6` then `3` | 3 | Both boundary violations, then valid |

**Key property demonstrated**: regardless of test case, the prompt
appears at least once before any validation occurs.

### Sample Run — Inputs: 0, 7, 3
```
  [body runs BEFORE condition -- guaranteed at least once]
  [do] Enter value (1-5): 0
  [while: out of range -- repeat body]
  [do] Enter value (1-5): 7
  [while: out of range -- repeat body]
  [do] Enter value (1-5): 3
  [while: in range -- exit loop]
  Accepted: 3
```

---

## Demo 4 — FOR Test Cases

| # | Input (N) | Expected rows | Max cost |
|---|-----------|--------------|----------|
| 1 | 0 | 0 rows (skip) | — |
| 2 | 1 | 1 row: i=1, cost=7 | 7 |
| 3 | 5 | 5 rows | 35 |
| 4 | 9 | 9 rows (maximum) | 63 |

### Sample Run — N = 4
```
  Rate: 7 credits per unit
  [FOR i = 1; i <= N; i++]
    [i=1]  7 credits
    [i=2]  14 credits
    [i=3]  21 credits
    [i=4]  28 credits
  [i > N -- loop done]
```

### Sample Run — N = 0 (loop body skipped entirely)
```
  (returns to menu with no table output)
```

---

## Demo 5 — SWITCH Test Cases

| # | Input (code) | Expected case | Output |
|---|-------------|---------------|--------|
| 1 | 0 | Case 0 | `OK:    meter operating normally.` |
| 2 | 1 | Case 1 | `LOW:   recharge recommended.` |
| 3 | 2 | Case 2 | `EMPTY: power supply suspended.` |
| 4 | 3 | Case 3 | `FAULT: engineer call required.` |
| 5 | 4 | Case 4 | `TEST:  diagnostic mode active.` |
| 6 | 5 | Default | `UNKNOWN: unrecognised status code.` |
| 7 | 99 | Default | `UNKNOWN: unrecognised status code.` |
| 8 | 0  | Case 0 | Verify jump table uses table[0] = sw_case0 |

### Sample Run — Code = 2
```
  [switch: O(1) jump-table dispatch]
  Case 2 -- EMPTY: power supply suspended.
```

### Sample Run — Code = 5 (default)
```
  [switch: O(1) jump-table dispatch]
  Default  -- UNKNOWN: unrecognised status code.
```

---

## Main Menu Validation

| Input | Expected behaviour |
|-------|--------------------|
| `0` | Program prints "Goodbye!" and exits (status 0) |
| `1-5` | Corresponding demo runs then returns to menu |
| `6` | "Invalid choice. Enter 0-5." |
| `99` | "Invalid choice. Enter 0-5." |
| *(empty Enter)* | Treated as 0 → exits (read_uint returns 0 for no digits) |

---

## Branch Coverage Summary

| Construct | Branches tested |
|-----------|----------------|
| IF-ELSE | All 4 branches: HIGH, NORMAL, LOW, CRITICAL; all boundary values |
| WHILE | Zero-iteration (N=0), one-iteration (N=1), multi-iteration (N≥2) |
| DO-WHILE | First-try valid, one repeat, multi-repeat; lower and upper boundaries |
| FOR | N=0 (skip), N=1 (single pass), N=9 (maximum) |
| SWITCH | All 5 cases + default; out-of-range values routed to default |
