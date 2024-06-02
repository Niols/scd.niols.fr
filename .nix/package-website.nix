{ self, ... }: {
  perSystem = { self', pkgs, ... }:
    let
      mkDerivation = self.lib.mkDerivationFor pkgs;

      customTexlive = pkgs.texlive.combine {
        inherit (pkgs.texlive)
          scheme-small enumitem ifoddpage tikzpagenodes wrapfig xifthen;
      };

      websiteBuildInputs = [
        pkgs.j2cli
        pkgs.jq
        pkgs.lilypond
        pkgs.sassc
        customTexlive
        pkgs.yq-go
      ];

    in {
      packages.default = self'.packages.website;

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
