{
  description = "kartei — krebs host database and retiolum VPN modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    tincr = {
      url = "github:Mic92/tincr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      tincr,
      nix-darwin,
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
    in
    {
      lib = {
        slib = import ./lib/pure.nix { lib = nixpkgs.lib; };
        krebs = import ./eval.nix { lib = nixpkgs.lib; };
      };

      nixosModules = {
        retiolum =
          { pkgs, ... }:
          {
            imports = [
              tincr.nixosModules.tincr
              ./modules/retiolum/nixos.nix
            ];
            services.tincr.package =
              nixpkgs.lib.mkDefault
                tincr.packages.${pkgs.stdenv.hostPlatform.system}.tincd;
          };
        ca = ./modules/ca;
      };

      darwinModules = {
        tincr = ./modules/tincr/darwin.nix;
        retiolum =
          { pkgs, ... }:
          {
            imports = [
              ./modules/tincr/darwin.nix
              ./modules/retiolum/darwin.nix
            ];
            services.tincr.package =
              nixpkgs.lib.mkDefault
                tincr.packages.${pkgs.stdenv.hostPlatform.system}.tincd;
          };
        ca = ./modules/ca;
      };

      packages = forAllSystems (
        system: nixpkgs.legacyPackages.${system}.callPackage ./packages.nix { }
      );

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          eval-hosts = pkgs.writeText "kartei-host-names" (
            nixpkgs.lib.concatStringsSep "\n" (builtins.attrNames self.lib.krebs.hosts)
          );
        }
        // nixpkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          nixos-example = self.nixosConfigurations.example.config.system.build.toplevel;
        }
      );

      nixosConfigurations.example = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          self.nixosModules.retiolum
          self.nixosModules.ca
          (
            { pkgs, ... }:
            {
              boot.loader.grub.enable = false;
              fileSystems."/" = {
                device = "tmpfs";
                fsType = "tmpfs";
              };
              networking.hostName = "example";
              networking.retiolum = {
                nodename = "hotdog";
                ed25519PrivateKeyFile = "/var/src/secrets/tinc.retiolum.ed25519_key.priv";
              };
              system.stateVersion = "24.05";
            }
          )
        ];
      };

      darwinConfigurations.example = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          self.darwinModules.retiolum
          self.darwinModules.ca
          {
            networking.retiolum = {
              nodename = "hotdog";
              ed25519PrivateKeyFile = "/var/src/secrets/tinc.retiolum.ed25519_key.priv";
            };
            system.stateVersion = 4;
          }
        ];
      };
    };
}
