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

# K0s targets
k0s-apply: generate-config
	k0sctl apply -c $(K0SCTL_CONFIG_OUTPUT)
.PHONY: k0s-apply

k0s-reset: generate-config
	k0sctl reset --force -c $(K0SCTL_CONFIG_OUTPUT)
.PHONY: k0s-reset

k0s-config: generate-config
	@mkdir -p $(dir $(KUBECONFIG))
	@install -m 0600 <(k0sctl kubeconfig -c $(K0SCTL_CONFIG_OUTPUT)) $(KUBECONFIG)
	export KUBECONFIG=$(KUBECONFIG)
.PHONY: k0s-config

# Flux targets
flux-apply:
	kubectl apply -k flux
.PHONY: flux-apply

# Generate targets
generate-config: generate-k0s
	@mkdir -p $(dir $(K0SCTL_CONFIG_OUTPUT))
	kustomize build k0s > $(K0SCTL_CONFIG_OUTPUT)
.PHONY: generate-config

generate-k0s:
	k0sctl init --k0s \
		--user $(K0SCTL_USERNAME) \
		-i $(K0SCTL_IDENTITY_PATH) \
		--cluster-name "$(K0SCTL_CLUSTER_NAME)" \
		$(K0SCTL_HOSTS) > $(K0SCTL_BASE_CONFIG_PATH)
.PHONY: generate-k0s

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
