# Technical Notes — `marks.asm`

Covers Task 2 practical task 3 (addressing modes & where each is used) and
deliverable (c) (assembly vs C/Python indexing).

---

## Part 1 — Addressing modes used

"Addressing mode" = *how an instruction names the data it works on.* `marks.asm`
uses all six. Each line below is a real instruction from the program.

### 1. Immediate — the value is in the instruction
```asm
mov r11, nmarks      ; r11 = 10  (10 is a literal baked into the code)
cmp rax, 40          ; compare against the literal 40
```
Used for: loop count, classification thresholds, syscall numbers, the `'0'`
added when converting a digit to ASCII. Fastest — nothing is fetched from memory.

### 2. Register — the operand is a register
```asm
add r8, rax          ; total += current mark, both in registers
mov r9, rax          ; highest = current mark
```
Used for: the running total, highest/lowest, and loop comparisons. Registers are
the CPU's own storage, so these are the quickest operations available.

### 3. Direct — a fixed, named memory address
```asm
inc qword [cnt_fail] ; address of cnt_fail is fixed at link time (0x40216C)
mov rax, [cnt_pass]  ; read a counter back for printing
```
Used for: the four classification counters. The address never changes, so it is
encoded straight into the instruction.

### 4. Indirect — the address is held in a register
```asm
lea rbx, [marks]     ; rbx now holds the ADDRESS of the array
movzx rax, byte [rbx]; read the byte that rbx points at  (marks[0])
```
Used for: the demonstration line and inside `print_uint` (`mov [rdi], dl` stores
a digit at whatever address `rdi` currently points to). This is exactly how a
pointer works in C.

### 5. Indexed — displacement + index register
```asm
movzx rax, byte [marks + rcx]   ; address = marks + rcx
```
Used for: the main loop. `marks` is the fixed displacement, `rcx` is the moving
index. Incrementing `rcx` walks through the array — this is the heart of array
processing in assembly.

### 6. Based — base register + displacement
```asm
movzx rax, byte [rbx + 5]       ; address = rbx + 5  (marks[5])
```
Used for: the demonstration line. `rbx` is the base (the array start) and `5` is
a constant offset. Useful when the base is computed at run time but the offset is
known in advance (e.g. a fixed field inside a record).

> Note: `[base + index]` such as `[rbx + rcx]` combines modes 5 and 6 and is
> often called *based-indexed*. We kept them separate here so each mode is shown
> on its own.

---

## Part 2 — Assembly indexing vs C and Python (deliverable c)

All three languages reach `marks[i]`, but at very different levels of help.

### The same access, three languages

| | Code | What actually happens |
|-|------|-----------------------|
| **Assembly** | `movzx rax, byte [marks + rcx]` | You give the base, the index, and implicitly the element size (1 byte). The CPU adds them and reads. |
| **C** | `marks[i]` | Compiler computes `*(marks + i * sizeof(element))` for you, then emits essentially the same instruction. |
| **Python** | `marks[i]` | The interpreter does a bounds check, object lookup, and reference handling at run time before returning a boxed integer. |

### Key differences

**1. Element size is manual in assembly.**
Our marks are bytes, so `[marks + rcx]` works because 1 element = 1 address. If
they were doublewords (4 bytes) we would need `[marks + rcx*4]` — the CPU's
*scale* factor. In C, `marks[i]` automatically multiplies by `sizeof(int)`; you
never write the `*4`. Python hides size entirely.

**2. No bounds checking in assembly or C.**
`[marks + rcx]` will happily read past the end of the array if `rcx >= 10` — that
is how buffer over-reads happen. C behaves the same (undefined behaviour). Python
raises `IndexError` instead, trading speed for safety. This is the single biggest
practical difference and the reason low-level code is both fast and dangerous.

**3. Indexing is an addressing mode, not an operator.**
In Python `marks[i]` is a method call (`__getitem__`). In C it is an operator the
compiler translates. In assembly there is no "indexing operator" at all — it is
literally a way of forming an address, executed by the CPU in a single step with
no function call.

**4. Zero-based, and why.**
All three are zero-based, but assembly shows *why*: `marks[0]` is at
`marks + 0`, i.e. the array's own address. The index is the **distance from the
start**, so the first element is distance 0. C inherited this directly; Python
kept the convention.

### One-line summary
Python *protects* you (bounds checks, no pointers), C *translates* for you
(automatic element-size scaling), and assembly *exposes everything* — you compute
the address yourself, which is why understanding `[base + index*scale + disp]` is
the foundation for reading compiled code, exploits, and memory dumps.
