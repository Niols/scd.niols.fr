{
  description = "Flake for building and developing scd.niols.fr";

  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-22.05;

  outputs = { self, nixpkgs }:
    let pkgs = nixpkgs.legacyPackages.x86_64-linux; in
    {
      packages.x86_64-linux.default =
        with import nixpkgs { system = "x86_64-linux"; };
        stdenv.mkDerivation {
          name = "scd.niols.fr";
          src = self;

          buildInputs = [
            pkgs.firefox      ## for tests
            pkgs.imagemagick  ## for tests
            pkgs.inkscape
            pkgs.jq
            pkgs.lilypond
            pkgs.sassc
            pkgs.texlive.combined.scheme-full
            pkgs.yq-go
          ];

          FONTCONFIG_FILE = makeFontsConf { fontDirectories = [
            self.packages.x86_64-linux.trebuchetms ]; };

          buildPhase = "make -j website";
          installPhase = "mkdir -p $out/var/www && cp -R _build/website $out/var/www";
        };

      packages.x86_64-linux.trebuchetms =
        with import nixpkgs { system = "x86_64-linux"; };
        stdenv.mkDerivation {
          name = "trebuchetms";
          src = self;

          installPhase = "install -m444 -Dt $out/share/fonts assets/fonts/*.ttf";
        };
    };
}
