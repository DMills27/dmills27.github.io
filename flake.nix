{
  description = "Jonathan Lorimer's personal website";

  nixConfig = {
    extra-substituters = ["https://cache.garnix.io"];
    extra-trusted-public-keys = ["cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="];
  };

  inputs = {
    # Nix Inputs
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    
    # Zettelkasten
    forester.url = "sourcehut:~jonsterling/ocaml-forester";
    forester.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self
    , nixpkgs
    , forester
    }:
    let
      forAllSystems = function:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
        ] (system: function rec {
          inherit system;
          pkgs = nixpkgs.legacyPackages.${system};
          supportedGHCVersion = "928";
          compilerVersion = "ghc${supportedGHCVersion}";
          hsPkgs = pkgs.haskell.packages.${compilerVersion}.override {
            overrides = hfinal: hprev: {
              jonathanlorimerdev = hfinal.callCabal2nix "jonathanlorimerdev" ./. {};
            };
          };
        });
    in
    {
      # nix fmt
      formatter = forAllSystems ({pkgs, ...}: pkgs.alejandra);

      # nix develop
      devShell = forAllSystems ({hsPkgs, pkgs, ...}:
        hsPkgs.shellFor {
          packages = p: [
            p.jonathanlorimerdev
          ];
          buildInputs = with pkgs; [
            hsPkgs.haskell-language-server
            haskellPackages.cabal-install
            haskellPackages.ghcid
            haskellPackages.fourmolu
            haskellPackages.cabal-fmt
            nodePackages.serve
            dig
            mprocs
            watchexec
            forester.packages.${system}.default
            texliveFull
            gcc
          ] ++ 
          pkgs.lib.attrsets.attrValues (import ./scripts { 
            inherit pkgs; 
            ghcid = haskellPackages.ghcid;
            cabal-install = haskellPackages.cabal-install;
            forester = forester.packages.${system}.default;
            texlive = texliveFull;
          }); 
        }
      );


      # nix build
      packages = forAllSystems ({hsPkgs, ...}: rec {
        jonathanlorimerdev = hsPkgs.jonathanlorimerdev;
        default = jonathanlorimerdev;
      });

      # nix run
      apps = forAllSystems ({system, ...}: rec {
        build-site = { type = "app"; program = "${self.packages.${system}.jonathanlorimerdev}/bin/build-site"; };
        default = build-site;
      });
    };
}
