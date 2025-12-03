{
  description = "Self-rendering quine example using niccup";

  inputs = {
    niccup.url = "github:embedding-shapes/niccup";
    nixpkgs.follows = "niccup/nixpkgs";
  };

  outputs = { nixpkgs, niccup, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    in {
      packages = nixpkgs.lib.genAttrs systems (system: {
        default = import ./build.nix {
          pkgs = import nixpkgs { inherit system; };
          h = niccup.lib;
        };
      });
    };
}
