#!/usr/bin/env bash
# run.sh — assemble, link, and run alu.asm in an x86-64 Linux Docker container.
#
# Task 3 is interactive (reads keyboard input), so we pass -it to docker run
# so that stdin flows through from your terminal into the container.
#
# Usage:
#   ./run.sh          # builds and runs alu.asm
#   ./run.sh foo.asm  # builds and runs any other NASM file in this directory
set -euo pipefail

SRC="${1:-alu.asm}"
BIN="${SRC%.asm}"
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

echo "Assembling and linking $SRC ..."
docker run --rm --platform linux/amd64 -v "$DIR:/work" -w /work "$IMAGE" \
  bash -c "nasm -f elf64 '$SRC' -o '$BIN.o' && ld '$BIN.o' -o '$BIN'"

echo "Running $BIN (interactive — use Ctrl-C or choose 0 to exit):"
echo "---"
docker run --rm -it --platform linux/amd64 -v "$DIR:/work" -w /work "$IMAGE" \
  ./"$BIN"
