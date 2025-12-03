{
  description = "Generative SVG art example using niccup";

  inputs = {
    niccup.url = "path:../..";
    nixpkgs.follows = "niccup/nixpkgs";
  };

  outputs = { self, nixpkgs, niccup }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          h = niccup.lib;
        in {
          default = import ./build.nix { inherit pkgs h; };
        });
    };
}
