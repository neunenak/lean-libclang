import LeanLibclang

/-- Print an indented tree of the AST rooted at `cursor`. -/
partial def printAST (cursor : Clang.Cursor) (indent : Nat := 0) : IO Unit := do
  let kind ← Clang.getCursorKind cursor
  let spelling ← Clang.getCursorSpelling cursor
  let typeSpelling ← Clang.getCursorTypeSpelling cursor
  let loc ← Clang.getCursorLocation cursor
  let pad := "".pushn ' ' (indent * 2)
  IO.println s!"{pad}{repr kind} \"{spelling}\" type=\"{typeSpelling}\" {loc.file}:{loc.line}:{loc.column}"
  let children ← Clang.getChildren cursor
  for child in children do
    printAST child (indent + 1)

def main (args : List String) : IO Unit := do
  match args with
  | [] =>
    IO.eprintln "Usage: lean-libclang <file.c> [-- <clang-args>...]"
  | filename :: rest =>
    let clangArgs := rest.toArray
    let idx ← Clang.createIndex false true
    let tu ← Clang.parseTranslationUnit idx filename clangArgs
    let cursor ← Clang.getTranslationUnitCursor tu
    printAST cursor
