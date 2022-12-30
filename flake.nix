{
  inputs.flake-utils.url = github:numtide/flake-utils;

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:

      let pkgs = import nixpkgs { inherit system; };

          mkDerivation = args:
            pkgs.stdenv.mkDerivation ({
              src = self;
              FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [
                pkgs.google-fonts ]; };
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
      in

        {
          packages.default = self.packages.${system}.website;

          devShells.default = mkDerivation {
            name = "devshell";
            buildInputs = websiteBuildInputs ++ websiteTestInputs;
          };

          packages.website = mkDerivation {
            name = "website";
            buildInputs = websiteBuildInputs;
            buildPhase = "make website";
            installPhase = "mkdir $out && cp -R _build/website/* $out/";
          };

          packages.test-website = mkDerivation {
            name = "test-website";
            buildInputs = websiteBuildInputs;
            buildPhase = "make test-website";
            installPhase = "mkdir $out && cp -R _build/website/* $out/";
          };

          packages.tests = mkDerivation {
            name = "tests";
            buildInputs = websiteBuildInputs ++ websiteTestInputs;
            buildPhase = ''
          export HOME=$(mktemp -d)
          make tests website-output=${self.packages.test-website}/
        '';
            installPhase = "mkdir $out && cp -R _build/tests/* $out/";
          };
        }
    );
}
