set pagination off
set disassembly-flavor intel
echo \n--- registers at _start entry ---\n
break _start
run
info registers rax rbx rcx r8 r9 r10 r12
echo \n--- array in memory (8 x qword) ---\n
x/8gd arr
echo \n--- after init (step 5): BUG1=rcx should be 0, BUG2=r9 should be large ---\n
stepi 5
info registers rcx r8 r9 r10
echo \n--- after first loop body (step 8): BUG3=r12 wrong from bad stride ---\n
stepi 8
info registers r8 r9 r10 r12
echo \n--- run to exit: final stats showing all bugs ---\n
continue
quit
