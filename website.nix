{ pkgs, niccup }:

let
  h = niccup.lib;
  isLinux = pkgs.stdenv.isLinux;

  # Discover and build examples
  exampleDirs = builtins.attrNames (
    pkgs.lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./examples)
  );

  buildExample = name:
    if name == "docs" then
      if isLinux then import ./examples/docs/build.nix { inherit pkgs h; } else null
    else
      import ./examples/${name}/build.nix { inherit pkgs h; };

  examples = pkgs.lib.filterAttrs (_: v: v != null) (
    builtins.listToAttrs (map (name: { inherit name; value = buildExample name; }) exampleDirs)
  );

  # Wrap example in showcase page (source left, rendered right)
  exampleNames = builtins.sort builtins.lessThan (
    builtins.filter (name: if name == "docs" then isLinux else true) exampleDirs
  );

  exampleMeta = {
    docs = { files = [ "build.nix" "components.nix" "options.nix" ]; };
  };

  showcaseStyles = ''
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { display: flex; flex-direction: column; height: 100vh; font-family: system-ui, sans-serif; background: #1a1a2e; color: #ccc; }
    .topbar { padding: 0.6rem 1rem; background: #151525; border-bottom: 1px solid #333; font-size: 0.85rem; letter-spacing: 0.01em; }
    .topbar a { color: #6ab0ff; text-decoration: none; }
    .topbar a:hover { text-decoration: underline; }
    .topbar .current { color: #fff; text-decoration: underline; text-underline-offset: 3px; }
    .content { display: flex; flex: 1; min-height: 0; }
    .source { flex: 1; overflow: auto; padding: 1rem; border-right: 1px solid #333; }
    .file { margin-top: 1rem; }
    .file:first-child { margin-top: 0; }
    .file h3 { display: inline-block; font-size: 0.7rem; font-weight: 600; color: #aaa; background: #252540; padding: 0.3rem 0.6rem; border-radius: 4px 4px 0 0; margin: 0; }
    .file pre { margin: 0; padding: 0.8rem; font-size: 0.8rem; line-height: 1.4; white-space: pre-wrap; word-break: break-word; background: #12121f; border-radius: 0 4px 4px 4px; }
    .file code { font-family: ui-monospace, monospace; }
    .preview { flex: 1; }
    .preview iframe { width: 100%; height: 100%; border: none; }
  '';

  exampleLink = current: name:
    if name == current
    then [ "span.current" name ]
    else [ "a" { href = "../${name}/"; } name ];

  navBar = current: [ "nav.topbar"
    [ "a" { href = "../../"; } "niccup docs" ]
    " | Examples: "
    (builtins.tail (pkgs.lib.concatMap (name: [ " - " (exampleLink current name) ]) exampleNames))
  ];

  renderFile = name: file: [ "div.file"
    [ "h3" file ]
    [ "pre" [ "code" (builtins.readFile ./examples/${name}/${file}) ] ]
  ];

  wrapExample = name: drv:
    let
      meta = exampleMeta.${name} or {};
      files = meta.files or [ "build.nix" ];
      page = h.render [ "html" { lang = "en"; }
        [ "head"
          [ "meta" { charset = "utf-8"; } ]
          [ "title" "${name} - niccup example" ]
          [ "style" (h.raw showcaseStyles) ]
        ]
        [ "body"
          (navBar name)
          [ "div.content"
            [ "div.source" (map (renderFile name) files) ]
            [ "div.preview" [ "iframe" { src = "demo/"; } ] ]
          ]
        ]
      ];
    in pkgs.runCommand "example-${name}" {} ''
      mkdir -p $out/demo
      cp -r ${drv}/* $out/demo/
      cp ${pkgs.writeText "index.html" page} $out/index.html
    '';

  wrappedExamples = builtins.mapAttrs wrapExample examples;

  # Homepage
  readme = builtins.readFile ./README.md;
  readmeForWeb = builtins.replaceStrings [ "/build.nix)" ] [ "/)" ] readme;
  readmeHtml = pkgs.runCommand "readme-html" { buildInputs = [ pkgs.cmark ]; } ''
    echo ${pkgs.lib.escapeShellArg readmeForWeb} | cmark > $out
  '';

  homeStyles = ''
    :root { --bg: #fafafa; --fg: #222; --code-bg: #1a1a2e; --code-fg: #eee; --accent: #0066cc; }
    @media (prefers-color-scheme: dark) {
      :root { --bg: #1a1a2e; --fg: #eee; --code-bg: #0f0f1a; --accent: #4d9fff; }
    }
    * { box-sizing: border-box; }
    body { max-width: 800px; margin: 0 auto; padding: 2rem 1rem; font-family: system-ui, sans-serif; background: var(--bg); color: var(--fg); line-height: 1.6; }
    h1, h2, h3 { margin-top: 2rem; }
    h1 { border-bottom: 2px solid var(--accent); padding-bottom: 0.5rem; }
    a { color: var(--accent); }
    pre { background: var(--code-bg); color: var(--code-fg); padding: 1rem; border-radius: 8px; overflow-x: auto; }
    code { font-family: ui-monospace, monospace; font-size: 0.9em; }
    :not(pre) > code { background: var(--code-bg); color: var(--code-fg); padding: 0.2em 0.4em; border-radius: 4px; }
  '';

  beforeContent = h.renderPretty [
    "html" { lang = "en"; }
    [ "head"
      [ "meta" { charset = "utf-8"; } ]
      [ "meta" { name = "viewport"; content = "width=device-width, initial-scale=1"; } ]
      [ "title" "niccup - Hiccup-style HTML generation for Nix" ]
      [ "style" (h.raw homeStyles) ]
    ]
    [ "body"
      [ "main" ]
    ]
  ];

  afterContent = h.renderPretty [
    "footer"
    [ "hr" ]
    [ "p" [ "a" { href = "https://github.com/embedding-shapes/niccup"; } "View on GitHub" ] ]
  ];

  closingTags = "</main>\n  </body>\n</html>";
  stripped = builtins.replaceStrings [closingTags] [""] beforeContent;

  copyExamples = pkgs.lib.concatStringsSep "\n" (
    pkgs.lib.mapAttrsToList (name: drv: "cp -r ${drv}/* $out/examples/${name}/") wrappedExamples
  );

in pkgs.runCommand "niccup-website" {} ''
  mkdir -p $out/examples/{${pkgs.lib.concatStringsSep "," (builtins.attrNames examples)}}

  {
    cat <<'BEFORE'
${stripped}
BEFORE
    cat ${readmeHtml}
    cat <<'AFTER'
    </main>
${afterContent}
  </body>
</html>
AFTER
  } > $out/index.html

  ${copyExamples}
''
