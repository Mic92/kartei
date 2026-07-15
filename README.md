# kartei

Krebs host database and retiolum VPN modules.

Each top-level directory that is a user name contains that user's
host and user records.  `module.nix` declares the `krebs.*` options
they populate so the set can be evaluated without stockholm.

The `retiolum` NixOS/Darwin modules consume the host database
directly and drive [tincr](https://github.com/Mic92/tincr), so no
generated `hosts/` or `etc.hosts` files need to be committed.

## NixOS

```nix
{
  inputs.kartei.url = "github:krebs/kartei";

  outputs = { kartei, nixpkgs, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        kartei.nixosModules.retiolum
        kartei.nixosModules.ca      # optional: trust the .r/.w ACME CA
        # kartei.nixosModules.default  # bare krebs.{hosts,users} data
        {
          # nodename defaults to networking.hostName; ipv4/ipv6 are
          # looked up in kartei by nodename.
          networking.retiolum.ed25519PrivateKeyFile =
            "/var/src/secrets/tinc.retiolum.ed25519_key.priv";
        }
      ];
    };
  };
}
```

Name resolution for `.r` uses tincr's built-in DNS stub via
systemd-resolved.  A static `/etc/hosts` copy is also installed by
default (`networking.retiolum.extraHosts`) so the mesh stays
resolvable while tincd is restarting.

## NixOS without flakes

```nix
{
  imports = let
    kartei = builtins.fetchTarball "https://github.com/krebs/kartei/archive/master.tar.gz";
  in [
    "${kartei}/modules/retiolum"
    "${kartei}/modules/ca"
  ];
  networking.retiolum.ed25519PrivateKeyFile = "/var/src/secrets/tinc.retiolum.ed25519_key.priv";
}
```

The module fetches tincr from the revision pinned in `flake.lock`.

## nix-darwin

```nix
darwinConfigurations.mymac = darwin.lib.darwinSystem {
  modules = [
    kartei.darwinModules.retiolum
    kartei.darwinModules.ca
    {
      networking.retiolum.nodename = "mymac";
      networking.retiolum.ed25519PrivateKeyFile =
        "/var/src/secrets/tinc.retiolum.ed25519_key.priv";
    }
  ];
};
```

## Artefacts

For consumers that still want plain files:

```
nix build .#retiolum-hosts     # /etc/tinc/retiolum/hosts directory
nix build .#etc-hosts          # /etc/hosts fragment (v4+v6)
nix build .#etc-hosts-v6only
nix build .#wiregrill-json
```

## Adding a host

Edit your directory's `default.nix` (or copy `template/`).  CI runs
`checks.*.eval`, which forces evaluation of every host entry and
fails on type errors.
