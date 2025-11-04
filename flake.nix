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
            coq-tlc = final.callPackage ./.nix/coq-overlays/tlc {
              coqPackages = final.coqPackages;
            };
            coq-cfml = final.callPackage ./.nix/coq-overlays/cfml {
              coq-tlc = final.coq-tlc;
              coqPackages = final.coqPackages;
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
