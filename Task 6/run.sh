#!/usr/bin/env bash
# Task 6: Build and run the log-cleaning toolkit
set -e
cd "$(dirname "$0")"

IMAGE=asm-lab

docker build -t "$IMAGE" .. -q

docker run --rm -i "$IMAGE" bash -c '
  set -e
  mkdir -p /work && cd /work

  cat > toolkit.asm << '"'"'ASMEOF'"'"'
'"$(cat toolkit.asm)"'
ASMEOF

  echo "=== Assembling ==="
  nasm -f elf64 toolkit.asm -o toolkit.o

  echo "=== Linking ==="
  ld toolkit.o -o toolkit

  echo "=== Running ==="
  ./toolkit
'
