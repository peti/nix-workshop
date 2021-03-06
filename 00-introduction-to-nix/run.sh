#! /bin/sh

set -eu

# Interpret the Nix language.
nix-instantiate --eval -E '"hello"'                      # prints: "hello"
nix-instantiate --eval -E '1 + 2'                        # prints: 3
nix-instantiate --eval -E '[ "hello" (1 + 2) ]'          # prints: [ "hello" <CODE> ]
nix-instantiate --eval --strict -E '[ "hello" (2 - 1) ]' # prints: [ "hello" 3 ]
nix-instantiate --eval --strict -E '
  with import <nixpkgs> {};
  let
    fib = n: if n == 0 then 0 else
             if n == 1 then 1 else
             fib (n - 2) + fib (n - 1);
  in
    map fib (lib.range 0 10)'

# Create a store derivation.
nix-instantiate 2>/dev/null -E '
  builtins.derivation {
    name = "test-0";
    system = "x86_64-linux";
    builder = "/bin/sh";
    args = ["-c" "echo Hello, Nix."];
  }'

# Realize a store path.
drv=$(nix-instantiate 2>/dev/null -E '
  with import <nixpkgs> {};
  builtins.derivation {
    name = "test-0";
    system = "x86_64-linux";
    builder = "/bin/sh";
    args = ["-c" "${coreutils}/bin/ls -la /nix/store >$out"];
  }')
nix-store 2>/dev/null --realize $drv

# Now for real.
nix-build --no-out-link -E '
  with import <nixpkgs> {};
  builtins.derivation {
    name = "test-0";
    system = "x86_64-linux";
    PATH = lib.makeBinPath [coreutils hello];
    builder = writeScript "my-build-script"
      "#! ${bash}/bin/bash
       echo PATH=$PATH | tee $out
       hello
      ";
  }'
