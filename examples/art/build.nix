{ pkgs, h }:

let
  sierpinski = depth: x: y: size:
    if depth == 0 then
      let
        x1 = x;
        y1 = y;
        x2 = x + size;
        y2 = y;
        x3 = x + size / 2;
        y3 = y - size * 0.866;
      in
        [ "polygon" { points = "${toString x1},${toString y1} ${toString x2},${toString y2} ${toString x3},${toString y3}"; } ]
    else
      let
        half = size / 2;
        height = size * 0.866;
      in [
        (sierpinski (depth - 1) x y half)
        (sierpinski (depth - 1) (x + half) y half)
        (sierpinski (depth - 1) (x + half / 2) (y - height / 2) half)
      ];

  page = h.renderPretty [
    "html" { lang = "en"; }
    [ "head"
      [ "meta" { charset = "utf-8"; } ]
      [ "title" "Sierpinski Triangle" ]
      [ "style" (h.raw ''
        body { margin: 0; display: flex; justify-content: center; align-items: center; min-height: 100vh; background: #1a1a2e; }
        svg { max-width: 90vmin; max-height: 90vmin; }
        polygon { fill: #e94560; }
      '') ]
    ]
    [ "body"
      [ "svg" { viewBox = "0 0 100 90"; xmlns = "http://www.w3.org/2000/svg"; }
        (sierpinski 6 0.0 86.0 100.0)
      ]
    ]
  ];

in pkgs.runCommand "art" {} ''
  mkdir -p $out
  cp ${pkgs.writeText "index.html" page} $out/index.html
''
