{ pkgs, h, modulePath ? [ "services" "tailscale" ] }:

let
  moduleName = builtins.concatStringsSep "." modulePath;

  eval = import (pkgs.path + "/nixos") {
    configuration = { };
    system = pkgs.stdenv.hostPlatform.system;
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

in pkgs.runCommand "docs-${builtins.replaceStrings ["."] ["-"] moduleName}" {} ''
  mkdir -p $out
  cp ${pkgs.writeText "index.html" page} $out/index.html
''
