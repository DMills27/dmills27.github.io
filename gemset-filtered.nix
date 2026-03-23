# Filtered gemset — removes android platform targets from sass-embedded to
# prevent build failures (android binaries require liblog.so, an Android-only
# system library that is not available on Linux or NixOS).
# Regenerate gemset.nix with: nix run github:inscapist/bundix -- -l
let rawGemset = import ./gemset.nix; in
rawGemset // {
  sass-embedded = rawGemset.sass-embedded // {
    targets = builtins.filter
      (t: builtins.match ".*android.*" t.target == null)
      rawGemset.sass-embedded.targets;
  };
}
