{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";

  outputs = inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      perSystem = { self', pkgs, ... }:
        let
          mkDerivation = args:
            pkgs.stdenv.mkDerivation ({
              src = self;
              FONTCONFIG_FILE =
                pkgs.makeFontsConf { fontDirectories = [ pkgs.google-fonts ]; };
              ## Do not look this derivation up in substitutes, because it is
              ## never going to be there.
              allowSubstitutes = false;
            } // args);

          websiteBuildInputs = [
            pkgs.inkscape
            pkgs.j2cli
            pkgs.jq
            pkgs.lilypond
            pkgs.sassc
            pkgs.texlive.combined.scheme-full
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
