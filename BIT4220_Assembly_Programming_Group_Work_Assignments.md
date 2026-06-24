# BIT 4220: Assembly Programming
## Group Work Task ( 50 marks)

### Group Work Requirements

Recommended group size: 5 to 8 students.
Each group must maintain a version-controlled repository with source code, README,

---

### Task 1: Assembly Environment and Digital Representation Toolkit

A small IT training centre wants a low-level demonstration toolkit that helps first-year students understand how the CPU sees numbers and characters. Your group will create simple NASM programs that print messages, display register-sized constants, and demonstrate binary, hexadecimal, ASCII, two's complement and little-endian storage concepts.

**Modern relevance:** reverse engineering, digital forensics, exploit analysis, firmware inspection and debugging all require understanding how data appears in registers and memory.

**Practical tasks**

1. Write a hello-world style assembly program and document the build process.
2. Create a program that stores bytes, words and doublewords and prints their ASCII interpretation where appropriate.
3. Use GDB or objdump to inspect memory layout and show evidence through screenshots.
4. Prepare a short tutorial for other students explaining how to compile, link and run the programs.

**Deliverables**

a) Source files and Makefile or build script.
b) README with setup steps, commands and screenshots.
c) Two-page technical note on data representation.

---

### Task 2: Student Marks Processor Using Registers and Addressing Modes

A department needs a tiny command-line routine that processes marks stored in memory. The solution must demonstrate immediate, register, direct, indirect, indexed and based addressing while computing totals and simple classifications.

**Modern relevance:** data-parsing routines in embedded systems and security tools often process small buffers directly at memory level.

**Practical tasks**

1. Define an array of at least ten marks in memory.
2. Compute total, average, highest and lowest mark using registers and loops.
3. Use at least three addressing modes and explain where each is used.
4. Display classification counts such as pass, fail, credit and distinction.

**Deliverables**

a) Working NASM program.
b) Memory map showing variables, arrays and offsets.
c) Commentary comparing assembly indexing with C/Python indexing.
d) Test cases for boundary marks such as 0, 39, 40, 69, 70 and 100.

---

### Task 3: Mini Arithmetic Logic Unit for an Embedded Billing Device

A prepaid utility meter requires a small low-level computation module to add units, subtract usage, multiply rates, divide balances and apply bit masks for device status. Your group will create a menu-driven ALU simulator in assembly.

**Modern relevance:** bitwise operations are used in device-status registers, cryptography, compression, networking headers and hardware control.

**Practical tasks**

1. Read two small numbers from keyboard input using Linux system calls.
2. Implement arithmetic and logical operations through a menu.
3. Demonstrate how flags change after selected operations using GDB.
4. Add validation for invalid menu choices and simple overflow cases.

**Deliverables**

a) ALU simulator source code.
b) Flag analysis table with at least six tested operations.
c) Screenshots of register and flag inspection.
d) Short discussion on why overflow matters in real systems.

---

### Task 4: Control Structures Translator for High-Level Logic

A programming lecturer wants students to see how common high-level constructs are translated into assembly. Your group will implement if-else, while, do-while, for-loop and switch-case examples using jumps, comparisons and labels.

**Modern relevance:** malware analysis, compiler design and binary patching require understanding how branches and loops are represented in machine code.

**Practical tasks**

a) Write a high-level pseudocode version of each construct.
b) Translate each construct into assembly and test it.
c) Build a menu program where each option runs one construct.
d) Explain how the instruction pointer changes during branching and looping.

**Deliverables**

a) Pseudocode and assembly implementation.
b) Flowchart for each construct.
c) Test cases showing different branch outcomes.
d) Group presentation comparing high-level and low-level control flow.

---

### Task 5: Secure Procedure Library and Stack-Based Function Calls

A software team wants reusable assembly routines for small utilities such as factorial, string length, maximum of three numbers and numeric conversion. Your group will build a procedure library and document how parameters and return values are handled.

**Modern relevance:** stack discipline is central to secure programming, buffer overflow prevention, reverse engineering and calling external libraries.

**Practical tasks**

1. Implement at least four reusable procedures.
2. Preserve registers where necessary and document calling conventions.
3. Add a test driver that calls each procedure with several inputs.
4. Identify one unsafe stack practice and explain how it could cause faults or vulnerabilities.

**Deliverables**

