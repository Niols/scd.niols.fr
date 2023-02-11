{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";

  outputs = inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.pre-commit-hooks.flakeModule
        ./.nix/lib.nix
        ./.nix/pre-commit-settings.nix
        ./.nix/nix-config.nix
      ];

      systems = [ "x86_64-linux" ];

      perSystem = { self', config, pkgs, ... }:
        let
          mkDerivation = self.lib.mkDerivationFor pkgs;

          websiteBuildInputs = [
            pkgs.inkscape
            pkgs.j2cli
            pkgs.jq
            pkgs.lilypond
            pkgs.sassc
            pkgs.texlive.combined.scheme-basic
            pkgs.xvfb-run
            pkgs.yq-go
          ];

          websiteTestInputs = [
            pkgs.firefox
            pkgs.imagemagick
            #pkgs.python310 ## is implied by:
            pkgs.python310Packages.selenium
          ];

        in {
          packages.default = self'.packages.website;

          devShells.default = mkDerivation {
            name = "devshell";
            buildInputs = websiteBuildInputs ++ websiteTestInputs;
            buildPhase = "true";
            installPhase = "mkdir $out";
            shellHook = config.pre-commit.installationScript;
          };

          packages.website = mkDerivation {
            name = "website";
            buildInputs = websiteBuildInputs;
            buildPhase = "make website";
            installPhase =
              "mkdir -p $out/var && cp -R _build/website $out/var/www";
          };

          packages.test-website = mkDerivation {
            name = "test-website";
            buildInputs = websiteBuildInputs;
            buildPhase = "make test-website";
            installPhase =
              "mkdir -p $out/var && cp -R _build/website $out/var/www";
          };
        };
    };
}
