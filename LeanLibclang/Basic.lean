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
-- CursorKind (subset of CXCursorKind + catch-all)
-- ---------------------------------------------------------------------------

/-- A subset of `CXCursorKind` covering the most common C declaration,
    reference, expression, and statement kinds. -/
inductive CursorKind where
  -- Declarations
  | unexposedDecl        -- 1
  | structDecl           -- 2
  | unionDecl            -- 3
  | classDecl            -- 4
  | enumDecl             -- 5
  | fieldDecl            -- 6
  | enumConstantDecl     -- 7
  | functionDecl         -- 8
  | varDecl              -- 9
  | parmDecl             -- 10
  | typedefDecl          -- 20
  -- References
  | typeRef              -- 43
  | cxxBaseSpecifier     -- 44
  | templateRef          -- 45
  | namespaceRef         -- 46
  | memberRef            -- 47
  | labelRef             -- 48
  | overloadedDeclRef    -- 49
  | variableRef          -- 50
  -- Expressions
  | unexposedExpr        -- 100
  | declRefExpr          -- 101
  | memberRefExpr        -- 102
  | callExpr             -- 103
  | integerLiteral       -- 106
  | floatingLiteral      -- 107
  | stringLiteral        -- 109
  | charLiteral          -- 110
  | parenExpr            -- 111
  | unaryOperator        -- 112
  | arraySubscriptExpr   -- 113
  | binaryOperator       -- 114
  | compoundAssignOp     -- 115
  | conditionalOperator  -- 116
  | cStyleCastExpr       -- 117
  | initListExpr         -- 119
  -- Statements
  | unexposedStmt        -- 200
  | compoundStmt         -- 202
  | caseStmt             -- 203
  | defaultStmt          -- 204
  | ifStmt               -- 205
  | switchStmt           -- 206
  | whileStmt            -- 207
  | doStmt               -- 208
  | forStmt              -- 209
  | gotoStmt             -- 210
  | continueStmt         -- 212
  | breakStmt            -- 213
  | returnStmt           -- 214
  | declStmt             -- 231
  -- Translation unit
  | translationUnit      -- 350 (CXCursor_TranslationUnit = 300)
  -- Other
  | other (raw : UInt32)
  deriving Repr, BEq, Inhabited

namespace CursorKind

def ofRaw (n : UInt32) : CursorKind :=
  match n with
  | 1   => .unexposedDecl
  | 2   => .structDecl
  | 3   => .unionDecl
  | 4   => .classDecl
  | 5   => .enumDecl
  | 6   => .fieldDecl
  | 7   => .enumConstantDecl
  | 8   => .functionDecl
  | 9   => .varDecl
  | 10  => .parmDecl
  | 20  => .typedefDecl
  | 43  => .typeRef
  | 44  => .cxxBaseSpecifier
  | 45  => .templateRef
  | 46  => .namespaceRef
  | 47  => .memberRef
  | 48  => .labelRef
  | 49  => .overloadedDeclRef
  | 50  => .variableRef
  | 100 => .unexposedExpr
  | 101 => .declRefExpr
  | 102 => .memberRefExpr
  | 103 => .callExpr
  | 106 => .integerLiteral
  | 107 => .floatingLiteral
  | 109 => .stringLiteral
  | 110 => .charLiteral
  | 111 => .parenExpr
  | 112 => .unaryOperator
  | 113 => .arraySubscriptExpr
  | 114 => .binaryOperator
  | 115 => .compoundAssignOp
  | 116 => .conditionalOperator
  | 117 => .cStyleCastExpr
  | 119 => .initListExpr
  | 200 => .unexposedStmt
  | 202 => .compoundStmt
  | 203 => .caseStmt
  | 204 => .defaultStmt
  | 205 => .ifStmt
  | 206 => .switchStmt
  | 207 => .whileStmt
  | 208 => .doStmt
  | 209 => .forStmt
  | 210 => .gotoStmt
  | 212 => .continueStmt
  | 213 => .breakStmt
  | 214 => .returnStmt
  | 231 => .declStmt
  | 350 => .translationUnit
  | n   => .other n

end CursorKind

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
