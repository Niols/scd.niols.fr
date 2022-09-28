{
  description = "Flake for building and developing scd.niols.fr";

  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-22.05;

  outputs = { self, nixpkgs }:
    let pkgs = nixpkgs.legacyPackages.x86_64-linux;

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
          pkgs.chromium
          pkgs.imagemagick
        ];
    in

    {
      packages.x86_64-linux.default = self.packages.x86_64-linux.website;

      devShells.x86_64-linux.default = pkgs.stdenv.mkDerivation {
        name = "devshell";
        src = self;

        buildInputs = websiteBuildInputs ++ websiteTestInputs;

        FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [
          self.packages.x86_64-linux.trebuchetms ]; };
      };

      packages.x86_64-linux.website = pkgs.stdenv.mkDerivation {
        name = "website";
        src = self;

        buildInputs = websiteBuildInputs;

        FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [
          self.packages.x86_64-linux.trebuchetms ]; };

        buildPhase = "make website";
        installPhase = "mkdir -p $out/var && cp -R _build/website $out/var/www";
      };

      packages.x86_64-linux.test-website = pkgs.stdenv.mkDerivation {
        name = "test-website";
        src = self;

        buildInputs = websiteBuildInputs;

        FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [
          self.packages.x86_64-linux.trebuchetms ]; };

        buildPhase = "make test-website";
        installPhase = "mkdir -p $out/var && cp -R _build/website $out/var/www";
      };

      packages.x86_64-linux.trebuchetms = pkgs.stdenv.mkDerivation {
          name = "trebuchetms";
          src = self;

          installPhase = "install -m444 -Dt $out/share/fonts assets/fonts/*.ttf";
        };
    };
}
