# SPDX-FileCopyrightText: 2025 NONE
#
# SPDX-License-Identifier: Unlicense

# Homelab PKI Makefile
# Migrated from mise.toml

# Default values - override these with environment variables or in a .env file
CONTAINER_ENGINE ?= docker

# K0SCTL Configuration
K0SCTL_USERNAME ?= admin
K0SCTL_IDENTITY_PATH ?= $(HOME)/.ssh/id_rsa
K0SCTL_BASE_CONFIG_PATH ?= $(PROJECT_ROOT)/k0s/k0s.Cluster.yaml
K0SCTL_CONFIG_OUTPUT ?= $(CACHE_DIR)/k0sctl/config.yaml
K0SCTL_CLUSTER_NAME ?= infra

# Include local overrides if they exist
-include .env

help:
	@echo "Available targets:"
	@echo "  k0s-apply              - Apply k0s configuration"
	@echo "  k0s-reset              - Reset k0s cluster"
	@echo "  k0s-config             - Generate kubeconfig"
	@echo "  flux-apply             - Apply Flux configuration"
	@echo "  generate-config        - Generate k0sctl config"
	@echo "  generate-k0s           - Generate base k0s config"
	@echo "  ca-issue-server-cert   - Issue server certificate"
	@echo "  ca-issue-client-cert   - Issue client certificate"
	@echo "  ca-sign-intermediate   - Sign intermediate CA"
	@echo "  ca-generate-signing    - Generate signing CA"
	@echo "  ca-install-certs       - Install root CA to system trust"
	@echo "  ca-generate-root       - Generate root CA"
.PHONY: help

# Flux targets
flux-apply:
	kubectl apply -k flux
.PHONY: flux-apply

# Certificate Authority targets
ca-issue-server-cert:
	$(CONTAINER_ENGINE) run \
		--rm -it \
		--read-only \
		-v "$(SIGNING_CA_DIR):/signing-ca:Z" \
		-v "$(CERT_OUTPUT_DIR):/output:Z" \
		"$$($(CONTAINER_ENGINE) build -q gen-ca)" \
		issue-server-cert $(ARGS)
.PHONY: ca-issue-server-cert

ca-issue-client-cert:
	$(CONTAINER_ENGINE) run \
		--rm -it \
		--read-only \
		-v "$(SIGNING_CA_DIR):/signing-ca:Z" \
		-v "$(CERT_OUTPUT_DIR):/output:Z" \
		"$$($(CONTAINER_ENGINE) build -q gen-ca)" \
		issue-client-cert $(ARGS)
.PHONY: ca-issue-client-cert

ca-sign-intermediate:
	$(CONTAINER_ENGINE) run \
		--rm -it \
		--read-only \
		-v "$(ROOT_CA_DIR):/root-ca:Z" \
		-v "$(CERT_OUTPUT_DIR):/output:Z" \
		"$$($(CONTAINER_ENGINE) build -q gen-ca)" \
		sign-intermediate-ca $(ARGS)
.PHONY: ca-sign-intermediate

ca-generate-signing:
	$(CONTAINER_ENGINE) run \
		--rm -it \
		--read-only \
		-v "$(ROOT_CA_DIR):/root-ca:Z" \
		-v "$(SIGNING_CA_DIR):/signing-ca:Z" \
		"$$($(CONTAINER_ENGINE) build -q gen-ca)" \
		generate-signing-ca
.PHONY: ca-generate-signing

ca-install-certs:
	sudo cp "$(ROOT_CA_DIR)/root-ca.crt" /etc/pki/ca-trust/source/anchors/root-ca.crt
	sudo update-ca-trust
.PHONY: ca-install-certs

ca-generate-root:
	$(CONTAINER_ENGINE) run \
		--rm -it \
		--read-only \
		-v "$(ROOT_CA_DIR):/root-ca:Z" \
		"$$($(CONTAINER_ENGINE) build -q gen-ca)" \
		generate-root-ca
.PHONY: ca-generate-root

reuse-apply:
	reuse annotate --copyright NONE --license Unlicense -r "$(PROJECT_ROOT)" --fallback-dot-license
.PHONY: reuse-apply
