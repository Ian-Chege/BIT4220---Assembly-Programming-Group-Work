# Task 4 — Pseudocode and Assembly Translation
## BIT 4220 Assembly Programming

Each section shows the high-level pseudocode followed by the
direct assembly translation with annotations explaining how each
construct maps onto CMP and JMP instructions.

---

## Demo 1 — IF-ELSE (Balance Classifier)

### Pseudocode
```
read balance

if balance >= 200:
    print "HIGH"
elif balance >= 100:
    print "NORMAL"
elif balance >= 50:
    print "LOW"
else:
    print "CRITICAL"
```

### Assembly Translation
```nasm
    call read_uint          ; balance → rax

    ; --- if balance >= 200 ---
    cmp rax, 200
    jge .high               ; true  → jump to HIGH block

    ; --- elif balance >= 100 ---
    cmp rax, 100
    jge .norm               ; true  → jump to NORMAL block

    ; --- elif balance >= 50 ---
    cmp rax, 50
    jge .low                ; true  → jump to LOW block

    ; --- else ---            ; all conditions failed: fall through
    print "CRITICAL"
    jmp .done

.high:   print "HIGH"    ;  jmp .done
.norm:   print "NORMAL"  ;  jmp .done
.low:    print "LOW"
.done:
```

**Translation rules**
| Pseudocode | Assembly |
|------------|----------|
| `if condition:` | `CMP x, y` followed by opposite conditional jump past the block |
| `elif condition:` | another `CMP` / conditional jump (reached only if prior conditions failed) |
| `else:` | code reached by falling through all prior jumps |
| End of each block | `JMP .done` to skip remaining branches |

---

## Demo 2 — WHILE (Countdown Loop)

### Pseudocode
```
N = read_input()
while N > 0:
    print N
    N = N - 1
```

### Assembly Translation
```nasm
    call read_uint
    mov rcx, rax            ; N → counter register

.top:                       ; ← condition checked HERE (top of loop)
    cmp rcx, 0
    jle .done               ; condition FALSE → skip body, exit

    ; body
    print rcx               ; print current N
    dec rcx                 ; N -= 1
    jmp .top                ; unconditional jump back to condition

.done:
```

**Translation rules**
| Pseudocode | Assembly |
|------------|----------|
| `while condition:` | label at top + CMP + conditional jump PAST body |
| Loop body | instructions between .top label and the JMP back |
| End of body | `JMP .top` (unconditional, returns to condition check) |
| Loop exit | `.done` label — reached only when condition is false |

**Key property:** If N = 0 on entry, the body executes ZERO times.

---

## Demo 3 — DO-WHILE (Input Validation)

### Pseudocode
```
do:
    n = read_input()
while n < 1 or n > 5

print "Accepted:", n
```

### Assembly Translation
```nasm
.body:                      ; ← no condition here; body runs immediately

    ; body
    print "Enter value (1-5): "
    call read_uint          ; n → rax

    ; condition checked HERE (bottom of loop)
    cmp rax, 1
    jb  .body               ; n < 1: condition TRUE → repeat body
    cmp rax, 5
    ja  .body               ; n > 5: condition TRUE → repeat body

    ; condition FALSE → fall through (exit loop)
print "Accepted:", rax
```

**Translation rules**
| Pseudocode | Assembly |
|------------|----------|
| `do:` | place a label at the top of the body (no CMP) |
| Loop body | instructions that always execute |
| `while condition:` | CMP at the BOTTOM; jump BACK to body if true |
| Loop exit | fall-through after the last CMP (condition false) |

**Key property:** Body always executes at least ONCE regardless of input.

---

## Demo 4 — FOR (Tariff Rate Table)

### Pseudocode
```
N = read_input()
rate = 7
for i = 1 to N:
    print i, "units ->", i * rate, "credits"
```

### Assembly Translation
```nasm
    call read_uint
    mov rbx, rax            ; N → rbx (upper bound)

    mov rcx, 1              ; i = 1  ← INITIALISER

.top:
    cmp rcx, rbx            ; i <= N ? ← CONDITION
    jg  .done               ; false → exit loop

    ; body
    imul rax, rcx, 7        ; cost = i * rate
    print i, cost

    inc rcx                 ; i++ ← INCREMENT
    jmp .top                ; back to condition

.done:
```

**Translation rules**
| `for` clause | Assembly |
|--------------|----------|
| `i = 1` (initialiser) | `MOV rcx, 1` before the loop |
| `i <= N` (condition) | `CMP rcx, rbx` at the top of the loop |
| `i++` (increment) | `INC rcx` at the bottom of the body |

A FOR loop is syntactic sugar over a WHILE loop — the compiler
always produces the same CMP-at-top structure.

---

## Demo 5 — SWITCH-CASE (Device Status)

### Pseudocode
```
code = read_input()
switch code:
    case 0:  print "OK"
    case 1:  print "LOW"
    case 2:  print "EMPTY"
    case 3:  print "FAULT"
    case 4:  print "TEST"
    default: print "UNKNOWN"
```

### Assembly Translation — Compare Chain (O(n), naïve)
```nasm
    cmp rax, 0
    je  .case0
    cmp rax, 1
    je  .case1
    cmp rax, 2
    je  .case2
    ...
    jmp .default
```

### Assembly Translation — Jump Table (O(1), compiler-optimised)
```nasm
; In .data:
jmptbl  dq  case0, case1, case2, case3, case4   ; 5 × 8-byte addresses

; In .text:
    cmp rax, 4              ; guard: is code in range 0-4?
    ja  sw_default          ; out of range → default

    lea rbx, [jmptbl]       ; rbx = base address of table
    jmp [rbx + rax*8]       ; one instruction dispatches to correct case
```

**Translation rules**
| Pseudocode | Assembly |
|------------|----------|
| Range guard | `CMP` + `JA sw_default` |
| `case N:` | a label in .text; address stored in jump table |
| `break` | `JMP sw_done` after each case body |
| `default:` | label reached when `cmp rax, max` fails |

**Complexity comparison**

| Method | Time | Best for |
|--------|------|----------|
| Compare chain | O(n) — worst case tests every condition | sparse or string cases |
| Jump table | O(1) — one bounds check + one indirect jump | dense integer ranges |

---

## Instruction-Pointer Summary

The **instruction pointer (RIP)** always contains the address of the NEXT
instruction to execute.  Control structures change RIP using:

| Instruction | Effect on RIP |
|-------------|---------------|
| `JMP label` | RIP ← absolute address of label (unconditional) |
| `JGE label` | RIP ← label if ZF=0 and SF=OF; otherwise RIP ← next instruction |
| `JMP [mem]` | RIP ← value read from memory (indirect jump — used by jump table) |
| `CALL proc` | push RIP+size; RIP ← proc address |
| `RET` | RIP ← value popped from stack |
