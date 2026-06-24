# Task 1 — x86-64 NASM Toolkit (Linux)

A small set of NASM programs that demonstrate how the CPU stores numbers and
characters (binary, hex, ASCII, little-endian, two's complement).

## Contents

| File | Purpose |
|------|---------|
| `hello.asm` | Task 1.1 — hello-world program (print + exit via syscalls). |
| `sizes.asm` | Task 1.2 — bytes/words/doublewords, their ASCII + little-endian layout. |
| `run.sh` | Build & run any `.asm` file. |
| `inspect.sh` | Task 1.3 — inspect a program's memory with `objdump` + `gdb`. |
| `TUTORIAL.md` | Task 1.4 — student guide to compiling, linking and running. |
| `TECHNICAL_NOTE.md` | Deliverable (c) — 2-page note on data representation. |
| `../Dockerfile` | Defines the Linux x86-64 build image (`nasm`, `binutils`, `gdb`). |

Both `.asm` files target **x86-64 Linux** (syscalls `write`=1 / `exit`=60, ELF
`_start` entry point). Because this is an Apple Silicon Mac, they run inside a
Linux x86-64 container — see setup below, and the "why" in `TUTORIAL.md`.

## One-time setup

```bash
brew install colima docker
colima start
```

After a reboot, just `colima start` again (check with `colima status`).
The build image is built automatically on first run, then cached.

## Commands

```bash
./run.sh hello.asm       # assemble + link + run
./run.sh sizes.asm
./inspect.sh sizes.asm   # show raw bytes + disassembly (Task 1.3)
```

`run.sh`/`inspect.sh` take any `.asm` filename; `run.sh` defaults to `hello.asm`,
`inspect.sh` to `sizes.asm`.

## Inspecting memory (Task 1.3)

`./inspect.sh sizes.asm` prints three things:

1. **`objdump -s -j .data`** — raw bytes in the data section.
2. **`objdump -d -M intel`** — disassembled instructions.
3. **`gdb x/...`** — bytes at each variable (`myByte`, `myWord`, `myDword`).

**The key result — little-endian:** we write `myDword dd 0x44434241`, but memory
stores it as `41 42 43 44` (lowest byte first), which reads as `ABCD`. Full
explanation in `TECHNICAL_NOTE.md`.

> **Live debugging note:** `gdb` reads memory statically here. Stepping/registers
> mid-run need `ptrace`, which QEMU user-mode emulation doesn't support, so
> `run`/`break`/`step` error in this setup. The static view is enough to show
> memory layout; full live debugging needs a real x86-64 Linux host.

### Screenshots (deliverable b)

Run a command and screenshot the terminal (macOS: **Cmd-Shift-4**). Save images
in a `screenshots/` folder beside this README and link them here.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `cannot connect to the Docker daemon` | `colima start` |
| `command not found: colima` | `brew install colima docker` |
| Changed `../Dockerfile` and need a rebuild | `docker rmi asm-lab` (next run rebuilds) |

## Deliverables checklist

- [x] (a) Source files + build script — `*.asm`, `run.sh`, `inspect.sh`, `../Dockerfile`
- [ ] (b) README with setup, commands, **screenshots** — *add screenshots*
- [x] (c) Two-page technical note — `TECHNICAL_NOTE.md`
- [x] Task 1.4 tutorial — `TUTORIAL.md`
