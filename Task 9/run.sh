#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

IMAGE=asm-lab
docker build --platform linux/amd64 -t "$IMAGE" .. -q

docker run --rm "$IMAGE" bash -c '
  set -e
  mkdir -p /work && cd /work

  cat > sum.c << '"'"'EOF'"'"'
'"$(cat sum.c)"'
EOF

  echo "=== Build ==="
  gcc -O2 -o sum_opt  sum.c
  gcc -O0 -o sum_nopt sum.c
  echo "Built: sum_opt (gcc -O2)  and  sum_nopt (gcc -O0)"

  echo ""
  echo "=== Run: -O2 (optimised) ==="
  ./sum_opt

  echo ""
  echo "=== Run: -O0 (unoptimised) ==="
  ./sum_nopt

  echo ""
  echo "=== Disassembly: sum_c vs sum_asm (-O2 binary) ==="
  objdump -d -M intel sum_opt | awk "/^[0-9a-f]+ <sum_/{found=1} found{print} /^$/{if(found)found--}" | head -60
' 2>&1
