{
  description = "kartei - krebs host and user definitions";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      lib = forAllSystems (system:
        import ./lib { inherit (nixpkgs.legacyPackages.${system}) lib; });

      checks = forAllSystems (system:
        let
          lib = nixpkgs.legacyPackages.${system}.lib;
        in
        {
          eval =
            let
              config = (lib.evalModules {
                modules = [
                  ./default.nix
                  { _module.args.lib = lib; }
                  {
                    options.krebs = lib.mkOption {
                      type = lib.types.submodule {
                        freeformType = lib.types.attrsOf lib.types.anything;
                        options.secret.directory = lib.mkOption {
                          type = lib.types.str;
                          default = "/run/secret";
                        };
                      };
                      default = { };
                    };
                  }
                ];
              }).config;
            in
            nixpkgs.legacyPackages.${system}.runCommand "kartei-eval" { } ''
              ${builtins.deepSeq config.krebs "true"}
              touch $out
            '';
        });
    };
}
