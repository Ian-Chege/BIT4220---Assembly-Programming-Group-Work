# BIT 4220 Assembly Programming — Group Work

x86-64 NASM, Linux, Docker.

---

## Tasks

| # | Title | Key concepts |
|---|-------|-------------|
| 1 | x86-64 NASM Toolkit | Arithmetic, syscalls, hello world |
| 2 | Student Marks Processor | Loops, conditionals, formatted output |
| 3 | Mini ALU — Embedded Billing Device | Arithmetic operations, overflow handling |
| 4 | Control Structures Translator | if/else, loops, switch in assembly |
| 5 | Secure Procedure Library | Separate compilation, calling convention, stack frames |
| 6 | String & Array Toolkit for Log Cleaning | to_upper, str_rev, kw_search, char counting |
| 7 | File-Based Sensor Data Parser | sys_open/read/close, argv, decimal parsing |
| 8 | Debugging & Reverse Engineering | 5 planted bugs, GDB, objdump, readelf |
| 9 | Inline Assembly & Performance Tuning | GCC inline asm, -O0 vs -O2 benchmark |
| 10 | Portfolio — IoT Sensor Log Analyser | Integrates Tasks 6, 7, 8 into one program |

---

## Running any task

Each task has its own `run.sh` that builds inside Docker and prints all output:

```bash
cd "Task N"
chmod +x run.sh
./run.sh
```

The shared Docker image (`asm-lab`) is built automatically on first run.

---

## Requirements

- Docker (with linux/amd64 support — Colima works on Apple Silicon)
- The `Dockerfile` at the repo root is shared across all tasks
