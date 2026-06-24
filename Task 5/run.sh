#!/usr/bin/env bash
# Task 5: Build and run the procedure library demo
# Two-file separate compilation to demonstrate global/extern linking.
set -e
cd "$(dirname "$0")"

IMAGE=asm-lab

docker build -t "$IMAGE" .. -q

docker run --rm -i "$IMAGE" bash -c '
  set -e
  mkdir /work && cd /work

  cat > procedures.asm << '"'"'ASMEOF'"'"'
'"$(cat procedures.asm)"'
ASMEOF

  cat > driver.asm << '"'"'ASMEOF'"'"'
'"$(cat driver.asm)"'
ASMEOF

  echo "=== Assembling procedures.asm ==="
  nasm -f elf64 procedures.asm -o procedures.o

  echo "=== Assembling driver.asm ==="
  nasm -f elf64 driver.asm -o driver.o

  echo "=== Linking ==="
  ld procedures.o driver.o -o driver

  echo "=== Running ==="
  ./driver
'
