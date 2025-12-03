{ h }:

let
  formatValue = v:
    if v == null then null
    else if builtins.isBool v then (if v then "true" else "false")
    else if builtins.isString v then ''"${v}"''
    else if builtins.isList v then "[${builtins.concatStringsSep ", " (map formatValue v)}]"
    else builtins.toJSON v;

in {
  header = title: subtitle: [ "header.header"
    [ "h1" title ]
    [ "p" subtitle ]
  ];

  optionCard = opt:
    let
      default = formatValue opt.default;
      example = formatValue opt.example;
    in [ "article.option"
      [ "div.option-header"
        [ "span.option-name" opt.name ]
        [ "span.option-type" opt.type ]
      ]
      (if opt.description != null then [ "p.option-desc" opt.description ] else [])
      (if default != null || example != null
        then [ "dl.option-meta"
          (if default != null then [ [ "dt" "Default:" ] [ "dd" [ "code" default ] ] ] else [])
          (if example != null then [ [ "dt" "Example:" ] [ "dd" [ "code" example ] ] ] else [])
        ]
        else [])
    ];

  footer = text: [ "footer.footer" [ "p" text ] ];
}
