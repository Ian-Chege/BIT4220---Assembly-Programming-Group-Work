#!/usr/bin/env bash
# Task 8: Build both binaries, compare output, run GDB + objdump
set -e
cd "$(dirname "$0")"

IMAGE=asm-lab
docker build -t "$IMAGE" .. -q

docker run --rm -i "$IMAGE" bash -c '
  set -e
  mkdir -p /work && cd /work

  # ── Copy sources ──────────────────────────────────────────
  cat > buggy.asm << '"'"'EOF'"'"'
'"$(cat buggy.asm)"'
EOF

  cat > fixed.asm << '"'"'EOF'"'"'
'"$(cat fixed.asm)"'
EOF

  cat > debug.gdb << '"'"'EOF'"'"'
'"$(cat debug.gdb)"'
EOF

  # ── Build ─────────────────────────────────────────────────
  echo "=== Build ==="
  nasm -f elf64 -g -F dwarf buggy.asm -o buggy.o
  ld buggy.o -o buggy
  nasm -f elf64 -g -F dwarf fixed.asm -o fixed.o
  ld fixed.o -o fixed
  echo "Both binaries built."

  # ── Run comparison ────────────────────────────────────────
  echo ""
  echo "### BUGGY OUTPUT ###"
  ./buggy

  echo "### FIXED OUTPUT ###"
  ./fixed

  # ── GDB register inspection ───────────────────────────────
  echo ""
  echo "### GDB SESSION (buggy) ###"
  gdb -batch -x debug.gdb ./buggy 2>/dev/null || true

  # ── objdump: loop body comparison ────────────────────────
  echo ""
  echo "### objdump: buggy loop body (spot Bug 3 and Bug 5) ###"
  objdump -d -M intel buggy | grep -A 30 "<_start>"  | head -45

  echo ""
  echo "### objdump: fixed loop body ###"
  objdump -d -M intel fixed | grep -A 30 "<_start>" | head -45

  # ── readelf: section headers ──────────────────────────────
  echo ""
  echo "### readelf -S buggy (section layout) ###"
  readelf -S buggy | grep -E "Name|\.text|\.data|\.bss"
' 2>&1