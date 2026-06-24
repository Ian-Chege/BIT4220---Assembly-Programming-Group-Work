# Task 7 — System Call Trace
## BIT 4220 Assembly Programming

---

## System Calls Used

| Call | Number | Purpose in this program |
|------|--------|------------------------|
| sys_read  | 0 | Read file contents into buffer |
| sys_write | 1 | Print output to stdout |
| sys_open  | 2 | Open the named input file |
| sys_close | 3 | Close the file descriptor |
| sys_exit  | 60 | Terminate with a status code |

---

## Register Protocol (Linux x86-64 syscall ABI)

At the `syscall` instruction, the kernel reads arguments from fixed registers:

```
rax  = syscall number
rdi  = argument 1
rsi  = argument 2
rdx  = argument 3
r10  = argument 4  (not used here)
r8   = argument 5  (not used here)
r9   = argument 6  (not used here)

Return value → rax  (negative value on error: -errno)

Clobbered by syscall: rcx, r11
All other registers preserved by the kernel.
```

---

## Per-Call Trace

### 1. sys_open — open the input file

```nasm
mov  rax, 2          ; syscall number: sys_open
mov  rdi, r15        ; arg1: NUL-terminated path string (argv[1])
xor  rsi, rsi        ; arg2: flags = O_RDONLY (0)
xor  rdx, rdx        ; arg3: mode  (ignored for O_RDONLY)
syscall
; rax = fd on success (≥ 0), or -ENOENT / -EACCES etc. on failure
```

**Error handling**: `test rax, rax; js .open_error` — if rax is negative
(sign flag set), the file could not be opened.  We print an error message
and call `sys_exit(2)`.

### 2. sys_read — read up to 4096 bytes

```nasm
mov  rax, 0          ; sys_read
mov  rdi, r12        ; arg1: file descriptor (from sys_open)
lea  rsi, [filebuf]  ; arg2: destination buffer address
mov  rdx, 4096       ; arg3: maximum bytes to read
syscall
; rax = bytes actually read (0 = empty file, negative = I/O error)
```

The kernel copies bytes from the file into `filebuf` and returns the
count.  For a file smaller than 4096 bytes (as assumed here) a single
`sys_read` obtains the whole file.  We clamp a negative return to zero
so that the parse loop sees an empty buffer and prints "no records".

### 3. sys_close — release the file descriptor

```nasm
mov  rax, 3          ; sys_close
mov  rdi, r12        ; arg1: file descriptor
syscall
; rax = 0 on success (ignored)
```

Good practice: close the fd before parsing so the kernel can reuse it.

### 4. sys_write — write output lines to stdout

```nasm
mov  rax, 1          ; sys_write
mov  rdi, 1          ; arg1: fd 1 = stdout
mov  rsi, <ptr>      ; arg2: pointer to string in memory
mov  rdx, <len>      ; arg3: byte count
syscall
; rax = bytes written (ignored)
```

Called repeatedly via the `print_str` helper for labels, numbers, and
newlines.

### 5. sys_exit — terminate the process

```nasm
mov  rax, 60         ; sys_exit
xor  rdi, rdi        ; arg1: exit code 0 (success)
syscall              ; does not return
```

Exit codes used:
| Code | Meaning |
|------|---------|
| 0 | Normal completion |
| 1 | Usage error (wrong argument count) |
| 2 | File-open error (file not found / no permission) |

---

## Call Sequence for `./parser readings.txt`

```
_start
  │
  ├─ sys_open("readings.txt", O_RDONLY)  → fd=3
  ├─ sys_read(3, filebuf, 4096)          → 36 bytes
  ├─ sys_close(3)
  │
  ├─ [parse loop — no syscalls]
  │
  ├─ sys_write(1, "=== Sensor Data Parser ===\n", 28)
  ├─ sys_write(1, "File:     ", 10)
  ├─ sys_write(1, "readings.txt\n", 13)
  ├─ sys_write(1, "Records:  ", 10)  + "9\n"
  ├─ sys_write(1, "Sum:      ", 10)  + "342\n"
  ├─ sys_write(1, "Min:      ", 10)  + "7\n"
  ├─ sys_write(1, "Max:      ", 10)  + "91\n"
  ├─ sys_write(1, "Average:  ", 10)  + "38\n"
  └─ sys_exit(0)
```

---

## Why No sys_stat or sys_lseek?

The parser assumes the file fits in 4096 bytes, so a single `sys_read`
suffices.  `sys_stat` would let us pre-check the file size, and
`sys_lseek` would let us seek for multi-pass processing — both add
complexity unnecessary for the sensor log use case here.
