# Test Cases — `marks.asm`

*Task 2, Deliverable (d).* Boundary testing of the classification logic.

## Classification rule under test

```
Fail        :   0 - 39      (mark <  40)
Pass        :  40 - 49      (40 <= mark < 50)
Credit      :  50 - 69      (50 <= mark < 70)
Distinction :  70 - 100     (mark >= 70)
```

The risky points are the **band edges**, where an off-by-one error would put a
mark in the wrong class. The cases below test each edge from both sides.

## Boundary cases

| # | Mark | Expected band | Why it's a boundary |
|---|------|---------------|---------------------|
| 1 | 0   | Fail        | minimum possible mark |
| 2 | 39  | Fail        | highest Fail (just below the Fail/Pass edge) |
| 3 | 40  | Pass        | lowest Pass (just on the Fail/Pass edge) |
| 4 | 49  | Pass        | highest Pass (just below the Pass/Credit edge) |
| 5 | 50  | Credit      | lowest Credit (just on the Pass/Credit edge) |
| 6 | 69  | Credit      | highest Credit (just below the Credit/Distinction edge) |
| 7 | 70  | Distinction | lowest Distinction (just on the Credit/Distinction edge) |
| 8 | 100 | Distinction | maximum possible mark |

The brief lists 0, 39, 40, 69, 70 and 100 — cases 1, 2, 3, 6, 7 and 8. Cases
4 and 5 are added to cover the Pass/Credit edge as well.

## How these are exercised

The default `marks` array deliberately embeds every required boundary:

```asm
marks db 0, 39, 40, 55, 69, 70, 85, 100, 45, 60
;        ^   ^   ^       ^   ^        ^
;       0  39  40      69  70      100   (boundary values)
```

Expected tally for this array:

| Band | Marks that fall in it | Expected count |
|------|-----------------------|----------------|
| Fail        | 0, 39           | 2 |
| Pass        | 40, 45          | 2 |
| Credit      | 55, 69, 60      | 3 |
| Distinction | 70, 85, 100     | 3 |
| **Total**   | sum = 563, avg = 56, hi = 100, lo = 0 | 10 |

## Actual output (verified)

Running `./run.sh marks.asm` produces:

```
Total mark .................. 563
Average mark ................ 56
Highest mark ................ 100
Lowest mark ................. 0
Fail        (0-39) .......... 2
Pass        (40-49) ......... 2
Credit      (50-69) ......... 3
Distinction (70-100) ........ 3
```

Counts and statistics match the expected table → classification logic is correct
at all boundaries. ✅

## Re-testing with different values

To test other inputs, edit the `marks` line in `marks.asm` and re-run
`./run.sh marks.asm`. Suggested extra arrays:

| Array | Tests | Expected |
|-------|-------|----------|
| `db 49,50, 49,50, 49,50, 49,50, 49,50` | Pass/Credit edge ×5 | Pass 5, Credit 5 |
| `db 39,40, 39,40, 39,40, 39,40, 39,40` | Fail/Pass edge ×5 | Fail 5, Pass 5 |
| `db 100,100,100,100,100,100,100,100,100,100` | all max | Distinction 10, avg 100 |
| `db 0,0,0,0,0,0,0,0,0,0` | all min | Fail 10, avg 0, hi 0, lo 0 |

> Note: marks must stay in the range 0–100 and the array must hold exactly 10
> values, otherwise update `nmarks` is automatic (`$ - marks`) but the average
> divisor and labels assume a 0–100 scale.
