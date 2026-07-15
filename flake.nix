{
  description = "kartei - krebs host and user definitions";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    tincr = {
      url = "github:Mic92/tincr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, tincr, nix-darwin }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      lib = forAllSystems (system:
        import ./lib { inherit (nixpkgs.legacyPackages.${system}) lib; });

      nixosModules = {
        default = ./module.nix;
        retiolum = { pkgs, ... }: {
          imports = [
            tincr.nixosModules.tincr
            ./modules/retiolum/nixos.nix
          ];
          services.tincr.package = nixpkgs.lib.mkDefault
            tincr.packages.${pkgs.stdenv.hostPlatform.system}.tincd;
        };
        ca = ./modules/ca;
      };

      darwinModules = {
        tincr = ./modules/tincr/darwin.nix;
        retiolum = { pkgs, ... }: {
          imports = [
            ./modules/tincr/darwin.nix
            ./modules/retiolum/darwin.nix
          ];
          services.tincr.package = nixpkgs.lib.mkDefault
            tincr.packages.${pkgs.stdenv.hostPlatform.system}.tincd;
        };
        ca = ./modules/ca;
      };

      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
        import ./packages.nix { inherit (pkgs) lib runCommand writeText; });

      checks = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          config = (pkgs.lib.evalModules {
            modules = [
              ./module.nix
              { _module.args.lib = pkgs.lib; }
            ];
          }).config;
        in
        {
          eval = pkgs.runCommand "kartei-eval" { } ''
            ${builtins.deepSeq config.krebs "true"}
            touch $out
          '';
        });

      nixosConfigurations.example = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          self.nixosModules.retiolum
          self.nixosModules.ca
          {
            boot.loader.grub.enable = false;
            fileSystems."/" = { device = "tmpfs"; fsType = "tmpfs"; };
            networking.hostName = "example";
            networking.retiolum = {
              nodename = "hotdog";
              ed25519PrivateKeyFile = "/var/src/secrets/tinc.retiolum.ed25519_key.priv";
            };
            system.stateVersion = "24.05";
          }
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
