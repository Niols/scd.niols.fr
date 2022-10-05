{
  description = "Flake for building and developing scd.niols.fr";

  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-22.05;

  outputs = { self, nixpkgs }:
    let pkgs = nixpkgs.legacyPackages.x86_64-linux;

        mkDerivation = args:
          pkgs.stdenv.mkDerivation ({
            src = self;
          } // args);

        mkDerivationWithFonts = args:
          mkDerivation ({
            FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [
              self.packages.trebuchetms ]; };
          } // args);

        websiteBuildInputs = [
          pkgs.inkscape
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

      devShell = mkDerivationWithFonts {
        name = "devshell";
        buildInputs = websiteBuildInputs ++ websiteTestInputs;
      };

      packages.website = mkDerivationWithFonts {
        name = "website";
        buildInputs = websiteBuildInputs;
        buildPhase = "make website";
        installPhase = "mkdir -p $out/var && cp -R _build/website $out/var/www";
      };

      packages.test-website = mkDerivationWithFonts {
        name = "test-website";
        buildInputs = websiteBuildInputs;
        buildPhase = "make test-website";
        installPhase = "mkdir -p $out/var && cp -R _build/website $out/var/www";
      };

      packages.trebuchetms = mkDerivation {
          name = "trebuchetms";
          installPhase = "install -m444 -Dt $out/share/fonts assets/fonts/trebuchetms/*.ttf";
        };
    };
}
