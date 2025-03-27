{ ... }:

{
  perSystem = { pkgs, ... }: {
    pre-commit.settings.hooks = {
      nixfmt-classic.enable = true;
      deadnix.enable = true;

      prettier = {
        enable = true;
        excludes = [ "flake\\.lock" ];
      };

      yml-to-yaml = {
        enable = true;
        name = ".yml to .yaml";
        entry = let
          yml-to-yaml = pkgs.writeShellApplication {
            name = "yml-to-yaml";
            text = ''
              for file; do
                truncated=''${file%.yml}
                if [ "$truncated" != "$file" ]; then
                  mv "$file" "$truncated".yaml
                fi
              done
            '';
          };
        in "${yml-to-yaml}/bin/yml-to-yaml";
      };
    };
  };
}
