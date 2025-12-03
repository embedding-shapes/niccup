{
  description = "Blog example using niccup";

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

          posts = [
            { slug = "hello-world"; title = "Hello World"; body = "Welcome to my blog!"; }
            { slug = "second-post"; title = "Second Post"; body = "Another great article."; }
          ];

          header = [ "header" [ "a" { href = "index.html"; } "My Blog" ] ];

          footer = [ "footer" [ "p" "Built with niccup" ] ];

          nav = posts: [ "nav"
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
              (nav posts)
              footer
            ]
          ];

          indexHtml = pkgs.writeText "index.html" (renderPage { title = "My Blog"; });

          postPages = map (post:
            pkgs.writeText "${post.slug}.html" (renderPage { inherit (post) title body; })
          ) posts;

        in {
          default = pkgs.runCommand "blog" {} ''
            mkdir -p $out
            cp ${indexHtml} $out/index.html
            ${builtins.concatStringsSep "\n" (map (post:
              "cp ${pkgs.writeText "${post.slug}.html" (renderPage { inherit (post) title body; })} $out/${post.slug}.html"
            ) posts)}
          '';
        });
    };
}
