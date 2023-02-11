{ self, ... }: {
  flake.lib.mkDerivationFor = pkgs: args:
    pkgs.stdenv.mkDerivation ({
      src = self;
      FONTCONFIG_FILE =
        pkgs.makeFontsConf { fontDirectories = [ pkgs.google-fonts ]; };
      ## Do not look this derivation up in substitutes, because it is
      ## never going to be there.
      ## REVIEW: Should change if we introduce Cachix.
      allowSubstitutes = false;
    } // args);
}
