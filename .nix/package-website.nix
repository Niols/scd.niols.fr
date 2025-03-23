{ self, ... }: {
  perSystem = { self', inputs', pkgs, ... }:
    let
      mkDerivation = self.lib.mkDerivationFor pkgs;

      websiteBuildInputs =
        (with pkgs; [ j2cli jq sassc texlive.combined.scheme-full yq-go ])
        ++ [ inputs'.nixpkgs2205.legacyPackages.lilypond ];

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
