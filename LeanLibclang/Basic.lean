import LeanLibclang.CursorKind

namespace Clang

-- ---------------------------------------------------------------------------
-- Opaque types
-- ---------------------------------------------------------------------------

/-- An opaque handle to a libclang index (a set of translation units). -/
opaque Index.Nonempty : NonemptyType
def Index : Type := Index.Nonempty.type
instance : Nonempty Index := Index.Nonempty.property

/-- An opaque handle to a parsed translation unit. -/
opaque TranslationUnit.Nonempty : NonemptyType
def TranslationUnit : Type := TranslationUnit.Nonempty.type
instance : Nonempty TranslationUnit := TranslationUnit.Nonempty.property

/-- An opaque handle to a cursor pointing into the AST. -/
opaque Cursor.Nonempty : NonemptyType
def Cursor : Type := Cursor.Nonempty.type
instance : Nonempty Cursor := Cursor.Nonempty.property


-- ---------------------------------------------------------------------------
-- Source location
-- ---------------------------------------------------------------------------

/-- A decoded source location: file path, line, and column. -/
structure SourceLocation where
  file   : String
  line   : UInt32
  column : UInt32
  deriving Repr, BEq, Inhabited

-- ---------------------------------------------------------------------------
-- FFI declarations
-- ---------------------------------------------------------------------------

/-- Create a new index. `excludeDeclsFromPCH` and `displayDiagnostics`
    correspond to the libclang parameters of the same name. -/
@[extern "lean_clang_createIndex"]
opaque createIndex (excludeDeclsFromPCH : Bool)
                   (displayDiagnostics : Bool) : IO Index

/-- Parse a source file into a translation unit.
    `args` are extra command-line arguments passed to clang (e.g. `#["-std=c11"]`). -/
@[extern "lean_clang_parseTranslationUnit"]
opaque parseTranslationUnit (idx : @& Index)
                             (filename : @& String)
                             (args : @& Array String) : IO TranslationUnit

/-- Get the root cursor of a translation unit. -/
@[extern "lean_clang_getTranslationUnitCursor"]
opaque getTranslationUnitCursor (tu : @& TranslationUnit) : IO Cursor

/-- Get the kind of a cursor (as a raw UInt32 from CXCursorKind). -/
@[extern "lean_clang_getCursorKind"]
opaque getCursorKindRaw (cursor : @& Cursor) : IO UInt32

/-- Get the kind of a cursor. -/
def getCursorKind (cursor : Cursor) : IO CursorKind := do
  let raw ← getCursorKindRaw cursor
  return CursorKind.ofRaw raw

/-- Get the spelling (name) of a cursor. -/
@[extern "lean_clang_getCursorSpelling"]
opaque getCursorSpelling (cursor : @& Cursor) : IO String

/-- Get the spelling of the cursor's type (e.g. "int", "struct foo"). -/
@[extern "lean_clang_getCursorTypeSpelling"]
opaque getCursorTypeSpelling (cursor : @& Cursor) : IO String

/-- Get the raw CXTypeKind of the cursor's type. -/
@[extern "lean_clang_getCursorTypeKind"]
opaque getCursorTypeKindRaw (cursor : @& Cursor) : IO UInt32

/-- Returns `true` if the cursor's location is in the main file
    (i.e. not from an `#include`d header). -/
@[extern "lean_clang_isFromMainFile"]
opaque isFromMainFile (cursor : @& Cursor) : IO Bool

/-- Returns `true` if the cursor's location is in a system header. -/
@[extern "lean_clang_isInSystemHeader"]
opaque isInSystemHeader (cursor : @& Cursor) : IO Bool

@[extern "lean_clang_getCursorFile"]
private opaque getCursorFile (cursor : @& Cursor) : IO String

@[extern "lean_clang_getCursorLine"]
private opaque getCursorLine (cursor : @& Cursor) : IO UInt32

@[extern "lean_clang_getCursorColumn"]
private opaque getCursorColumn (cursor : @& Cursor) : IO UInt32

/-- Get the source location of a cursor. -/
def getCursorLocation (cursor : Cursor) : IO SourceLocation := do
  let file ← getCursorFile cursor
  let line ← getCursorLine cursor
  let column ← getCursorColumn cursor
  return { file, line, column }

/-- Get the immediate children of a cursor. -/
@[extern "lean_clang_getChildren"]
opaque getChildren (cursor : @& Cursor) : IO (Array Cursor)

/-- Check if a cursor is null. -/
@[extern "lean_clang_cursorIsNull"]
opaque cursorIsNull (cursor : @& Cursor) : IO Bool

/-- Dispose of a translation unit (can also just let GC handle it). -/
@[extern "lean_clang_disposeTranslationUnit"]
opaque disposeTranslationUnit (tu : TranslationUnit) : IO Unit

/-- Dispose of an index (can also just let GC handle it). -/
@[extern "lean_clang_disposeIndex"]
opaque disposeIndex (idx : Index) : IO Unit

end Clang
