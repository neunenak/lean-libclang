{
  description = "Lean 4 bindings to libclang";

  inputs = {
    lean4-nix.url = "github:lenianiva/lean4-nix";
    nixpkgs.follows = "lean4-nix/nixpkgs";
  };

  outputs = { self, nixpkgs, lean4-nix }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems f;
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ (lean4-nix.readToolchainFile ./lean-toolchain) ];
          };
          libclang = pkgs.llvmPackages.libclang;
        in {
          default = pkgs.stdenv.mkDerivation {
            pname = "lean-libclang";
            version = "0.1.0";
            src = self;
            nativeBuildInputs = [
              pkgs.lean.lean-all
              pkgs.llvmPackages.clang
            ];
            buildInputs = [
              libclang.dev
              libclang.lib
            ];
            env = {
              LEAN_CC = "${pkgs.llvmPackages.clang}/bin/clang";
            };
            buildPhase = ''
              export HOME=$(mktemp -d)
              lake build
            '';
            installPhase = ''
              mkdir -p $out/bin
              cp .lake/build/bin/lean-libclang $out/bin/
            '';
          };
        });

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ (lean4-nix.readToolchainFile ./lean-toolchain) ];
          };
          libclang = pkgs.llvmPackages.libclang;
        in {
          default = pkgs.mkShell {
            nativeBuildInputs = [
              pkgs.lean.lean-all
              pkgs.llvmPackages.clang
            ];
            buildInputs = [
              libclang.dev
              libclang.lib
            ];
            env = {
              LEAN_CC = "${pkgs.llvmPackages.clang}/bin/clang";
            };
          };
        });
    };
}
