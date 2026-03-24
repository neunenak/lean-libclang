_default:
    @just --list


# Build the library and executable using lake
build:
    lake build

# Run the example executable, which shows a basic parse tree of a C file given as an argument
run *args:
    lake exe lean-libclang {{args}}

# Build the library and executable using nix
nix-build:
    nix build

# Build and run via nix
nix-run *args:
    nix run . -- {{args}}

# Clean build artifacts
clean:
    lake clean
