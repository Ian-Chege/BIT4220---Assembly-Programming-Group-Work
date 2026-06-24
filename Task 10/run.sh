#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

IMAGE=asm-lab
docker build --platform linux/amd64 -t "$IMAGE" .. -q

docker run --rm -i "$IMAGE" bash -c '
  set -e
  mkdir -p /work && cd /work

  cat > portfolio.asm << '"'"'EOF'"'"'
'"$(cat portfolio.asm)"'
EOF

  cat > sensors.log << '"'"'EOF'"'"'
'"$(cat sensors.log)"'
EOF

  echo "=== Build ==="
  nasm -f elf64 -g -F dwarf portfolio.asm -o portfolio.o
  ld portfolio.o -o portfolio
  echo "Built: portfolio"

  echo ""
  echo "=== TEST 1: Normal log file ==="
  ./portfolio sensors.log

  echo ""
  echo "=== TEST 2: Empty file ==="
  > empty.log
  ./portfolio empty.log

  echo ""
  echo "=== TEST 3: File with no TEMP readings ==="
  printf "HUM:65 PRESS:1013\nHUM:70 PRESS:1015\n" > notemp.log
  ./portfolio notemp.log

  echo ""
  echo "=== TEST 4: Missing file ==="
  ./portfolio missing.log || echo "(exited with code $?)"

  echo ""
  echo "=== Memory layout (readelf -S) ==="
  readelf -S portfolio | grep -E "Name|\.text|\.data|\.bss"

  echo ""
  echo "=== Disassembly: scan loop ==="
  objdump -d -M intel portfolio | grep -A 55 "_start.scan" || true
' 2>&1
