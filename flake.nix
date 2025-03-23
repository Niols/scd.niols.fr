{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs2205.url = "github:nixos/nixpkgs/nixos-22.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.pre-commit-hooks.flakeModule
        ./.nix/lib.nix
        ./.nix/pre-commit-settings.nix
        ./.nix/package-website.nix
        ./.nix/devShell.nix
      ];
      systems = [ "x86_64-linux" ];
    };

  nixConfig = {
    extra-trusted-substituters = [ "https://scd-niols-fr.cachix.org/" ];
    extra-trusted-public-keys = [
      "scd-niols-fr.cachix.org-1:7NP/UmPtYppVv3Qq7C6MNLL6jVL8x8bcPB96NckZpDw="
    ];
  };
}