a) Procedure library and test driver.
b) Stack diagram for each procedure.
c) Register preservation checklist.
d) Security reflection on stack misuse.

---

### Task 6: String and Array Toolkit for Log Cleaning

A helpdesk receives simple text logs from legacy devices. They need a low-level routine that converts lowercase letters to uppercase, reverses strings, counts characters, scans for a keyword and processes byte arrays.

**Modern relevance:** log parsing, packet inspection, intrusion detection and embedded diagnostics often require fast byte-level processing.

**Practical tasks**

1. Read or define a sample log string.
2. Convert lowercase letters to uppercase.
3. Reverse a string or byte array.
4. Count digits, letters, spaces and special characters.
5. Search for a short keyword and report whether it exists.

**Deliverables**

a) String/array toolkit source code.
b) Before-and-after output evidence.
c) Algorithm explanation with memory diagrams.
d) Test cases with normal, empty, long and mixed-character strings.

---

### Task 7: File-Based Sensor Data Parser Using System Calls

An IoT gateway stores temperature or energy readings in a small text file. Your group must write assembly routines that open, read, process and write results using Linux system calls.

**Modern relevance:** system calls are the basis of command-line tools, sandboxing, file forensics, operating system utilities and secure systems programming.

**Practical tasks**

1. Create a sample input file with numeric readings.
2. Read data into a buffer and count records or valid characters.
3. Compute a simple statistic such as count, sum or maximum for single-digit readings, or explain limitations for multi-digit parsing.
4. Write a summary to screen or an output file.

**Deliverables**

a) File parser program and sample input/output files.
b) System-call trace or explanation of register usage.
c) Buffer layout diagram.
d) Testing evidence for missing file, empty file and normal file.

---

### Task 8: Debugging and Reverse Engineering a Faulty Assembly Program

A legacy assembly program used in a lab is failing because of wrong register usage, incorrect jump conditions and memory-size mismatches. Your group acts as a debugging and reverse-engineering team.

**Modern relevance:** debugging and reverse engineering are key skills in cybersecurity, malware analysis, vulnerability research and software maintenance.

**Practical tasks**

1. Create or receive a faulty assembly program with at least five planted defects.
2. Debug the program using breakpoints, single-stepping and register inspection.
3. Produce a corrected version and compare the output before and after correction.
4. Use objdump or readelf to inspect the generated binary.

**Deliverables**

a) Faulty and corrected source files.
b) Bug table showing symptom, cause, fix and test evidence.
c) Debugger screenshots or command logs.
d) Brief reverse-engineering note explaining what the binary does.

---

### Task 9: Inline Assembly and Performance Tuning in a High-Level Program

A software company has a performance-sensitive routine in C/C++ that repeatedly processes numbers. Your group will compare a high-level implementation, a pure assembly routine and an inline assembly version.

**Modern relevance:** performance tuning is used in cryptography, multimedia, network processing, games, operating systems and scientific computing, although modern compilers often optimize well.

**Practical tasks**

1. Implement a simple routine such as array sum, byte count, checksum, bit mask operation or string length in C/C++.
2. Implement the same logic using assembly or inline assembly.
3. Benchmark both versions using repeated runs and record results.
4. Analyze why one version is faster, slower or similar.

**Deliverables**

a) C/C++ and assembly source files.
b) Build commands linking the programs.
c) Benchmark table and discussion.
d) Trade-off analysis covering speed, readability, portability and debugging difficulty.

---

### Task 10: Modern Assembly Application Portfolio and Final Integrated Demonstration

Your group has been contracted to prepare a final portfolio showing how assembly programming is still useful in modern IT. The portfolio should integrate at least three previous assignments into one themed demonstration, such as cybersecurity analysis, embedded/IoT data processing, OS utilities, or performance-critical routines.

**Modern relevance:** assembly remains important in firmware, device drivers, bootloaders, embedded systems, exploit mitigation, reverse engineering, malware analysis, optimized libraries and hardware-aware programming.

**Practical tasks**

1. Select a theme: cybersecurity/reverse engineering, IoT/embedded systems, OS utilities, performance optimization, or digital forensics.
2. Integrate at least three modules from earlier assignments.
3. Include a debugging/testing section and a performance or memory-use discussion.
4. Prepare a final demonstration and individual contribution report.

**Deliverables**

Integrated source code and repository.
Final technical report of 6 to 8 pages.
Presentation slides or poster.
