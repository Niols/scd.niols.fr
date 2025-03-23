{ ... }: {
  perSystem = { ... }: {
    pre-commit.settings.hooks = {
      nixfmt-classic.enable = true;
      deadnix.enable = true;
      prettier.enable = true;
    };
  };
}
