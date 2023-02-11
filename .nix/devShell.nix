{ self, ... }: {
  perSystem = { self', config, pkgs, ... }:
    let
      mkDerivation = self.lib.mkDerivationFor pkgs;

      websiteBuildInputs = self'.packages.website.buildInputs;

      websiteTestInputs = [
        pkgs.firefox
        pkgs.imagemagick
        #pkgs.python310 ## is implied by:
        pkgs.python310Packages.selenium
      ];

    in {
      devShells.default = mkDerivation {
        name = "devshell";
        buildInputs = websiteBuildInputs ++ websiteTestInputs;
        buildPhase = "true";
        installPhase = "mkdir $out";
        shellHook = config.pre-commit.installationScript;
      };
    };
}
