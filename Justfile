default: build test all-examples build-website

lock:
	nix flake lock

build:
	nix build .#default

build-website:
	nix build .#website

test:
	nix flake check --all-systems

all-examples:
  just example blog
  just example quine
  just example art

example name:
	cd examples/{{name}} && nix build
