# niccup

Hiccup-style HTML generation for Nix. Describe HTML as Nix lists/attrsets, render to strings. Heavily inspired by [hiccup](https://github.com/weavejester/hiccup) (Fast library for rendering HTML in Clojure) by [@weavejester](https://github.com/weavejester)

[View on GitHub](https://github.com/embedding-shapes/niccup) | [Website/Docs](https://embedding-shapes.github.io/niccup/) | [Introduction Blog Post](https://embedding-shapes.github.io/introducing-niccup/)

## Installation

Flakes:
```nix
inputs.niccup.url = "github:embedding-shapes/niccup";
# use inputs.niccup.lib
```

Non-flakes:
```nix
let
  niccup = builtins.fetchTarball "https://github.com/embedding-shapes/niccup/archive/master.tar.gz";
  h = import (niccup + "/src/lib.nix") { };
in h.render [ "p" "Hello" ]
```

## Security Note

This library assumes trusted inputs. Like server-side templates, the expressions should be developer-authored code, not user-generated content. Do not pass untrusted input directly to `raw` or `comment`, or do so at your own risk. Don't say you weren't warned tho.

## Examples

```nix
let h = inputs.niccup.lib; in
h.render [
  "div#main.container"
  { lang = "en"; class = [ "app" "dark" ]; }
  [ "h1" "Hello from Nix" ]
  [ "p" "Hiccup-style HTML in Nix." ]
  (h.comment "List example")
  [ "ul" (map (x: [ "li.item" x ]) [ "one" "two" "three" ]) ]
]
```

Write to file (use nixpkgs `writeText`):
```nix
{ pkgs, inputs, ... }:
pkgs.writeText "index.html" (inputs.niccup.lib.render [ "p" "Hello" ])
```

Some more involved examples:

- [art](examples/art/build.nix) - Generative SVG (Sierpinski triangle)
- [blog](examples/blog/build.nix) - Multi-page blog with navigation
- [docs](examples/docs/build.nix) - NixOS module documentation generator
- [quine](examples/quine/build.nix) - Self-rendering page

The website for niccup is generated dynamically with niccup too, the [whole source](https://github.com/embedding-shapes/niccup/blob/master/website.nix) is ~120 lines of Nix as well

## Data Model

**Element**: `[ tag-spec attrs? children... ]`

**Tag spec**: string with optional CSS shorthand: `"div#id.class1.class2"`. ID must precede classes.

**Attributes** (optional attrset, second position):
- Merged with shorthand; classes combine (shorthand first), ID from map overwrites shorthand.
- `class`: string or list of strings.
- Boolean `true` renders as `attr="attr"`; `false`/`null` omits the attribute.

**Children**:
- Strings/numbers: escaped, numbers via `toString`.
- Elements: nested `[ tag ... ]` lists.
- Lists: flattened one level (enables `map` patterns).
- `raw` nodes: unescaped HTML.
- `comment` nodes: `<!-- ... -->`.

**Void tags** (`img`, `br`, `hr`, `input`, `meta`, `link`, `area`, `base`, `col`, `embed`, `source`, `track`, `wbr`): no closing tag.

## API

- `render : expr -> string` - Render to minified HTML string.
- `renderPretty : expr -> string` - Render to indented, human-readable HTML.
- `raw : string -> node` - Mark content as unescaped HTML.
- `comment : string -> node` - Emit HTML comment.

Exported as `lib` from the flake.

## Development

```
just build # checks syntax, builds the library

just test # runs a bunch of tests

just build-website # builds the project website to result/

just all-examples # builds all of the examples, currently `blog`, `quine` and `art`

just example blog # builds only the `blog` example
```

## License

MIT 2025 - [@embedding-shapes](https://github.com/embedding-shapes)
