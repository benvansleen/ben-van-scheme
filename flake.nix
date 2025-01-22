{
  inputs = {
    nixpkgs.url = "github:nix-ocaml/nix-overlays";
    systems.url = "github:nix-systems/default";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs =
    {
      systems,
      nixpkgs,
      pre-commit-hooks,
      self,
      ...
    }:
    let
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
            packages = with ocamlPackages; [
              ocaml-lsp
              ocamlformat
              utop
            ];

            buildInputs = [
              self.checks.${system}.pre-commit-check.enabledPackages
            ];
            inherit (self.checks.${system}.pre-commit-check) shellHook;
          };
      });

      checks = eachSystem (pkgs: {
        pre-commit-check = pre-commit-hooks.lib.${pkgs.system}.run {
          src = ./.;
          hooks = {
            deadnix.enable = true;
            dune-fmt.enable = true;
            nixfmt-rfc-style.enable = true;
            ripsecrets.enable = true;
          };
        };
      });
    };
}
