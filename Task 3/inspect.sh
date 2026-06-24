#!/usr/bin/env bash
# inspect.sh — compile alu.asm with debug info and launch GDB inside Docker.
#
# Useful GDB commands for flag inspection (paste after (gdb) prompt):
#
#   break show_result          # break just before flags are printed
#   run                        # start the program; interact in another pane
#   info registers rflags      # show raw RFLAGS hex after an operation
#   print/t $rflags            # same value in binary
#   info registers rax rbx     # operands / result
#
# Decoding RFLAGS manually:
#   bit  0 → CF   bit  2 → PF   bit  6 → ZF
#   bit  7 → SF   bit 11 → OF
#
# Example GDB session for ADD 100 + 200:
#   (gdb) break .op_add+6      # after 'add al, bl'
#   (gdb) run                  # type 1 <enter> 100 <enter> 200 <enter>
#   (gdb) info registers rflags
#   rflags         0x202           [ CF PF ]    ← CF=1 confirms unsigned carry
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/.." && pwd)"
IMAGE="asm-lab"

if ! colima status >/dev/null 2>&1; then
  echo "Starting Colima VM..."
  colima start
fi

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Building $IMAGE image (one-time)..."
  docker build --platform linux/amd64 -t "$IMAGE" "$ROOT"
fi

echo "Compiling alu.asm with DWARF debug info (-g)..."
docker run --rm -it --platform linux/amd64 -v "$DIR:/work" -w /work "$IMAGE" \
  bash -c "
    nasm -g -f elf64 alu.asm -o alu_dbg.o && \
    ld -g alu_dbg.o -o alu_dbg && \
    echo 'Binary ready. Launching GDB...' && \
    gdb ./alu_dbg
  "
