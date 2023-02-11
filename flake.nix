{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";

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
