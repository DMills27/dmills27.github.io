{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    bundix = {
      url = "github:inscapist/bundix/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ruby-nix = {
      url = "github:inscapist/ruby-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    bundix,
    ruby-nix
  }: let
    supportedSystems = [ "x86_64-linux" "aarch64-darwin" ];

    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    nixpkgsFor = forAllSystems (system: import nixpkgs {
      inherit system;
      overlays = [ ruby-nix.overlays.ruby ];
    });

    outputsFor = system: let
      pkgs = nixpkgsFor.${system};
      rubyNix = ruby-nix.lib pkgs;
      bundixcli = bundix.packages.${system}.default;

      # LaTeX environment for TikZ → SVG compilation.
      # pdflatex (scheme-basic) compiles .tex → .pdf;
      # dvisvgm (--pdf mode) converts the PDF → SVG.
      texlivePkgs = pkgs.texlive.combine {
        inherit (pkgs.texlive)
          scheme-basic   # core: latex, pdflatex, plain TeX, essential packages
          standalone     # standalone document class — crops output to content
          pgf            # TikZ / PGF + libraries (arrows, shapes, positioning…)
          amsmath        # AMS math environments (\align, \gather, etc.) + latexsym
          amscls         # AMS document classes (amsthm, amsart, etc.)
          dvisvgm        # DVI/PDF → SVG converter (provides the dvisvgm binary)
          ;
      };

      inherit (rubyNix {
        name = "seroperson.gitlab.io";
        # gemset-filtered.nix wraps gemset.nix and strips android platform
        # targets from sass-embedded; those binaries need liblog.so (an
        # Android-only system library) which is unavailable on Linux/NixOS.
        gemset = ./gemset-filtered.nix;
        gemConfig = pkgs.defaultGemConfig;
      })
        env ruby;

      deps = with pkgs; [ env ruby bundixcli texlivePkgs patchelf ];

      bundlecli = pkgs.writeShellApplication {
        name = "bundle";
        runtimeInputs = deps;
        text = ''
          export BUNDLE_PATH=vendor/bundle
          bundle "$@"
        '';
      };
      jekyll = pkgs.writeShellApplication {
        name = "jekyll";
        runtimeInputs = deps;
        text = ''
          if [ $# -eq 0 ]; then
            jekyll build
          else
            jekyll "$@"
          fi
        '';
      };
    in {
      packages = {
        jekyll = jekyll;
        bundle = bundlecli;
        bundix = bundixcli;
        default = jekyll;
      };
      devShell = pkgs.mkShell {
        shellHook = ''
          export BUNDLE_PATH=vendor/bundle
          ${pkgs.lib.optionalString pkgs.stdenv.isLinux ''
            # Patch the dart-sass binary shipped inside sass-embedded for NixOS
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
    };
  in {
    packages = forAllSystems (system: (outputsFor system).packages);
    devShells = forAllSystems (system: { default = (outputsFor system).devShell; });
  };
}
