{
  inputs = {
    nixpkgs.url = "github:nix-ocaml/nix-overlays";
    systems.url = "github:nix-systems/default";

    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      systems,
      nixpkgs,
      pre-commit-hooks,
      treefmt-nix,
      self,
      ...
    }:
    let
      treefmtEval = pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      eachSystem =
        f:
        nixpkgs.lib.genAttrs (import systems) (
          system:
          f (
            nixpkgs.legacyPackages.${system}.extend (
              _prev: final: {
                ocamlPackages = final.ocaml-ng.ocamlPackages_latest;
              }
            )
          )
        );
    in
    {
      packages = eachSystem (
        pkgs: with pkgs; {
          default = ocamlPackages.buildDunePackage {
            pname = "ben_van_scheme";
            version = "0.1.0";
            duneVersion = "3";
            src = self.outPath;

            buildInputs = with ocamlPackages; [
              angstrom
              base
            ];
          };
        }
      );

      devShells = eachSystem (pkgs: {
        default =
          with pkgs;
          mkShell {
            inputsFrom = [
              self.packages.${system}.default
            ];
            packages = with ocamlPackages;
              [
                ocaml-lsp
                ocamlformat
                utop
              ];

            buildInputs = [
              self.checks.${system}.pre-commit-check.enabledPackages
            ];
            shellHook = self.checks.${system}.pre-commit-check.shellHook;
          };
      });

      formatter = eachSystem (pkgs: (treefmtEval pkgs).config.build.wrapper);
      checks = eachSystem (
        pkgs:
        {
          pre-commit-check = pre-commit-hooks.lib.${pkgs.system}.run {
            src = ./.;
            hooks = {
              deadnix.enable = true;
              ripsecrets.enable = true;
              nix-fmt = {
                enable = true;
                name = "nix fmt";
                entry = "${pkgs.nix}/bin/nix fmt";
                language = "system";
                stages = [ "pre-commit" ];
              };
            };
          };
      }
      );
    };
}
