# SUScript — A Bengali-Keyword Programming Language & Compiler

> A compiler project built with **Flex** and **Bison** that compiles a custom programming language — **SUScript** — whose keywords are written in Romanized Bengali. The compiler translates `.sus` source files into C code, with support for Three-Address Code (TAC) generation and compile-time constant folding.

---

## Table of Contents

- [SUScript — A Bengali-Keyword Programming Language \& Compiler](#suscript--a-bengali-keyword-programming-language--compiler)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Language Features](#language-features)
  - [Keyword Reference](#keyword-reference)
    - [Types](#types)
    - [Boolean Literals](#boolean-literals)
    - [Program Structure](#program-structure)
    - [Control Flow](#control-flow)
    - [Input / Output](#input--output)
  - [Project Architecture](#project-architecture)
  - [Prerequisites](#prerequisites)
  - [Building the Compiler](#building-the-compiler)
  - [Usage](#usage)
    - [Compiling a `.sus` file](#compiling-a-sus-file)
    - [Viewing Three-Address Code (TAC)](#viewing-three-address-code-tac)
  - [Running Tests](#running-tests)
    - [Run a single test](#run-a-single-test)
    - [Run all tests](#run-all-tests)
  - [Code Examples](#code-examples)
    - [Hello World](#hello-world)
    - [Variables and Types](#variables-and-types)
    - [Conditionals](#conditionals)
    - [Loops](#loops)
    - [Functions and Recursion](#functions-and-recursion)
    - [Input / Output](#input--output-1)
  - [File Structure](#file-structure)
  - [Author](#author)
---

## Overview

SUScript is a statically-typed, procedural language that uses **Romanized Bengali words** as keywords instead of English. It was designed as a compiler construction project to demonstrate all major compiler phases:

- **Lexical Analysis** — Flex-based tokenizer (`suscript.l`)
- **Parsing & Semantic Analysis** — Bison-based LALR(1) parser with type checking (`suscript.y`)
- **Symbol Table Management** — Scoped symbol table with type tracking
- **Constant Folding** — Compile-time evaluation of constant expressions
- **Intermediate Code Generation** — Three-Address Code (TAC) output
- **Code Generation** — Transpilation to valid C code

---

## Language Features

| Feature | Status |
|---|---|
| Primitive types: `int`, `float`, `char`, `bool` | ✅ |
| Constants (`const`) | ✅ |
| Arithmetic & compound assignment operators | ✅ |
| Relational & logical operators | ✅ |
| Increment / Decrement (`++`, `--`) | ✅ |
| `if` / `else if` / `else` conditionals | ✅ |
| `for` loop | ✅ |
| `while` and `do-while` loops | ✅ |
| `break` and `continue` | ✅ |
| User-defined functions with return types | ✅ |
| Recursive functions | ✅ |
| `print` and `println` I/O | ✅ |
| `scan` (user input) | ✅ |
| Single-line and multi-line comments | ✅ |
| Implicit type coercion with warnings | ✅ |
| Compile-time constant folding | ✅ |
| Three-Address Code (TAC) generation | ✅ |
| Semantic error detection | ✅ |

---

## Keyword Reference

SUScript uses Romanized Bengali keywords in place of standard English ones.

### Types

| SUScript Keyword | Meaning |
|---|---|
| `purno` | `int` (integer) |
| `doshomik` | `float` (floating-point) |
| `okkhor` | `char` (character) |
| `tainaki` | `bool` (boolean) |
| `dhoreNao` | `const` (constant) |

### Boolean Literals

| SUScript Keyword | Meaning |
|---|---|
| `shotto` | `true` |
| `mittha` | `false` |

### Program Structure

| SUScript Keyword | Meaning |
|---|---|
| `asolkaj` | `main` (entry point) |
| `kaj` | `func` (function definition) |
| `ferot` | `return` |

### Control Flow

| SUScript Keyword | Meaning |
|---|---|
| `jodi` | `if` |
| `nahole jodi` | `else if` |
| `nahole` | `else` |
| `shuru` | `for` |
| `jotokkhon` | `while` |
| `koro` | `do` |
| `thamo` | `break` |
| `porer_bar` | `continue` |

### Input / Output

| SUScript Keyword | Meaning |
|---|---|
| `lekho(...)` | `print(...)` — print without newline |
| `lekhoLine(...)` | `println(...)` — print with newline |
| `poro(...)` | `scan(...)` — read user input |

---

## Project Architecture

```
suscript.l          →  Lexer  (Flex)         : tokenizes .sus source
suscript.y          →  Parser (Bison)        : grammar, semantic checks, C code output
symbol_table.c/.h   →  Symbol Table          : scoped variable/type tracking
constant_fold.c/.h  →  Constant Folding      : compile-time expression evaluation
tac.c/.h            →  TAC Generator         : three-address intermediate code output
Makefile            →  Build system
test_*.sus          →  Test programs
```

**Compilation Pipeline:**

```
source.sus  →  [Flex Lexer]  →  Tokens
                                   ↓
                            [Bison Parser]
                                   ↓
                   ┌───────────────┼──────────────────┐
                   ↓               ↓                  ↓
           Symbol Table    Constant Folding       TAC Output
                                   ↓                (tac.txt)
                           Generated C Code
                               (_t.c)
                                   ↓
                           [gcc compilation]
                                   ↓
                           Native Executable
```

---

## Prerequisites

Make sure the following tools are installed on your system:

```bash
# On Debian / Ubuntu
sudo apt-get install flex bison gcc make

# On Fedora / RHEL
sudo dnf install flex bison gcc make

# On macOS (via Homebrew)
brew install flex bison gcc make
```

Verify the installations:

```bash
flex --version
bison --version
gcc --version
```

---

## Building the Compiler

Clone the repository and build using `make`:

```bash
git clone https://github.com/sakincse21/SUScript-Lanugage-Compiler.git
cd SUScript-Lanugage-Compiler
make
```

This will:
1. Run Bison on `suscript.y` to produce `suscript.tab.c` and `suscript.tab.h`
2. Run Flex on `suscript.l` to produce `lex.yy.c`
3. Compile all C files into the `suscript` binary

To clean all build artifacts:

```bash
make clean
```

---

## Usage

### Compiling a `.sus` file

```bash
./suscript <input_file.sus> <output_file.c>
```

**Example:**

```bash
./suscript test_01_variables.sus output.c
gcc -o output output.c
./output
```

### Viewing Three-Address Code (TAC)

TAC is automatically written to `tac.txt` during compilation. You can use the `tac` Makefile target to view it easily:

```bash
make tac FILE=test_04_if_else.sus
```

---

## Running Tests

The project includes 12 test programs that cover all language features. You can run them individually or all at once.

### Run a single test

```bash
make t01    # Variables & Assignment
make t02    # Arithmetic & Constant Folding
make t03    # Relational & Logical Operators
make t04    # If / Else-If / Else
make t05    # For Loop
make t06    # While & Do-While
make t07    # Functions
make t08    # Input & Output
make t09    # Type System & Implicit Conversion
make t10    # Constant Folding (shows generated C with folded values)
make t11    # Comments
make t12    # Semantic Error Detection
```

### Run all tests

```bash
make testall
```

Output is saved to `testall_output.txt`.

---

## Code Examples

### Hello World

```suscript
purno asolkaj() {
    lekhoLine("Assalamu Alaikum, Duniya!");
    ferot 0;
}
```

### Variables and Types

```suscript
purno asolkaj() {
    purno x = 42;
    doshomik pi = 3.14;
    okkhor grade = 'A';
    tainaki passed = shotto;
    dhoreNao purno MAX = 100;

    lekho("x = "); lekhoLine(x);
    lekho("pi = "); lekhoLine(pi);
    ferot 0;
}
```

### Conditionals

```suscript
purno asolkaj() {
    purno score = 72;

    jodi (score >= 90) {
        lekhoLine("Grade: A+");
    } nahole jodi (score >= 70) {
        lekhoLine("Grade: B");
    } nahole {
        lekhoLine("Grade: F");
    }

    ferot 0;
}
```

### Loops

```suscript
purno asolkaj() {
    // for loop
    shuru (purno i = 1; i <= 5; i++) {
        lekhoLine(i);
    }

    // while loop
    purno n = 10;
    jotokkhon (n > 0) {
        n -= 3;
    }

    ferot 0;
}
```

### Functions and Recursion

```suscript
purno factorial(purno n) {
    jodi (n <= 1) {
        ferot 1;
    }
    ferot n * factorial(n - 1);
}

purno asolkaj() {
    lekho("5! = ");
    lekhoLine(factorial(5));
    ferot 0;
}
```

### Input / Output

```suscript
purno asolkaj() {
    purno num;
    lekho("Enter a number: ");
    poro(num);
    lekho("You entered: ");
    lekhoLine(num);
    ferot 0;
}
```

---

## File Structure

```
suscript/
├── suscript.l                      # Flex lexer specification
├── suscript.y                      # Bison parser + semantic actions
├── symbol_table.c                  # Scoped symbol table implementation
├── symbol_table.h
├── constant_fold.c                 # Compile-time constant folding
├── constant_fold.h
├── tac.c                           # Three-Address Code generation
├── tac.h
├── Makefile                        # Build system
├── test_01_variables.sus           # Variables & assignment
├── test_02_arithmetic.sus          # Arithmetic expressions
├── test_03_relational_logical.sus  # Relational & logical operators
├── test_04_if_else.sus             # Conditional statements
├── test_05_for_loop.sus            # For loops
├── test_06_while_dowhile.sus       # While & do-while loops
├── test_07_functions.sus           # Functions & recursion
├── test_08_input_output.sus        # I/O operations
├── test_09_type_system.sus         # Type system & coercion
├── test_10_constant_folding.sus    # Constant folding demo
├── test_11_comments.sus            # Comments
└── test_12_error_handling.sus      # Semantic error detection
```

---

## Author

**Student ID:** 2107103  
**Course:** Compiler Design  Laboratory (CSE3212)
**Institution:** Khulna University of Engineering & Technology
**Report:** [Report File PDF](/Compiler_Report_2107103.pdf)
