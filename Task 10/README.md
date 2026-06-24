# Task 10: Assembly Portfolio — IoT Sensor Log Analyser
## BIT 4220 Assembly Programming — Group Work

---

## Theme: IoT / Embedded Data Processing

A single NASM program that reads a sensor log file, filters entries by
keyword (`TEMP:`), and computes a statistical summary.  No C library,
no dynamic linker — direct Linux system calls only.

---

## Integrated Modules

| Module | Origin | Role |
|--------|--------|------|
| File I/O | Task 7 | sys_open / sys_read / sys_close |
| Keyword search | Task 6 | Filter log lines containing "TEMP:" |
| Statistics engine | Task 8 | count / sum / min / max / average |

---

## Files

| File | Purpose |
|------|---------|
| `portfolio.asm` | Integrated 4.5 KB NASM program |
| `sensors.log` | Sample IoT log: 8 TEMP readings mixed with HUM/PRESS |
| `run.sh` | Build + 4 test scenarios + objdump + readelf |
| `REPORT.md` | 8-page technical report (deliverable) |
| `SLIDES.md` | 12-slide presentation (deliverable) |
| This README | Quick start + test evidence |

---

## Quick Start

```bash
chmod +x run.sh
./run.sh
```

---

## Test Evidence

```
=== TEST 1: Normal log file ===
=== IoT Sensor Log Analyser ===
File:    sensors.log
Records: 8
Sum:     287
Min:     7
Max:     91
Average: 35

=== TEST 2: Empty file ===
Records: 0
  (no TEMP readings found)

=== TEST 3: No TEMP readings ===
Records: 0
  (no TEMP readings found)

=== TEST 4: Missing file ===
Error: cannot open file.
(exited with code 2)
```

---

## Deliverables Checklist

- [x] **Integrated source code:** `portfolio.asm`
- [x] **Build commands:** `run.sh` and this README
- [x] **Final technical report (6–8 pages):** `REPORT.md`
- [x] **Presentation slides:** `SLIDES.md`
