# NixOS module exposing kartei's host and user definitions.
#
# It declares the subset of krebs.* options that the definitions in this
# repository populate, using the vendored types in ./lib.  This lets kartei
# be evaluated on its own (e.g. in CI) without pulling in stockholm's full
# krebs module tree.
{ lib, ... }:
let
  slib = import ./lib { inherit lib; };
in
{
  imports = [ ./default.nix ];

  options.krebs = {
    hosts = lib.mkOption {
      type = lib.types.attrsOf slib.types.host;
      default = { };
    };
    users = lib.mkOption {
      type = lib.types.attrsOf slib.types.user;
      default = { };
    };
    sitemap = lib.mkOption {
      type = lib.types.attrsOf slib.types.sitemap.entry;
      default = { };
    };
    dns.providers = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };
    dns.search-domain = lib.mkOption {
      type = lib.types.nullOr slib.types.hostname;
      default = null;
    };
    secret.directory = lib.mkOption {
      type = lib.types.str;
      default = "/run/secret";
    };
  };
}
