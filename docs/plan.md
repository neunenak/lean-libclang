# lean-libclang: Implementation Plan

Lean 4 bindings to libclang for parsing C source files and inspecting their ASTs.

## Architecture

**Two-layer approach:**

1. **Thin FFI bindings** — 1:1 wrapping of libclang's C API. Opaque pointer types, extern functions, and a small C shim to handle callback-based traversal. This layer is useful on its own for imperative AST exploration.

2. **Pure Lean AST types** (future) — Inductive types (`CDecl`, `CExpr`, `CType`, etc.) built by traversing via the thin layer. Consumers work with native Lean data structures instead of opaque pointers.

## Phase 1: FFI Foundation

- C shim layer (`c/clang_shim.c`) to bridge libclang's visitor-callback pattern. Lean FFI cannot directly pass Lean closures as C function pointers, so the shim collects child cursors into a buffer that Lean can consume as an array.
- `lakefile.toml` configuration: `[[c_src]]` for the shim, link args for `-lclang`.
- Opaque Lean types wrapping `CXIndex`, `CXTranslationUnit`, `CXCursor`.
- Lifecycle functions: `createIndex`, `parseTranslationUnit`, `disposeTranslationUnit`, `disposeIndex`.
- Cursor traversal: `getTranslationUnitCursor`, `getChildren` (returns `Array Cursor`).
- Cursor queries: `getCursorKind`, `getCursorSpelling`, `getCursorType`, `getCursorLocation`.
- `CursorKind` enum: subset of `CXCursorKind` + `other` fallback.

## Phase 2: Broader API Coverage

- More cursor/type query functions as needed.
- Source range and location utilities.
- Diagnostic surfacing.

## Phase 3: Pure Lean AST

- Define inductive types for C declarations, expressions, types, statements.
- Traversal function that converts the libclang AST into these Lean types.
- This is the primary consumer-facing API.

## Phase 4: Polish

- Resource safety (bracket patterns for index/TU lifecycle).
- Error handling and diagnostics as Lean-native errors.
- Test suite: parse known C files, assert on AST structure.
