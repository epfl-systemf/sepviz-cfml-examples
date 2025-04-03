{
  description = "A nix-flake-based development environment with cfml & tlc";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachSystem
      [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ]
      (
        system:
        let
          coq-overlay = final: prev: {
            coq-tlc = import ./.nix/coq-overlays/tlc {
              inherit (final) lib which;
              inherit (final.coqPackages) mkCoqDerivation coq;
            };
            coq-cfml = import ./.nix/coq-overlays/cfml {
              inherit (final) lib which;
              inherit (final) bash coq-tlc;
              inherit (final.coqPackages) mkCoqDerivation coq;
            };
          };
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ coq-overlay ];
          };
        in
        {
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              python312Full
              python312Packages.alectryon
              coq
              coq-tlc
              coq-cfml
              coqPackages.serapi
              nodejs
            ];
          };
        }
      );
}
