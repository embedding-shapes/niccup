{ lib, eval, modulePath }:

let
  allAttrs = lib.attrByPath modulePath {} eval.options;

  isOption = v: builtins.isAttrs v && v._type or null == "option";

  optionNames = builtins.filter (n: isOption allAttrs.${n}) (builtins.attrNames allAttrs);

  extractValue = attr:
    if builtins.isAttrs attr && attr ? value then attr.value
    else attr;

  simplifyValue = v:
    if v == null then null
    else if builtins.isBool v || builtins.isInt v || builtins.isFloat v then v
    else if builtins.isString v then v
    else if builtins.isList v then
      let simplified = map simplifyValue v;
      in if builtins.all (x: x != null) simplified then simplified else null
    else null;

  getInfo = name:
    let opt = allAttrs.${name}; in {
      inherit name;
      description = opt.description.text or opt.description or null;
      type = opt.type.name or opt.type.description or "unknown";
      default = if opt ? default then simplifyValue (extractValue opt.default) else null;
      example = if opt ? example then simplifyValue (extractValue opt.example) else null;
    };

in map getInfo optionNames
