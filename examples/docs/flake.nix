{
  description = "NixOS module documentation generator using niccup";

  inputs = {
    niccup.url = "path:../..";
    nixpkgs.follows = "niccup/nixpkgs";
  };

  outputs = { self, nixpkgs, niccup }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          h = niccup.lib;

          modulePath = [ "services" "tailscale" ];
          moduleName = builtins.concatStringsSep "." modulePath;

          eval = import (pkgs.path + "/nixos") {
            configuration = { };
            inherit system;
          };

          options = import ./options.nix {
            inherit (pkgs) lib;
            inherit eval modulePath;
          };

          components = import ./components.nix { inherit h; };

          css = builtins.readFile ./style.css;

          page = h.renderPretty [ "html" { lang = "en"; }
            [ "head"
              [ "meta" { charset = "utf-8"; } ]
              [ "meta" { name = "viewport"; content = "width=device-width, initial-scale=1"; } ]
              [ "title" "${moduleName} - NixOS Options" ]
              [ "style" (h.raw css) ]
            ]
            [ "body"
              (components.header moduleName "NixOS module configuration options")
              [ "main" (map components.optionCard options) ]
              (components.footer "Generated from nixpkgs using niccup")
            ]
          ];

        in {
          default = pkgs.runCommand "docs-${builtins.replaceStrings ["."] ["-"] moduleName}" {} ''
            mkdir -p $out
            cp ${pkgs.writeText "index.html" page} $out/index.html
          '';
        });
    };
}
