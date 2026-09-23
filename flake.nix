{
  inputs = {
    treefmt = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    treefmt,
    nixpkgs,
    self,
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {inherit system;};

    treefmtEval = treefmt.lib.evalModule pkgs {
      projectRootFile = "flake.nix";

      programs = {
        qmlformat.enable = true; # .qml
        alejandra.enable = true; # .nix
      };
    };
  in {
    formatter.${system} = treefmtEval.config.build.wrapper;
  };
}
