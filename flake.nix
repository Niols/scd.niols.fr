{
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-22.05;

  outputs = { self, nixpkgs }:
    let pkgs = nixpkgs.legacyPackages.x86_64-linux;

        mkDerivation = args:
          pkgs.stdenv.mkDerivation ({
            src = self;
            FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [
              pkgs.google-fonts ]; };
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
    in

    {
      packages.x86_64-linux.default = self.packages.default;
      packages.x86_64-linux.website = self.packages.website;
      packages.x86_64-linux.test-website = self.packages.test-website;
      devShells.x86_64-linux.default = self.devShell;

      packages.default = self.packages.website;

      devShell = mkDerivation {
        name = "devshell";
        buildInputs = websiteBuildInputs ++ websiteTestInputs;
        buildPhase = "true";
        installPhase = "mkdir $out";
      };

      packages.website = mkDerivation {
        name = "website";
        buildInputs = websiteBuildInputs;
        buildPhase = "make website";
        installPhase = "mkdir -p $out/var && cp -R _build/website $out/var/www";
      };

      packages.test-website = mkDerivation {
        name = "test-website";
        buildInputs = websiteBuildInputs;
        buildPhase = "make test-website";
        installPhase = "mkdir -p $out/var && cp -R _build/website $out/var/www";
      };
    };
}
