# dmills27.github.io

Personal blog built with [Jekyll](https://jekyllrb.com/) using a customised Tale theme, deployed to GitHub Pages via a Nix-based CI pipeline.

## Local development

The build environment is managed with a [Nix flake](flake.nix), which pins all Ruby gem and system dependencies for reproducibility. You need [Nix](https://nixos.org/download/) with flakes enabled.

```bash
# Enter the dev shell (installs all deps into the Nix store)
nix develop

# Install gems into vendor/bundle
bundle install

# Serve locally at http://127.0.0.1:4000/
bundle exec jekyll serve
```

`jekyll serve` watches for file changes and rebuilds automatically. Changes to `_config.yml` require a manual restart.

### NixOS vs other operating systems

| | NixOS | Linux with Nix (Ubuntu, etc.) | macOS (Apple Silicon) |
|---|---|---|---|
| `nix develop` works | ✓ | ✓ | ✓ |
| dart-sass auto-patched | ✓ via shellHook | ✓ via shellHook | not needed |
| Supported system | `x86_64-linux` | `x86_64-linux` | `aarch64-darwin` |

**Why patching is needed on Linux:** The `sass-embedded` gem bundles a pre-compiled `dart` binary linked against the standard glibc dynamic linker at `/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2`. On NixOS (and on any Linux system using Nix), glibc lives inside the Nix store instead. The `devShell` `shellHook` in `flake.nix` uses `patchelf` to rewrite the binary's interpreter path to the correct Nix store location after `bundle install` downloads it.

**macOS:** No patching is needed. The `aarch64-darwin` sass-embedded variant ships a native Mach-O binary. The `shellHook` patch step is Linux-only and is skipped automatically.

### Updating gems

```bash
# After editing Gemfile, regenerate both lockfiles
bundle install           # updates Gemfile.lock
nix run github:inscapist/bundix -- -l   # regenerates gemset.nix
```

`gemset-filtered.nix` does not need manual updates — it filters `gemset.nix` at build time to remove platform variants (android, musl) that cannot build on standard Linux/macOS.

## Deployment

Pushing to `main` triggers the GitHub Actions workflow (`.github/workflows/pages-deploy.yml`), which:

1. Installs Nix via `DeterminateSystems/nix-installer-action`
2. Runs `nix develop` to enter the reproducible build environment
3. Runs `bundle install && bundle exec jekyll build`
4. Deploys the `_site/` output to GitHub Pages

## Structure

```
_posts/          Blog posts (YYYY-MM-DD-slug.md)
_pages/          Static pages (about, posts index, tags)
_layouts/        HTML layout templates
_includes/       HTML partials (head, nav, footer, etc.)
_sass/           SCSS source files
assets/
  fonts/         Self-hosted web fonts (Alegreya, Source Sans/Code Pro, Merriweather)
  js/            JavaScript (sidenotes, popups, highlight, anime.js, etc.)
_plugins/        Jekyll plugins (BibTeX citations, TikZ diagrams)
_bib/            BibTeX bibliography
_tikz/           TikZ build artefacts (auto-generated, do not edit)
```

## License

MIT — see [LICENSE](LICENSE).
