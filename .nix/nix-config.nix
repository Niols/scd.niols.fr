{ ... }: {
  flake.nixConfig = {
    extra-trusted-substituters = [ "https://scd-niols-fr.cachix.org/" ];
    extra-trusted-public-keys = [
      "scd-niols-fr.cachix.org-1:7NP/UmPtYppVv3Qq7C6MNLL6jVL8x8bcPB96NckZpDw="
    ];
  };
}
