# NixOS + Jekyll + sass-embedded: Setup & Fix Notes

This document records the issues encountered getting `nix develop` + `bundle exec jekyll serve` working on NixOS (x86_64-linux) and how they were resolved.

---

## Problem 1: `nix develop` fails with missing attribute

**Error:**
```
error: flake does not provide attribute 'devShells.x86_64-linux.default'
```

**Cause:** The original `flake.nix` hardcoded `system = "aarch64-darwin"`, so all flake outputs were only defined for that system. Running on any other system (e.g. `x86_64-linux`) produced this error.

**Fix:** Replace the hardcoded system with a `forAllSystems` pattern:

```nix
supportedSystems = [ "x86_64-linux" "aarch64-darwin" ];
forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
```

Then derive all packages and devShells per-system using `outputsFor system`.

---

## Problem 2: `bundle exec jekyll serve` fails with broken pipe

**Error:**
```
Could not start dynamically linked executable: .../sass-embedded-1.77.5-x86_64-linux-gnu/ext/sass/dart-sass/src/dart
NixOS cannot run dynamically linked executables intended for generic linux environments
Broken pipe
```

**Cause:** The `sass-embedded` gem (pulled in transitively by `jekyll-sass-converter` v3+) ships a pre-compiled `dart` binary. On NixOS, the filesystem layout differs from a standard Linux distribution — there is no `/lib64/ld-linux-x86-64.so.2` dynamic linker at the standard path. NixOS cannot run binaries compiled against the standard glibc path without intervention.

This affects `bundle exec` specifically because `BUNDLE_PATH=vendor/bundle` directs Bundler to install gems into `vendor/bundle` itself, downloading the pre-built `sass-embedded` binary from RubyGems. This bypasses `ruby-nix`'s Nix store builds, so `gemConfig` overrides (e.g. `autoPatchelfHook`) have no effect on these gems.

**Why `gemConfig` alone doesn't work:** `gemConfig` in `ruby-nix` only patches gems built inside the Nix store. Since the devShell uses `BUNDLE_PATH=vendor/bundle` and `bundle install` fetches gems from RubyGems into that path, the dart binary in `vendor/bundle` is never touched by Nix's build machinery.

**Fix:** Patch the dart binary at shell entry time using `patchelf` in the `shellHook`, rewriting its ELF interpreter to point at the NixOS glibc:

```nix
deps = with pkgs; [ env ruby bundixcli texlivePkgs patchelf ];

devShell = pkgs.mkShell {
  shellHook = ''
    export BUNDLE_PATH=vendor/bundle
    ${pkgs.lib.optionalString pkgs.stdenv.isLinux ''
      _dart=$(find vendor/bundle -name "dart" -path "*/dart-sass/src/dart" -type f 2>/dev/null | head -1)
      if [ -n "$_dart" ]; then
        patchelf \
          --set-interpreter "${pkgs.stdenv.cc.libc}/lib/ld-linux-x86-64.so.2" \
          --set-rpath "${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}" \
          "$_dart" 2>/dev/null || true
      fi
    ''}
  '';
  buildInputs = deps;
};
```

The `optionalString pkgs.stdenv.isLinux` guard ensures this is a no-op on macOS (where `patchelf` isn't relevant and the dart binary is a Mach-O executable anyway).

---

## Problem 3: Missing `gemset.nix`

**Cause:** `ruby-nix` requires a `gemset.nix` file — a Nix-specific lockfile generated from `Gemfile.lock` — but this file is not committed to the repo.

**Fix:** Generate it using `bundix`:

```bash
nix run github:inscapist/bundix -- -l
```

This reads `Gemfile.lock` and produces `gemset.nix`. Commit this file alongside `Gemfile.lock`.

---

## Normal workflow

```bash
# First time or after Gemfile changes:
nix run github:inscapist/bundix -- -l   # regenerate gemset.nix
nix develop                              # enter dev shell (patches dart binary)
bundle install                           # install gems into vendor/bundle

# Day-to-day:
nix develop
bundle exec jekyll serve
```

---

## Remaining warnings (non-fatal)

- **`bigdecimal` standard library warning** — from `liquid` gem on Ruby 3.3. Add `gem "bigdecimal"` to `Gemfile` to silence it, or ignore it.
- **`Lexer: unexpected token`** — from `bibtex-ruby` parsing certain `.bib` file syntax. Non-fatal; the build completes successfully.
