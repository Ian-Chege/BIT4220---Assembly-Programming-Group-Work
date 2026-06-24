/*
 * sum.c — Task 9: Inline Assembly & Performance Tuning
 * BIT 4220 Assembly Programming | Group Work
 *
 * Compares three implementations of array sum:
 *   sum_c()      — plain C loop (compiler-optimised)
 *   sum_asm()    — GCC inline assembly (hand-written loop)
 *   sum_c_nopt() — C loop compiled at -O0 for a fair unoptimised baseline
 *
 * Build:
 *   gcc -O2 -o sum sum.c          (optimised — default)
 *   gcc -O0 -o sum_nopt sum.c     (unoptimised baseline)
 */

#include <stdio.h>
#include <time.h>
#include <stdlib.h>

#define N     1000000   /* array length  */
#define REPS  200       /* timing repetitions */

static long arr[N];

/* ── 1. Pure C (compiled at whatever -O level is used) ── */
__attribute__((noinline))
long sum_c(const long *a, long n)
{
    long s = 0;
    for (long i = 0; i < n; i++) s += a[i];
    return s;
}

/* ── 2. Inline assembly — manual add loop ── */
__attribute__((noinline))
long sum_asm(const long *a, long n)
{
    long result = 0;
    long ptr = (long)a;   /* copy so we can increment it */

    __asm__ volatile (
        "xor    %0, %0          \n"   /* result = 0          */
        "test   %2, %2          \n"   /* if n == 0, skip     */
        "jz     2f              \n"
        "1:                     \n"
        "add    (%1), %0        \n"   /* result += *ptr      */
        "add    $8,   %1        \n"   /* ptr += 8            */
        "dec    %2              \n"   /* n--                 */
        "jnz    1b              \n"   /* loop while n != 0   */
        "2:                     \n"
        : "+r" (result),              /* output (also input) */
          "+r" (ptr),
          "+r" (n)
        :                             /* no pure inputs      */
        : "cc", "memory"
    );
    return result;
}

/* ── timing helper ── */
static double elapsed_ms(struct timespec start, struct timespec end)
{
    return (end.tv_sec - start.tv_sec) * 1000.0
         + (end.tv_nsec - start.tv_nsec) / 1e6;
}

int main(void)
{
    /* fill array: 0, 1, 2, … N-1  →  expected sum = N*(N-1)/2 */
    for (long i = 0; i < N; i++) arr[i] = i;
    long expected = (long)N * (N - 1) / 2;

    struct timespec t0, t1;
    volatile long res;   /* volatile prevents dead-code elimination */

    /* ── benchmark sum_c ── */
    clock_gettime(CLOCK_MONOTONIC, &t0);
    for (int r = 0; r < REPS; r++) res = sum_c(arr, N);
    clock_gettime(CLOCK_MONOTONIC, &t1);
    double ms_c = elapsed_ms(t0, t1);

    /* ── benchmark sum_asm ── */
    clock_gettime(CLOCK_MONOTONIC, &t0);
    for (int r = 0; r < REPS; r++) res = sum_asm(arr, N);
    clock_gettime(CLOCK_MONOTONIC, &t1);
    double ms_asm = elapsed_ms(t0, t1);

    /* ── results ── */
    long c_result   = sum_c(arr, N);
    long asm_result = sum_asm(arr, N);

    printf("\n=== Task 9: Array Sum Benchmark ===\n");
    printf("Array length : %d elements\n", N);
    printf("Repetitions  : %d\n\n", REPS);

    printf("%-20s  %12s  %10s  %8s\n",
           "Implementation", "Result", "Total(ms)", "Per-rep(us)");
    printf("%-20s  %12s  %10s  %8s\n",
           "--------------------", "------------", "----------", "--------");

    printf("%-20s  %12ld  %10.2f  %8.2f\n",
           "sum_c (C loop)",   c_result,   ms_c,   ms_c * 1000.0 / REPS);
    printf("%-20s  %12ld  %10.2f  %8.2f\n",
           "sum_asm (inline)", asm_result, ms_asm, ms_asm * 1000.0 / REPS);

    printf("\nExpected sum : %ld\n", expected);
    printf("C   correct  : %s\n", c_result   == expected ? "YES" : "NO");
    printf("ASM correct  : %s\n", asm_result == expected ? "YES" : "NO");

    double ratio = ms_asm > 0.0 ? ms_c / ms_asm : 0.0;
    printf("\nSpeed ratio (C / ASM) : %.2fx\n", ratio);
    if (ratio > 1.05)
        printf("Inline ASM is faster.\n");
    else if (ratio < 0.95)
        printf("C (compiler-optimised) is faster.\n");
    else
        printf("Both are roughly equal (within 5%%).\n");

    return 0;
}
