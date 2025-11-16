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
            coreutils
            findutils
            git
            gnumake
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

            # Check if 'pki' context exists, if not create it
            if ! kubectl config get-contexts | grep -q "pki"; then
              kubectl config set-cluster pki --server=https://pki.ajphome.com:6443 --insecure-skip-tls-verify=true
              kubectl config set-context pki --cluster=pki --user=ajpantuso@gmail.com
            fi

            # Test connectivity to the cluster
            if kubectl cluster-info --context=pki &>/dev/null; then
              kubectl config use-context pki
            else
              echo "Warning: Could not connect to pki cluster at https://pki.ajphome.com:6443"
            fi
          '';
        };
      });
}
