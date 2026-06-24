# Tutorial: Compiling, Linking & Running NASM Programs

*Task 1.4 — a short guide for first-year students.*

This walks you through running the assembly programs in this folder, even if
you've never touched assembly before. Follow it top to bottom.

---

## 1. What are we actually doing?

A `.asm` file is **human-readable text**. The CPU can't run text — it runs
binary machine code. Getting from one to the other is a two-step pipeline:

```
 hello.asm  ──nasm──▶  hello.o  ──ld──▶  hello  ──▶  run it
 (source)            (object)         (program)
```

1. **Assemble** (`nasm`) — translate your text instructions into machine-code
   bytes, producing an *object file* (`.o`).
2. **Link** (`ld`) — turn the object file into a finished, runnable *executable*
   (sets the entry point, lays out memory).
3. **Run** — the operating system loads it and the CPU executes it.

That's the whole idea. Everything below is just *how* to do those three steps.

---

## 2. Why we use a container (read this once)

These programs are written for **x86-64 Linux**, but our Macs are
**Apple Silicon (arm64)** running macOS. Two things don't match:

- **Operating system** — macOS isn't Linux; the "syscall" numbers differ.
- **CPU** — our chip is arm64, the code is x86-64.

So we run everything inside a small **Linux x86-64 container** (via Docker +
Colima). You don't need to understand the internals — the helper scripts handle
it. Just know that's why we type `./run.sh` instead of running the file directly.

> **First time on a new Mac?** Do the one-time setup in
> [README.md](README.md#one-time-setup) before continuing.

---

## 3. Running a program (the easy way)

From inside the `Task 1` folder:

```bash
./run.sh hello.asm      # the hello-world program
./run.sh sizes.asm      # the bytes/words/doublewords program
```

Expected output for `hello.asm`:

```
Hello, World! Welcome to x86-64 Assembly.
This program runs directly on the CPU — no Python, no Java.
```

`run.sh` does the assemble → link → run pipeline for you in one go.

---

## 4. Running it manually (to see each step)

If you want to *see* the pipeline instead of letting the script hide it, open a
shell inside the container and run the commands yourself:

```bash
# open a Linux shell with the tools, this folder mounted at /work
docker run -it --platform linux/amd64 -v "$PWD:/work" -w /work asm-lab bash
```

Then, inside that shell:

```bash
nasm -f elf64 hello.asm -o hello.o   # 1. assemble  -> hello.o
ld hello.o -o hello                  # 2. link      -> hello
./hello                              # 3. run
```

Type `exit` to leave the container. This is exactly what `run.sh` automates.

**What the flags mean:**

| Command | Flag | Meaning |
|---------|------|---------|
| `nasm`  | `-f elf64` | output format = 64-bit Linux ELF object |
| `nasm`  | `-o hello.o` | name the output object file |
| `ld`    | `-o hello` | name the final executable |

---

## 5. Looking inside a program (Task 1.3)

To see the raw bytes and the disassembled instructions:

```bash
./inspect.sh sizes.asm
```

This prints the contents of memory and the machine instructions. See
[README.md](README.md#inspecting-memory-task-13) for how to read the output and
what it proves about little-endian storage.

---

## 6. Common errors and fixes

| You see… | Cause | Fix |
|----------|-------|-----|
| `cannot connect to the Docker daemon` | The Linux VM isn't running | `colima start` |
| `command not found: colima` | Tools not installed | `brew install colima docker` |
| `hello.asm: No such file` | Wrong folder or filename | `cd` into `Task 1`; check spelling |
| Output looks like nothing printed | Forgot the newline byte `0x0A` | add `0x0A` at the end of your string |
| Program prints then hangs/crashes | Missing the exit syscall | end with `mov rax, 60` / `mov rdi, 0` / `syscall` |

---

## 7. The 60-second mental model

- Assembly = tiny steps: *put a value in a register*, then *ask the OS to act*.
- A **register** is a named slot inside the CPU (`rax`, `rdi`, `rsi`, `rdx`).
- To **print**: `rax=1` (write), `rdi=1` (screen), `rsi=address`, `rdx=length`,
  then `syscall`.
- To **quit**: `rax=60` (exit), `rdi=0` (success), then `syscall`.
- `nasm` turns your text into bytes; `ld` turns those into a program; the OS runs it.

That's everything you need to read and run the programs in this folder.
