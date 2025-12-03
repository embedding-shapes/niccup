let
  lib = import ./src/lib.nix { };
  raw = lib.raw;
  comment = lib.comment;
in
# Test cases: list of { name, expr, expected }
# expr is evaluated with lib.render, expected is the HTML string
[
  {
    name = "simple paragraph";
    expr = [ "p" "Hello world" ];
    expected = "<p>Hello world</p>";
  }
  {
    name = "escape text";
    expr = [ "p" "<x & y>" ];
    expected = "<p>&lt;x &amp; y&gt;</p>";
  }
  {
    name = "escape attributes";
    expr = [ "a" { href = "a&b\"c"; } "link" ];
    expected = "<a href=\"a&amp;b&quot;c\">link</a>";
  }
  {
    name = "boolean attrs";
    expr = [ "input" { type = "checkbox"; checked = true; disabled = false; } ];
    expected = "<input checked=\"checked\" type=\"checkbox\">";
  }
  {
    name = "class merging order";
    expr = [ "div.one" { class = [ "two" "three" ]; } "x" ];
    expected = "<div class=\"one two three\">x</div>";
  }
  {
    name = "id override";
    expr = [ "div#shorthand" { id = "map"; } "x" ];
    expected = "<div id=\"map\">x</div>";
  }
  {
    name = "class list normalization";
    expr = [ "div" { class = [ "" "a" null "b" ]; } ];
    expected = "<div class=\"a b\"></div>";
  }
  {
    name = "void tag";
    expr = [ "br" ];
    expected = "<br>";
  }
  {
    name = "raw passthrough";
    expr = [ "p" (raw "<span>ok</span>") ];
    expected = "<p><span>ok</span></p>";
  }
  {
    name = "comment node";
    expr = [ "div" (comment "note") "x" ];
    expected = "<div><!-- note -->x</div>";
  }
  {
    name = "one level flatten";
    expr = [ "ul" (map (x: [ "li" x ]) [ "a" "b" ]) ];
    expected = "<ul><li>a</li><li>b</li></ul>";
  }
  {
    name = "numbers coerced";
    expr = [ "p" 42 ];
    expected = "<p>42</p>";
  }
  {
    name = "nested list keeps depth";
    expr = [ "div" [ [ "span" "a" ] [ "span" "b" ] ] ];
    expected = "<div><span>a</span><span>b</span></div>";
  }
  # --- Additional tests for better coverage ---
  {
    name = "multiple shorthand classes";
    expr = [ "div.a.b.c" "x" ];
    expected = "<div class=\"a b c\">x</div>";
  }
  {
    name = "combined id and multiple classes";
    expr = [ "div#foo.bar.baz" "x" ];
    expected = "<div class=\"bar baz\" id=\"foo\">x</div>";
  }
  {
    name = "multiple text children";
    expr = [ "p" "Hello " "world" ];
    expected = "<p>Hello world</p>";
  }
  {
    name = "single quote in attributes";
    expr = [ "div" { title = "it's"; } "x" ];
    expected = "<div title=\"it&apos;s\">x</div>";
  }
  {
    name = "null attribute value omitted";
    expr = [ "a" { href = null; class = "link"; } "click" ];
    expected = "<a class=\"link\">click</a>";
  }
  {
    name = "empty element with attributes";
    expr = [ "div" { id = "container"; } ];
    expected = "<div id=\"container\"></div>";
  }
  {
    name = "void tag img";
    expr = [ "img" { src = "pic.png"; alt = "A picture"; } ];
    expected = "<img alt=\"A picture\" src=\"pic.png\">";
  }
  {
    name = "void tag meta";
    expr = [ "meta" { charset = "utf-8"; } ];
    expected = "<meta charset=\"utf-8\">";
  }
  {
    name = "void tag link";
    expr = [ "link" { rel = "stylesheet"; href = "style.css"; } ];
    expected = "<link href=\"style.css\" rel=\"stylesheet\">";
  }
  {
    name = "void tag hr";
    expr = [ "hr" ];
    expected = "<hr>";
  }
  {
    name = "deeply nested elements";
    expr = [ "div" [ "section" [ "article" [ "p" [ "span" "deep" ] ] ] ] ];
    expected = "<div><section><article><p><span>deep</span></p></article></section></div>";
  }
  {
    name = "numeric attribute value";
    expr = [ "input" { type = "text"; tabindex = 1; maxlength = 100; } ];
    expected = "<input maxlength=\"100\" tabindex=\"1\" type=\"text\">";
  }
  {
    name = "empty string content";
    expr = [ "p" "" ];
    expected = "<p></p>";
  }
  # --- renderPretty tests ---
  {
    name = "pretty: simple nested";
    pretty = true;
    expr = [ "div" [ "p" "Hello" ] ];
    expected = ''
<div>
  <p>
    Hello
  </p>
</div>'';
  }
  {
    name = "pretty: multiple children";
    pretty = true;
    expr = [ "ul" [ "li" "one" ] [ "li" "two" ] ];
    expected = ''
<ul>
  <li>
    one
  </li>
  <li>
    two
  </li>
</ul>'';
  }
  {
    name = "pretty: deeply nested";
    pretty = true;
    expr = [ "div" [ "section" [ "p" "deep" ] ] ];
    expected = ''
<div>
  <section>
    <p>
      deep
    </p>
  </section>
</div>'';
  }
  {
    name = "pretty: empty element";
    pretty = true;
    expr = [ "div" { id = "empty"; } ];
    expected = "<div id=\"empty\"></div>";
  }
  {
    name = "pretty: void tag";
    pretty = true;
    expr = [ "div" [ "br" ] [ "hr" ] ];
    expected = ''
<div>
  <br>
  <hr>
</div>'';
  }
  {
    name = "pretty: with attributes";
    pretty = true;
    expr = [ "div.container" { id = "main"; } [ "p.text" "content" ] ];
    expected = ''
<div class="container" id="main">
  <p class="text">
    content
  </p>
</div>'';
  }
  {
    name = "pretty: map flattening";
    pretty = true;
    expr = [ "ul" (map (x: [ "li" x ]) [ "a" "b" ]) ];
    expected = ''
<ul>
  <li>
    a
  </li>
  <li>
    b
  </li>
</ul>'';
  }
  {
    name = "pretty: raw content";
    pretty = true;
    expr = [ "div" (raw "<span>raw</span>") ];
    expected = ''
<div>
  <span>raw</span>
</div>'';
  }
  {
    name = "pretty: comment";
    pretty = true;
    expr = [ "div" (comment "a comment") [ "p" "text" ] ];
    expected = ''
<div>
  <!-- a comment -->
  <p>
    text
  </p>
</div>'';
  }
  {
    name = "pretty: number child";
    pretty = true;
    expr = [ "span" 42 ];
    expected = ''
<span>
  42
</span>'';
  }
]
