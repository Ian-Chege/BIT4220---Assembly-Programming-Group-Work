#!/usr/bin/env bash
# run.sh — assemble, link, and run an x86-64 Linux NASM program on macOS.
#
# Why a container? hello.asm uses Linux syscalls (write=1, exit=60) and the
# ELF _start convention. macOS (Mach-O, different syscalls) can't run it
# natively — and on Apple Silicon the CPU is arm64, not x86-64. Docker + Colima
# gives us a Linux VM, and --platform linux/amd64 emulates x86-64 via QEMU.
#
# nasm + binutils are baked into the "asm-lab" image (see ../Dockerfile), so
# they are installed ONCE at image-build time, not on every run.
#
# Usage:
#   ./run.sh            # builds and runs hello.asm
#   ./run.sh foo.asm    # builds and runs foo.asm instead
set -euo pipefail

SRC="${1:-hello.asm}"        # source file (default: hello.asm)
BIN="${SRC%.asm}"            # output binary name (strip .asm)
DIR="$(cd "$(dirname "$0")" && pwd)"   # this task folder
ROOT="$(cd "$DIR/.." && pwd)"          # asm-lab root (holds the Dockerfile)
IMAGE="asm-lab"

# 1. Make sure the Linux VM is running.
if ! colima status >/dev/null 2>&1; then
  echo "Starting Colima VM..."
  colima start
fi

# 2. Build the toolchain image once. Skipped on later runs (image is cached).
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Building $IMAGE image (one-time)..."
  docker build --platform linux/amd64 -t "$IMAGE" "$ROOT"
fi

# 3. Assemble + link + run. This folder is mounted at /work.
docker run --rm --platform linux/amd64 -v "$DIR:/work" -w /work "$IMAGE" \
  bash -c "
    nasm -f elf64 '$SRC' -o '$BIN.o' && \
    ld '$BIN.o' -o '$BIN' && \
    echo '--- output ---' && \
    ./'$BIN'
  "