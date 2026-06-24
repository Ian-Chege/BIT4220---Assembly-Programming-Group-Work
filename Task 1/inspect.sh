#!/usr/bin/env bash
# inspect.sh — Task 1.3: look inside a compiled program's memory.
#
# Uses two standard reverse-engineering tools:
#   objdump  -> STATIC view: the bytes as stored in the file (no running)
#   gdb      -> LIVE view:   the bytes as they sit in memory while running
#
# Both prove the same point: x86 stores multi-byte numbers little-endian
# (backwards), so 0x44434241 is stored in memory as the bytes 41 42 43 44.
#
# Usage:
#   ./inspect.sh            # inspects sizes.asm
#   ./inspect.sh foo.asm    # inspects foo.asm instead
set -euo pipefail

SRC="${1:-sizes.asm}"
BIN="${SRC%.asm}"
DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"
IMAGE="asm-lab"

# Make sure the VM + toolchain image exist (rebuild if Dockerfile changed).
if ! colima status >/dev/null 2>&1; then
  echo "Starting Colima VM..."; colima start
fi
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Building $IMAGE image (one-time)..."
  docker build --platform linux/amd64 -t "$IMAGE" "$ROOT"
fi

docker run --rm --platform linux/amd64 -v "$DIR:/work" -w /work "$IMAGE" bash -c "
  set -e
  nasm -f elf64 '$SRC' -o '$BIN.o'
  ld '$BIN.o' -o '$BIN'

  echo '############################################################'
  echo '# 1. objdump  -  raw bytes stored in the .data section'
  echo '#    (look for: 41 . 41 42 . 41 42 43 44  = A AB ABCD)'
  echo '############################################################'
  objdump -s -j .data '$BIN'

  echo
  echo '############################################################'
  echo '# 2. objdump  -  disassembly of our code (.text / _start)'
  echo '#    shows the mov + syscall instructions we wrote'
  echo '############################################################'
  objdump -d -M intel '$BIN'

  echo
  echo '############################################################'
  echo '# 3. gdb  -  dump the bytes at each named variable'
  echo '#    x/1xb = examine 1 hex byte, x/4xb = examine 4 hex bytes'
  echo '#    (NOTE: we examine memory statically. Stepping/registers'
  echo '#     need live tracing, which QEMU user-mode emulation does'
  echo '#     not support — see README. The byte layout is the point.)'
  echo '############################################################'
  gdb -q -batch \
      -ex 'echo \n--- myByte  (1 byte)  ---\n'  -ex 'x/1xb &myByte' \
      -ex 'echo --- myWord  (2 bytes) ---\n'    -ex 'x/2xb &myWord' \
      -ex 'echo --- myDword (4 bytes) ---\n'    -ex 'x/4xb &myDword' \
      '$BIN'
"
