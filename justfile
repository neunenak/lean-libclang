_default:
    @just --list


build:
    nix develop --command lake build

# Run the AST printer on a C file
run file:
    nix develop --command .lake/build/bin/lean-libclang {{file}}

# Build and run via nix
nix-run file:
    nix run . -- {{file}}

# Clean build artifacts
clean:
    nix develop --command lake clean
