{ pkgs, h }:

let
  posts = [
    { slug = "hello-world"; title = "Hello World"; body = "Welcome to my blog!"; }
    { slug = "second-post"; title = "Second Post"; body = "Another great article."; }
  ];

  header = [ "header" [ "a" { href = "index.html"; } "My Blog" ] ];
  footer = [ "footer" [ "p" "Built with niccup" ] ];

  nav = [ "nav"
    [ "h2" "Posts" ]
    [ "ul" (map (p: [ "li" [ "a" { href = "${p.slug}.html"; } p.title ] ]) posts) ]
  ];

  renderPage = { title, body ? null }: h.renderPretty [
    "html" { lang = "en"; }
    [ "head"
      [ "meta" { charset = "utf-8"; } ]
      [ "title" title ]
    ]
    [ "body"
      header
      (if body != null then [ "main" [ "h1" title ] (h.raw body) ] else [])
      nav
      footer
    ]
  ];

in pkgs.runCommand "blog" {} ''
  mkdir -p $out
  cp ${pkgs.writeText "index.html" (renderPage { title = "My Blog"; })} $out/index.html
  ${builtins.concatStringsSep "\n" (map (post:
    "cp ${pkgs.writeText "${post.slug}.html" (renderPage { inherit (post) title body; })} $out/${post.slug}.html"
  ) posts)}
''
