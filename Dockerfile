# Shared build image for the asm-lab x86-64 NASM tasks.
# Bakes nasm + binutils into the image ONCE so individual runs don't reinstall.
#
# Build (done automatically by run.sh if missing):
#   docker build --platform linux/amd64 -t asm-lab .
FROM --platform=linux/amd64 ubuntu:24.04

RUN apt-get update \
 && apt-get install -y --no-install-recommends nasm binutils gdb gcc libc-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /work