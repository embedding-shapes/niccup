{ }:
let
  voidTags = [
    "area" "base" "br" "col" "embed" "hr" "img" "input" "link" "meta"
    "source" "track" "wbr"
  ];

  escapeText = s:
    builtins.replaceStrings [ "&" "<" ">" "\"" "'" ] [ "&amp;" "&lt;" "&gt;" "&quot;" "&apos;" ] s;

  escapeAttr = escapeText;

  normalizeClass = v:
    if v == null then [ ]
    else if builtins.isList v then
      builtins.filter (x: x != "") (map (x: if builtins.isString x then x else toString x) v)
    else if builtins.isString v then (if v == "" then [ ] else [ v ])
    else [ toString v ];

  parseTagSpec = spec:
    if ! builtins.isString spec then
      builtins.throw "Tag spec must be a string"
    else
      let
        filterStrings = builtins.filter builtins.isString;
        classParts = filterStrings (builtins.split "\\." spec);
        first = builtins.head classParts;
        classes = builtins.tail classParts;
        tagIdParts = filterStrings (builtins.split "#" first);
        tag = builtins.head tagIdParts;
        idPart = if builtins.length tagIdParts > 1 then builtins.elemAt tagIdParts 1 else null;
      in {
        tag = if tag == "" then builtins.throw "Tag cannot be empty" else tag;
        id = idPart;
        classes = classes;
      };

  mergeAttrs = { shorthand, attrs }:
    let
      attr = if attrs == null then { } else attrs;
      shorthandClasses = normalizeClass shorthand.classes;
      attrClasses = normalizeClass (if attr ? class then attr.class else null);
      combinedClasses = shorthandClasses ++ attrClasses;
      idVal = if attr ? id then attr.id else shorthand.id;
      stripped = builtins.removeAttrs attr [ "class" "id" ];
      withId = if idVal == null then stripped else stripped // { id = idVal; };
    in if combinedClasses == [ ] then withId else withId // { class = combinedClasses; };

  renderAttrs = attrs:
    let
      names = builtins.attrNames attrs;
      renderOne = name:
        let val = attrs.${name}; in
        if val == null then null else
        if builtins.isBool val then
          if val then name + "=\"" + name + "\"" else null
        else if name == "class" && builtins.isList val then
          let classStr = builtins.concatStringsSep " " (map (x: toString x) val);
          in if classStr == "" then null else name + "=\"" + escapeAttr classStr + "\""
        else
          name + "=\"" + escapeAttr (if builtins.isString val then val else toString val) + "\"";
      rendered = builtins.filter (x: x != null) (map renderOne names);
    in if rendered == [ ] then "" else " " + builtins.concatStringsSep " " rendered;

  flattenChildren = items:
    builtins.concatLists (map (child:
      if builtins.isList child && ! (child != [ ] && builtins.isString (builtins.head child)) then child else [ child ]
    ) items);

  indent = depth: builtins.concatStringsSep "" (builtins.genList (_: "  ") depth);

  renderNodeWith = { pretty, depth }: node:
    let
      sep = if pretty then "\n" else "";
      recurse = renderNodeWith { inherit pretty; depth = depth; };
    in
    if builtins.isString node then escapeText node
    else if builtins.isInt node || builtins.isFloat node then escapeText (toString node)
    else if builtins.isAttrs node && node ? __niccup_raw then node.__niccup_raw
    else if builtins.isAttrs node && node ? __niccup_comment then "<!-- " + node.__niccup_comment + " -->"
    else if builtins.isList node then
      if node != [ ] && builtins.isString (builtins.head node) then renderElementWith { inherit pretty depth; } node
      else builtins.concatStringsSep sep (map recurse (flattenChildren node))
    else
      builtins.throw "Unsupported node type";

  renderElementWith = { pretty, depth }: element:
    let
      tagSpec = if element == [ ] then builtins.throw "Element list is empty" else builtins.head element;
      rest = builtins.tail element;
      first = if rest == [ ] then null else builtins.head rest;
      hasAttrs =
        rest != [ ] &&
        builtins.isAttrs first &&
        ! (first ? __niccup_raw || first ? __niccup_comment);
      attrsProvided = if hasAttrs then first else { };
      childrenRaw = if hasAttrs then builtins.tail rest else rest;
      parsed = parseTagSpec tagSpec;
      mergedAttrs = mergeAttrs { shorthand = parsed; attrs = attrsProvided; };
      attrsString = renderAttrs mergedAttrs;
      children = flattenChildren childrenRaw;
      openTag = "<" + parsed.tag + attrsString + ">";
      closeTag = "</" + parsed.tag + ">";
      renderChild = c:
        let rendered = renderNodeWith { inherit pretty; depth = depth + 1; } c;
        in if pretty then indent (depth + 1) + rendered else rendered;
      sep = if pretty then "\n" else "";
      renderedChildren = builtins.concatStringsSep sep (map renderChild children);
      closingIndent = if pretty then indent depth else "";
    in if builtins.elem parsed.tag voidTags then
      openTag
    else if children == [ ] then
      openTag + closeTag
    else if pretty then
      openTag + "\n" + renderedChildren + "\n" + closingIndent + closeTag
    else
      openTag + renderedChildren + closeTag;

  render = expr: renderNodeWith { pretty = false; depth = 0; } expr;

  renderPretty = expr: renderNodeWith { pretty = true; depth = 0; } expr;

  raw = s: { __niccup_raw = s; };

  comment = s: { __niccup_comment = s; };

in {
  inherit render renderPretty raw comment;
}
