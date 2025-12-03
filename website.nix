{ pkgs, niccup }:
let
  h = niccup.lib;
  readme = builtins.readFile ./README.md;

  # Convert markdown to HTML using cmark (CommonMark reference implementation)
  readmeHtml = pkgs.runCommand "readme-html" {
    buildInputs = [ pkgs.cmark ];
  } ''
    echo ${pkgs.lib.escapeShellArg readme} | cmark > $out
  '';

  styles = ''
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

  repoUrl = "https://github.com/embedding-shapes/niccup";

  # Build the page structure using niccup, with a placeholder for content
  beforeContent = h.renderPretty [
    "html" { lang = "en"; }
    [ "head"
      [ "meta" { charset = "utf-8"; } ]
      [ "meta" { name = "viewport"; content = "width=device-width, initial-scale=1"; } ]
      [ "title" "niccup - Hiccup-style HTML generation for Nix" ]
      [ "style" (h.raw styles) ]
    ]
    [ "body"
      [ "main" ]
    ]
  ];

  afterContent = h.renderPretty [
    "footer"
    [ "hr" ]
    [ "p" [ "a" { href = repoUrl; } "View on GitHub" ] ]
  ];

  # Remove the closing tags that we'll add back after the content
  closingTags = "</main>\n  </body>\n</html>";
  stripped = builtins.replaceStrings [closingTags] [""] beforeContent;

in pkgs.runCommand "niccup-website" { } ''
  mkdir -p $out
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
''
