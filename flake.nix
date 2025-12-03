{
  description = "niccup: Nix HTML generation library";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.stdenv.mkDerivation {
            pname = "niccup";
            version = "0.1.0";
            src = self;

            dontBuild = true;

            installPhase = ''
              mkdir -p $out/lib/niccup
              cp -r src $out/lib/niccup
              if [ -f README.md ]; then
                cp README.md $out/lib/niccup/README.md
              fi
            '';

            meta = with pkgs.lib; {
              description = "Hiccup-style HTML generation for Nix";
              homepage = "https://github.com/embedding-shapes/niccup";
              license = licenses.mit;
              platforms = platforms.all;
            };
          };

          website = import ./website.nix { inherit pkgs; niccup = self; };
        });

      # Expose the library as a ready-to-use attrset.
      lib = import ./src/lib.nix { };

      checks = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          lib = import ./src/lib.nix { };
          tests = import ./tests.nix;
          runTest = t:
            let
              renderFn = if t.pretty or false then lib.renderPretty else lib.render;
              actual = renderFn t.expr;
              passed = actual == t.expected;
            in
              if passed then true
              else builtins.throw "Test '${t.name}' failed:\n  expected: ${t.expected}\n  actual:   ${actual}";
          allPassed = builtins.all (t: runTest t) tests;
        in {
          default = pkgs.runCommand "niccup-tests" { } ''
            ${if allPassed then "echo 'All tests passed'" else "exit 1"}
            touch $out
          '';
        });

      devShells = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.mkShell {
            packages = [ ];
          };
        });
    };
}
