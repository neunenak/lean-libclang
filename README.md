# lean-libclang

Lean 4 bindings to [libclang](https://clang.llvm.org/doxygen/group__CINDEX.html), the stable C API for parsing C/C++ source files and traversing their ASTs.

## Overview

This library provides a thin FFI wrapper around libclang's cursor-based AST API. You can use it to:

- Parse C source files into translation units
- Traverse the AST using cursors
- Query cursor kind, spelling, type, and source location
- Filter declarations by origin (main file vs. included headers vs. system headers)

A higher-level API with pure Lean inductive types for the C AST is planned but not yet implemented.

## Prerequisites

- [Nix](https://nixos.org/) (with flakes enabled)

All other dependencies (Lean 4 toolchain, libclang, C compiler) are provided by the Nix flake.

## Building

```sh
nix develop --command lake build
```

## Running

The included executable parses a C file and prints its AST:

```sh
nix develop --command .lake/build/bin/lean-libclang path/to/file.c
```

You can pass extra clang arguments after the filename:

```sh
nix develop --command .lake/build/bin/lean-libclang file.c -std=c11 -DFOO=1
```

## Using as a library

Add this repository as a Lake dependency and `import LeanLibclang`. The main API is in the `Clang` namespace:

```lean
let idx ← Clang.createIndex (excludeDeclsFromPCH := false) (displayDiagnostics := true)
let tu ← Clang.parseTranslationUnit idx "example.c" #[]
let cursor ← Clang.getTranslationUnitCursor tu
let children ← Clang.getChildren cursor
for child in children do
  let fromMain ← Clang.isFromMainFile child
  if fromMain then
    let kind ← Clang.getCursorKind child
    let spelling ← Clang.getCursorSpelling child
    IO.println s!"{repr kind}: {spelling}"
```

## Project structure

```
├── flake.nix                 # Nix flake (Lean toolchain + libclang)
├── lakefile.lean              # Lake build config (C shim + linking)
├── c/clang_shim.c            # C FFI shim bridging libclang and Lean
├── LeanLibclang/Basic.lean   # Lean API: opaque types, CursorKind, extern decls
├── LeanLibclang.lean          # Library root
├── Main.lean                  # Example: AST printer
└── docs/plan.md              # Implementation roadmap
```
