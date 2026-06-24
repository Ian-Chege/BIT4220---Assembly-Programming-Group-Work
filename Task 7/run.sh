#!/usr/bin/env bash
# Task 7: Build and run three test scenarios
set -e
cd "$(dirname "$0")"

IMAGE=asm-lab
docker build -t "$IMAGE" .. -q

docker run --rm -i "$IMAGE" bash -c '
  set -e
  mkdir -p /work && cd /work

  cat > parser.asm << '"'"'ASMEOF'"'"'
'"$(cat parser.asm)"'
ASMEOF

  cat > readings.txt << '"'"'EOF'"'"'
'"$(cat readings.txt)"'
EOF

  echo "=== Assembling and linking ==="
  nasm -f elf64 parser.asm -o parser.o
  ld parser.o -o parser

  echo ""
  echo "### TEST 1: normal file ###"
  ./parser readings.txt

  echo "### TEST 2: empty file ###"
  > empty.txt
  ./parser empty.txt

  echo "### TEST 3: missing file ###"
  ./parser missing.txt
  echo "(exit code $?)"
' 2>&1; true