import Lake
open System Lake DSL

package «hex-mod-arith» where
  leanOptions := #[⟨`doc.verso, true⟩, ⟨`doc.verso.suggestions, false⟩]

require HexArith from git
  "https://github.com/leanprover/hex-arith.git" @ "v0.9.0"

private def zmod64MulOTarget (pkg : Package) : FetchM (Job FilePath) := do
  let oFile := pkg.dir / defaultBuildDir / "HexModArith" / "ffi" / "zmod64_mul.o"
  let srcTarget ← inputTextFile <| pkg.dir / "HexModArith" / "ffi" / "zmod64_mul.c"
  buildFileAfterDep oFile srcTarget fun srcFile => do
    -- `LEAN_EXPORTING` makes `LEAN_EXPORT` a dllexport on Windows, as Lake
    -- does for Lean's own C; a carrier DLL otherwise hides these symbols.
    let flags := #["-I", (← getLeanIncludeDir).toString, "-fPIC", "-O3",
      "-DLEAN_EXPORTING"]
    -- Mathlib's sandbox permits writes in the build directory, but not /tmp.
    -- Set TMPDIR for this compiler process only, including compiler wrappers.
    createParentDirs oFile
    proc {
      cmd := "cc"
      args := #["-c", "-o", oFile.toString, srcFile.toString] ++ flags
      env := #[("TMPDIR", some (← IO.FS.realPath (oFile.parent.getD ".")).toString)]
    }

target hexmodarithO pkg : FilePath := zmod64MulOTarget pkg

@[default_target]
lean_lib HexModArith where
  precompileModules := true

lean_lib HexModArithNative where
  roots := #[`HexModArithNative]
  globs := #[.one `HexModArithNative, .one `HexModArith.WordMod,
    .one `HexModArith.Residue]
  precompileModules := true
  moreLinkObjs := #[hexmodarithO]
