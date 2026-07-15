# Artefacts the old retiolum repo used to commit, for non-NixOS
# consumers. The NixOS module reads the same data straight from Nix.
{
  lib,
  runCommand,
  writeText,
}:
let
  data = import ./modules/retiolum/hosts.nix { inherit lib; };
  krebs = data.krebs;

  # Some hosts declare a wiregrill net without a wireguard pubkey; the
  # submodule then throws on access instead of being null.
  wiregrill = lib.filterAttrs (
    _: h:
    h.nets ? wiregrill
    && (
      let
        r = builtins.tryEval (h.nets.wiregrill.wireguard.pubkey or null);
      in
      r.success && r.value != null
    )
  ) krebs.hosts;
  wiregrillJson = builtins.toJSON (
    lib.mapAttrs (_: h: {
      pubkey = h.nets.wiregrill.wireguard.pubkey;
      addrs = h.nets.wiregrill.addrs;
      subnets = h.nets.wiregrill.wireguard.subnets;
      endpoint = h.nets.wiregrill.via.addrs or null;
    }) wiregrill
  );
in
{
  retiolum-hosts =
    runCommand "retiolum-hosts"
      {
        passAsFile = [ "script" ];
        script = lib.concatStrings (
          lib.mapAttrsToList (name: text: ''
            cat > "$out/${name}" <<'EOF'
            ${text}
            EOF
          '') data.tincHosts
        );
      }
      ''
        mkdir -p $out
        bash "$scriptPath"
      '';

  etc-hosts = writeText "etc.hosts" data.extraHosts.v4v6;
  etc-hosts-v6only = writeText "etc.hosts-v6only" data.extraHosts.v6only;
  wiregrill-json = writeText "wiregrill.json" wiregrillJson;
}
