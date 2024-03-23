{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };

    # TABLE = [
    #   0 7 0  0 0 0  0 0 0
    #   0 0 0  0 0 0  8 0 0
    #   2 0 6  0 9 1  4 0 0

    #   0 0 0  9 0 0  0 6 0
    #   0 1 5  0 0 7  0 4 0
    #   0 8 0  0 5 0  0 9 0

    #   0 3 0  4 0 0  0 0 0
    #   0 0 8  0 6 0  7 0 0
    #   7 0 0  0 3 0  0 1 9
    # ];

    TABLE = [
      9 4 0  0 0 8  0 2 0
      0 0 2  1 0 0  0 0 9
      0 0 0  0 0 3  6 8 0

      0 0 0  0 4 0  0 0 3
      0 5 1  2 0 0  0 0 7
      0 0 3  8 0 6  0 0 0

      7 6 0  0 9 0  5 0 0
      2 0 0  0 7 0  0 1 0
      0 9 0  0 0 0  4 0 0
    ];

    html = import ./sudoku-html.nix {
      table = TABLE;
      solution = import ./sudoku.nix { tableToSolve = TABLE; lib = pkgs.lib; };
    };

    htmlFile = builtins.toFile "solution.html" html;
  in {
    apps.${system}.default = let
      bin = pkgs.writeShellApplication {
        name = "solve";
        runtimeInputs = [ pkgs.falkon ];
        text = "falkon ${htmlFile}";
      };
    in {
      type = "app";
      program = "${bin}/bin/solve";
    };
  };
}
