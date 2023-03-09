{ self, ... }: {
  flake.lib = {
    mkDerivationFor = pkgs: args:
      pkgs.stdenv.mkDerivation ({
        src = self;
        FONTCONFIG_FILE =
          pkgs.makeFontsConf { fontDirectories = [ pkgs.google-fonts ]; };
        ## Do not look this derivation up in substitutes, because it is
        ## never going to be there.
        ## REVIEW: Should change if we introduce Cachix.
        allowSubstitutes = false;
      } // args);

    ## Reads a directory and returns a list of file names.
    readDirAsList = path: builtins.attrNames (builtins.readDir path);

    readDirSubsetAsList = pkgs: path: suffix:
      builtins.map (pkgs.lib.removeSuffix suffix)
      (builtins.filter (pkgs.lib.hasSuffix suffix)
        (self.lib.readDirAsList path));
  };
}
