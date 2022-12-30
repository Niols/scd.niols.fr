{
  inputs.flake-utils.url = github:numtide/flake-utils;

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:

      let pkgs = import nixpkgs { inherit system; };

          ## Reads a directory and returns a list of file names.
          readDir = path: with builtins; attrNames (readDir path);
          readDirSubset = path: suffix: with builtins; with pkgs.lib;
            map (removeSuffix suffix) (filter (hasSuffix suffix) (readDir path));

          mkDerivation = name: args:
            pkgs.stdenv.mkDerivation ({
              src = self;
              inherit name;

              FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [
                pkgs.google-fonts ]; };

              buildInputs = with pkgs; [
                inkscape j2cli jq lilypond sassc
                texlive.combined.scheme-full xvfb-run yq-go

                ## Only used for tests:
                firefox imagemagick python310Packages.selenium #implies python310
              ];
            } // args);
      in

        {
          packages.default = self.packages.${system}.website;

          packages.website = mkDerivation "website" {
            buildPhase = "make website";
            installPhase = "mkdir $out && cp -R _build/website/* $out/";
          };

          packages.test-website = mkDerivation "test-website" {
            buildPhase = "make test-website";
            installPhase = "mkdir $out && cp -R _build/website/* $out/";
          };

          packages.tests = mkDerivation "tests" {
            buildPhase = ''
              export HOME=$(mktemp -d)
              make tests website-output=${self.packages.test-website}/
            '';
            installPhase = "mkdir $out && cp -R _build/tests/* $out/";
          };
        }
    );
}
