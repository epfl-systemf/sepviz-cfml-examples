# CFML Example Proofs

This repository contains a Rocq project with example proofs about data structure APIs, developed using separation logic. Running the build process compiles the Coq proofs and records them with Alectryon, producing annotated HTML documentation (**without diagrams**) in the output directory.

## How to build

### Environment Setup

#### Option 1: nix-flakes

`nix build` will generate a shell with proper environment.

If you have direnv installed, run `direnv allow` once and for all. From now on, simply entering the project directory will load the proper environment automatically.

#### Option 2: opam

1. If you have never used opam before, run `opam init`.

2. Create a new switch to contain the relevant packages:

   ```bash
   opam switch create sepviz 4.14.2
   eval $(opam env)
   opam pin add coq 8.20.1
   opam install coq pprint menhir "coq-serapi>=8.10.0+0.7.0"
   ```

3. Run `make cfml` to install the CFML package.

4. Install Alectryon:

   ```bash
   python3 -m pip install alectryon
   ```

### Building

If you're using nix, run `make USE_NIX=true -j`.

If you're using opam, run `make -j`.

The default output directory is `_build`. You can change it by passing a new value to variable `OUT_DIR`, for example, `make OUT_DIR=another-directory -j`.
