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

      nixosModules.default = ./module.nix;

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
    };
}
