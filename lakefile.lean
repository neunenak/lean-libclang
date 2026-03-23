import Lake
open System Lake DSL

package «lean-libclang»

structure ClangConfig where
  includeDir : String
  libDir : String
  deriving Inhabited


namespace ClangConfig

private def default : ClangConfig :=
  { includeDir := "/usr/include", libDir := "/usr/lib" }

end ClangConfig

/-- Try running a command and return its stdout trimmed, or `none` on failure. -/
private def runCmd (cmd : String) (args : Array String) : IO (Option String) := do
  try
    let out ← IO.Process.output { cmd, args, stdin := .null }
    if out.exitCode == 0 then
      return some out.stdout.trimAscii.toString
    else
      return none
  catch _ =>
    return none

/-- Detect libclang include and lib directories.
    Checks in order:
    1. LIBCLANG_PREFIX env var (expects include/ and lib/ subdirs)
    2. llvm-config (tries versioned names)
    3. Common system defaults (checks for clang-c/Index.h) -/
private def detectLibclang : IO ClangConfig := do
  -- 1. Explicit env var
  if let some pfx ← IO.getEnv "LIBCLANG_PREFIX" then
    return { includeDir := s!"{pfx}/include", libDir := s!"{pfx}/lib" }

  -- 2. Try llvm-config variants
  let configs := #["llvm-config",
                    "llvm-config-19", "llvm-config-18", "llvm-config-17",
                    "llvm-config-16", "llvm-config-15", "llvm-config-14"]
  for cfg in configs do
    if let some includeDir ← runCmd cfg #["--includedir"] then
      if let some libDir ← runCmd cfg #["--libdir"] then
        return { includeDir, libDir }

  -- 3. Platform defaults
  let defaults := #[
    ("/usr/lib/llvm/include", "/usr/lib/llvm/lib"),
    ("/usr/include", "/usr/lib"),
    ("/usr/local/include", "/usr/local/lib"),
    -- Homebrew (Apple Silicon / Intel)
    ("/opt/homebrew/opt/llvm/include", "/opt/homebrew/opt/llvm/lib"),
    ("/usr/local/opt/llvm/include", "/usr/local/opt/llvm/lib")
  ]
  for (includeDir, libDir) in defaults do
    if ← FilePath.pathExists (includeDir / "clang-c" / "Index.h") then
      return { includeDir, libDir }

  IO.eprintln "Warning: Could not detect libclang. Set LIBCLANG_PREFIX to your LLVM install prefix."
  IO.eprintln "  e.g. LIBCLANG_PREFIX=/usr/lib/llvm-18 lake build"
  return ClangConfig.default

-- `moreLinkArgs` in lean_lib/lean_exe requires a pure value, so we must use
-- unsafeBaseIO to run the IO-based detection at elaboration time.
private unsafe def clangConfigImpl : ClangConfig :=
  match unsafeBaseIO (EIO.toBaseIO detectLibclang) with
  | .ok cfg => cfg
  | .error _ => ClangConfig.default

@[implemented_by clangConfigImpl]
private opaque clangConfig : ClangConfig

-- Compile the C shim
target «clang_shim.o» pkg : FilePath := do
  logInfo "Compiling clang_shim"
  let oFile := pkg.buildDir / "c" / "clang_shim.o"
  let srcJob ← inputTextFile <| pkg.dir / "c" / "clang_shim.c"
  let weakArgs := #["-I", (← getLeanIncludeDir).toString, "-I", clangConfig.includeDir]
  buildO oFile srcJob weakArgs #["-fPIC"] "cc" getLeanTrace

-- Package the C shim into a static library
extern_lib libclangshim pkg := do
  let shimO ← «clang_shim.o».fetch
  let name := nameToStaticLib "clangshim"
  buildStaticLib (pkg.staticLibDir / name) #[shimO]

def moreLinkArgs: Array String := #[s!"-L{clangConfig.libDir}", "-lclang"]

@[default_target]
lean_lib LeanLibclang where
  moreLinkArgs := moreLinkArgs

@[default_target]
lean_exe «lean-libclang» where
  root := `Main
  moreLinkArgs := moreLinkArgs
