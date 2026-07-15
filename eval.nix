# Standalone evaluator for the kartei host database.
#
# Stockholm evaluates kartei inside its full krebs/3modules set. Here
# we only need `krebs.hosts`/`users`, so provide the minimal option
# skeleton the per-user files reference and return the evaluated
# `krebs` attrset.
{ lib }:
let
  slib = import ./lib/pure.nix { inherit lib; };

  eval = lib.evalModules {
    modules = [
      {
        options.krebs = {
          hosts = lib.mkOption {
            type = lib.types.attrsOf slib.types.host;
            default = { };
          };
          users = lib.mkOption {
            type = lib.types.attrsOf slib.types.user;
            default = { };
          };
          dns.providers = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
          };
          sitemap = lib.mkOption {
            type = lib.types.attrsOf slib.types.sitemap.entry;
            default = { };
          };
          # A few host entries derive ssh privkey paths from this;
          # the retiolum module never reads those.
          secret.directory = lib.mkOption {
            type = lib.types.str;
            default = "/var/src/secrets";
          };
        };
        config.krebs.users.krebs = {
          home = "/krebs";
          mail = "spam@krebsco.de";
        };
      }
      ./default.nix
    ];
  };
in
eval.config.krebs
