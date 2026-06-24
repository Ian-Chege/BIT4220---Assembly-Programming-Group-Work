#!/usr/bin/env bash
# inspect.sh — Task 2: look inside the compiled marks processor.
#
#   objdump  -> static view of the stored bytes + disassembly
#   gdb      -> dump the marks array straight from memory
#
# Usage:
#   ./inspect.sh            # inspects marks.asm
#   ./inspect.sh foo.asm    # inspects foo.asm instead
set -euo pipefail

SRC="${1:-marks.asm}"
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
  echo '# 1. objdump -t  -  symbol table (addresses & offsets)'
  echo '#    this is the raw material for the memory map'
  echo '############################################################'
  objdump -t '$BIN' | grep -E '\\.data|\\.bss|\\.text' | grep -vE 'df |\\*ABS\\*'

  echo
  echo '############################################################'
  echo '# 2. objdump -s  -  raw bytes of the marks array (.data)'
  echo '############################################################'
  objdump -s -j .data '$BIN' | head -3

  echo
  echo '############################################################'
  echo '# 3. objdump -d  -  disassembled code (addressing modes)'
  echo '############################################################'
  objdump -d -M intel '$BIN'

  echo
  echo '############################################################'
  echo '# 4. gdb  -  the 10 marks as they sit in memory'
  echo '#    x/10db = 10 decimal bytes, x/10xb = 10 hex bytes'
  echo '############################################################'
  gdb -q -batch \
      -ex 'echo \n--- marks[] as decimal ---\n' -ex 'x/10db &marks' \
      -ex 'echo --- marks[] as hex ---\n'       -ex 'x/10xb &marks' \
      '$BIN'
"
