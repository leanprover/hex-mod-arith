import Lake

open System Lake DSL

package «hex-mod-arith» where
  leanOptions := #[⟨`doc.verso, true⟩, ⟨`doc.verso.suggestions, false⟩]

require HexArith from git
  "https://github.com/leanprover/hex-arith.git" @ "01ca010c2e94db5ec4abf9024ba60ecb9d6626ac"

private def zmod64MulOTarget (pkg : Package) : FetchM (Job FilePath) := do
  let oFile := pkg.dir / defaultBuildDir / "HexModArith" / "ffi" / "zmod64_mul.o"
  let srcTarget ← inputTextFile <| pkg.dir / "HexModArith" / "ffi" / "zmod64_mul.c"
  buildFileAfterDep oFile srcTarget fun srcFile => do
    compileO oFile srcFile #["-I", (← getLeanIncludeDir).toString, "-fPIC", "-O3"]

extern_lib hexmodarithffi (pkg) := do
  let name := nameToStaticLib "hexmodarithffi"
  let oTarget ← zmod64MulOTarget pkg
  buildStaticLib (pkg.staticLibDir / name) #[oTarget]

@[default_target]
lean_lib HexModArith where
  precompileModules := true
  moreLinkArgs := #["-lgmp"]
