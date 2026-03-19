-- ---------------------------------------------------------------------------
-- CursorKind (subset of CXCursorKind + catch-all)
-- ---------------------------------------------------------------------------

/-- A subset of `CXCursorKind` covering the most common C declaration,
    reference, expression, and statement kinds. See
    https://github.com/llvm/llvm-project/blob/main/clang/include/clang-c/Index.h#L1186
    -/
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

instance : ToString CursorKind where
  toString k :=
    let r := repr k |>.pretty
    let pfx := "CursorKind."
    if r.startsWith pfx then (r.drop pfx.length).toString else r

end CursorKind
