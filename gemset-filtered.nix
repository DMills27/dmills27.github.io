# Filtered gemset — removes non-native platform targets from sass-embedded to
# prevent build failures:
#   android  — binaries need liblog.so (Android-only system library)
#   musl     — binaries need libc.musl-*.so.1 (not available on glibc systems)
#   cygwin / mingw — Windows-only, irrelevant on Linux/macOS
# Regenerate gemset.nix with: nix run github:inscapist/bundix -- -l
let rawGemset = import ./gemset.nix; in
rawGemset // {
  sass-embedded = rawGemset.sass-embedded // {
    targets = builtins.filter
      (t:
        builtins.match ".*android.*"  t.target == null &&
        builtins.match ".*musl.*"     t.target == null &&
        builtins.match ".*cygwin.*"   t.target == null &&
        builtins.match ".*mingw.*"    t.target == null
      )
      rawGemset.sass-embedded.targets;
  };
}
