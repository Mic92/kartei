# kartei

Krebs host database and retiolum VPN modules.

Each top-level directory that is a user name contains that user's
host and user records.  `eval.nix` evaluates the whole set into
`krebs.hosts` / `krebs.users` without depending on the stockholm
tree — the required stockholm library bits are vendored under
`lib/`.

The `retiolum` NixOS/Darwin modules consume the host database
directly and drive [tincr](https://github.com/Mic92/tincr), so no
generated `hosts/` or `etc.hosts` files are committed anymore.

## NixOS

```nix
{
  inputs.kartei.url = "github:Mic92/kartei";

  outputs = { kartei, nixpkgs, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        kartei.nixosModules.retiolum
        kartei.nixosModules.ca   # optional: trust the .r/.w ACME CA
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
`checks.*.eval-hosts`, which forces evaluation of every host entry
and fails on type errors.
