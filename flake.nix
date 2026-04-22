{
  description = "A nix-flake-based development environment with cfml & tlc";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    alectryon-src = {
      url = "github:cpitclaudel/alectryon/v2.0.0";
      flake = false;
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      alectryon-src,
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
          overlay = final: prev: {
            tlc = final.callPackage ./.nix/coq-overlays/tlc {
              coqPackages = final.coqPackages_8_20;
            };
            cfml = final.callPackage ./.nix/coq-overlays/cfml {
              tlc = final.tlc;
              coqPackages = final.coqPackages_8_20;
            };
            alectryon = final.python312Packages.buildPythonPackage {
              pname = "alectryon";
              version = "2.0.0";
              src = alectryon-src;
              format = "pyproject";
              nativeBuildInputs = with final.python312Packages; [
                setuptools
              ];
              propagatedBuildInputs = with final.python312Packages; [
                pygments
                docutils
                sphinx
                dominate
                beautifulsoup4
                myst-parser
              ];
              postPatch = ''
                substituteInPlace alectryon/serapi.py \
                  --replace "'pp_depth': 30" "'pp_depth': 100" \
                  --replace "'pp_margin': 55" "'pp_margin': 100"
              '';
              doCheck = false;
            };
            vsrocq-language-server-8_20 = final.rocqPackages.vsrocq-language-server.override {
              coq = final.coqPackages_8_20.coq;
            };
          };
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };
          coqPkgs = pkgs.coqPackages_8_20;
        in
        {
          devShells.default = pkgs.mkShell {
            packages =
              with pkgs;
              [
                alectryon
                vsrocq-language-server-8_20
              ]
              ++ (with coqPkgs; [
                coq
                serapi
                tlc
                cfml
              ]);
          };
        }
      );
}
