{
  projectRootFile = "flake.nix";
  settings.global.excludes = [
    ".envrc"
  ];

  programs = {
    ocamlformat.enable = false;
    nixfmt.enable = true;
    statix.enable = true;
  };

  # List of formatters available at https://github.com/numtide/treefmt-nix?tab=readme-ov-file#supported-programs
}
