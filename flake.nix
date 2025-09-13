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
            butane
            kustomize
            pre-commit
            k0sctl
            kubectl
            git
            podman
            bash
            coreutils
            findutils
            tenv
            vault-bin
            gnumake
          ];

          shellHook = ''
            export PROJECT_ROOT="$(git rev-parse --show-toplevel)";
            export CACHE_DIR="$PROJECT_ROOT/.cache";
            export KUBECONFIG="$CACHE_DIR/.kube/config";
          '';
        };
      });
}
