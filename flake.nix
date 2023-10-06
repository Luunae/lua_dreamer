{
  description = "A Nix-flake-based Shell development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.luvit-nix.url = "github:aiverson/luvit-nix";

  outputs = { self, nixpkgs, luvit-nix }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = nixpkgs.legacyPackages.${system};
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }:
      let system = pkgs.system; in {
        default = pkgs.mkShell {
          packages = [
            luvit-nix.packages.${system}.luvit
            luvit-nix.packages.${system}.luvi
            pkgs.nodePackages.wrangler
            pkgs.gh
          ];
        };
      });
    };
}