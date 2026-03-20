import Lake
open System Lake DSL

package «lean-libclang»

-- Compile the C shim
target «clang_shim.o» pkg : FilePath := do
  let oFile := pkg.buildDir / "c" / "clang_shim.o"
  let srcJob ← inputTextFile <| pkg.dir / "c" / "clang_shim.c"
  let weakArgs := #["-I", (← getLeanIncludeDir).toString]
  buildO oFile srcJob weakArgs #["-fPIC"] "cc" getLeanTrace

-- Package the C shim into a static library
extern_lib libclangshim pkg := do
  let shimO ← «clang_shim.o».fetch
  let name := nameToStaticLib "clangshim"
  buildStaticLib (pkg.staticLibDir / name) #[shimO]

@[default_target]
lean_lib LeanLibclang where
  moreLinkArgs := #["-L/usr/lib", "-lclang"]

@[default_target]
lean_exe «lean-libclang» where
  root := `Main
  moreLinkArgs := #["-L/usr/lib", "-lclang"]
