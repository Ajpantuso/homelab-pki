# SPDX-FileCopyrightText: 2025 NONE
#
# SPDX-License-Identifier: Unlicense

{
  description = "Homelab PKI development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            bash
            butane
            coreutils
            findutils
            git
            gnumake
            k0sctl
            kubectl
            kustomize
            podman
            pre-commit
            reuse
            tenv
            vault-bin
          ];

          shellHook = ''
            export PROJECT_ROOT="$(git rev-parse --show-toplevel)";
            export CACHE_DIR="$PROJECT_ROOT/.cache";
          '';
        };
      });
}
