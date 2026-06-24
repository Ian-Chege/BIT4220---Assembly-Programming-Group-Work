# BIT 4220 — Task 10 Presentation Slides
# IoT Sensor Log Analyser — Assembly Portfolio

---

## Slide 1 — Title

**IoT Sensor Log Analyser**
Assembly Programming Portfolio — BIT 4220 Group Work

> "Demonstrating that hand-written assembly still solves real problems
>  in resource-constrained embedded systems."

---

## Slide 2 — Why Assembly in IoT?

**The Problem**
- IoT edge nodes: 256 KB flash, no C runtime, minimal Linux
- Need to parse sensor logs with zero library dependencies
- Every kilobyte and every syscall has a cost

**Our Approach**
- Single NASM binary: 4.5 KB, 7 syscalls per run, zero heap allocation
- Equivalent C + glibc static binary: ~700 KB, 40–80 syscalls

---

## Slide 3 — Theme and Integration

**Theme: IoT / Embedded Data Processing**

Three prior modules combined into one program:

```
Task 7  ──►  File I/O           sys_open / sys_read / sys_close
Task 6  ──►  Keyword search     filter lines containing "TEMP:"
Task 8  ──►  Statistics         count / sum / min / max / average
```

---

## Slide 4 — Program Architecture

```
argv[1]
  │
  ▼
sys_open ──► error? → exit 2
  │
sys_read → filebuf (4096 B)
  │
sys_close
  │
  ▼
Scan loop (O(n) single pass)
  ├─ "TEMP:" found? → parse number → update stats
  └─ otherwise     → advance one byte
  │
  ▼
Print: Records / Sum / Min / Max / Average
```

---

## Slide 5 — The Scan Loop (Core Innovation)

Inlined keyword check — 5 comparisons, short-circuit on first mismatch:

```nasm
cmp  byte [rdi],   'T' ;  }
cmp  byte [rdi+1], 'E' ;  } if any fails →
cmp  byte [rdi+2], 'M' ;  }   advance_one
cmp  byte [rdi+3], 'P' ;  }
cmp  byte [rdi+4], ':' ;  }
; match → parse digits → update stats → skip to next newline
```

No heap, no malloc, no string copies — operates directly on the read buffer.

---

## Slide 6 — Live Demo Output

```
=== IoT Sensor Log Analyser ===
File:    sensors.log
Records: 8
Sum:     287
Min:     7
Max:     91
Average: 35
```

Cross-checked against Task 8 fixed.asm (same 8 values in a dq array) ✓

**Edge cases handled:**
- Empty file → "no TEMP readings found", no divide fault
- No matching keyword → same graceful exit
- Missing file → stderr error, exit code 2

---

## Slide 7 — Register Map (ABI Compliance)

| Register | Role |
|----------|------|
| `r15` | filename pointer (argv[1]) — callee-saved |
| `r13` | bytes read — callee-saved |
| `r14` | scan index — callee-saved |
| `rbx` | record count — callee-saved |
| `r8`  | running sum |
| `r9`  | running min (init INT64_MAX) |
| `r10` | running max |
| `rax/rcx/rdx/rdi/rsi` | scratch / syscall args |

Callee-saved registers used for long-lived state — System V AMD64 ABI compliant.

---

## Slide 8 — Memory Footprint

| Region | Size |
|--------|------|
| `.text` (code) | ~960 B |
| `.data` (strings) | 140 B |
| `.bss` (filebuf + numbuf) | 4120 B |
| Stack (runtime) | ~128 B |
| **Total** | **~5.5 KB** |

Static C equivalent: ~700 KB.  Dynamic C: 8 KB + 2 MB libc loaded at runtime.

---

## Slide 9 — Debugging Evidence

**GDB:** break at `_start.scan`, inspect registers after first record commit
- `rbx=1, r8=23, r9=23, r10=23` — correct first-record seeding

**objdump confirms all Task 8 bug-fixes survived integration:**
```
cmp  BYTE PTR [rdi], 0x54       ; 'T' ✓
cmp  BYTE PTR [rdi+4], 0x3a     ; ':' ✓
jle  (no_max branch)             ; correct direction ✓
div  rbx                         ; divides by count ✓
```

---

## Slide 10 — Trade-offs

| | **Assembly** | **C + glibc** |
|--|-------------|--------------|
| Size | 4.5 KB | ~700 KB |
| Startup | microseconds | milliseconds |
| Portability | x86-64 only | any platform |
| Readability | low | high |
| Debugging | register-level | source-level + sanitisers |
| Maintenance | expensive | cheap |

**Use assembly when:** CRC/hash inner loops, boot stubs, hardware-specific instructions (AES-NI, SIMD), or when the C runtime simply doesn't exist.

---

## Slide 11 — Module Integration Summary

| Integration point | What changed from the original module |
|-------------------|--------------------------------------|
| Task 7 file I/O | Parse loop replaced — keyword filter decides what to count |
| Task 6 kw_search | Inlined as 5 `cmp`/`jne` pairs — no general loop needed |
| Task 8 statistics | Used verbatim — already parameterised on a single `rcx` register value |

Minimal adaptation required — each module was designed with a clean register interface.

---

## Slide 12 — Conclusion

**What we demonstrated:**
- Assembly can integrate cleanly across multiple modules via a shared register convention
- A 4.5 KB binary with 7 syscalls solves a real IoT log-parsing problem
- Debugging tools (GDB, objdump) verify correctness at machine-code level

**When assembly is still relevant today:**
Firmware, device drivers, bootloaders, exploit mitigations (ASLR, stack canaries),
cryptographic primitives, real-time DSP, and anywhere a C runtime cannot exist.

**Thank you**
