# SPDX-FileCopyrightText: 2025 NONE
#
# SPDX-License-Identifier: Unlicense

# Kubernetes cert-manager PKI integration
# Provides intermediate CA for automated certificate issuance in Kubernetes cluster

locals {
  k8s_cert_file = "${path.module}/k8s-intermediate-ca-v1.crt"
  # Use try() to safely read the certificate file, returning empty string if it doesn't exist
  k8s_intermediate_cert = try(file(local.k8s_cert_file), "")
  # Determine if the certificate is available
  k8s_cert_exists = local.k8s_intermediate_cert != ""
}

# Intermediate CA PKI mount for Kubernetes certificate issuance
resource "vault_mount" "k8s_intermediate_ca_v1" {
  path                      = "k8s/intermediate-ca/v1"
  type                      = "pki"
  description               = "PKI engine for Kubernetes cert-manager intermediate CA v1"
  default_lease_ttl_seconds = local.default_1hr_in_sec
  max_lease_ttl_seconds     = local.default_3y_in_sec
}

# Generate CSR for Kubernetes intermediate CA (sign with offline root CA)
resource "vault_pki_secret_backend_intermediate_cert_request" "k8s_intermediate_ca_v1" {
  depends_on   = [vault_mount.k8s_intermediate_ca_v1]
  backend      = vault_mount.k8s_intermediate_ca_v1.path
  type         = "internal"
  key_type     = "rsa"
  key_bits     = 4096
  common_name  = "AJP Kubernetes Intermediate CA v1"
  organization = "AJP"
  country      = "US"
  locality     = ""
  province     = ""
}

# Output the CSR so you can sign it with your offline root CA
output "k8s_intermediate_ca_csr" {
  description = "Kubernetes intermediate CA CSR to be signed by offline root CA"
  value       = vault_pki_secret_backend_intermediate_cert_request.k8s_intermediate_ca_v1.csr
  sensitive   = false
}

# Import signed Kubernetes intermediate CA certificate (apply after CSR signing)
# Use count to make this resource conditional - only created when certificate file exists
resource "vault_pki_secret_backend_intermediate_set_signed" "k8s_intermediate_ca_v1" {
  count       = local.k8s_cert_exists ? 1 : 0
  depends_on  = [vault_pki_secret_backend_intermediate_cert_request.k8s_intermediate_ca_v1]
  backend     = vault_mount.k8s_intermediate_ca_v1.path
  certificate = local.k8s_intermediate_cert
}

# Configure CA and CRL distribution URLs
resource "vault_pki_secret_backend_config_urls" "k8s_intermediate_ca_v1" {
  count                   = local.k8s_cert_exists ? 1 : 0
  depends_on              = [vault_pki_secret_backend_intermediate_set_signed.k8s_intermediate_ca_v1]
  backend                 = vault_mount.k8s_intermediate_ca_v1.path
  issuing_certificates    = ["https://vault.ajphome.com/v1/k8s/intermediate-ca/v1/ca"]
  crl_distribution_points = ["https://vault.ajphome.com/v1/k8s/intermediate-ca/v1/crl"]
}

# PKI role for Kubernetes cert-manager certificate issuance
resource "vault_pki_secret_backend_role" "k8s_cert_manager" {
  count                         = local.k8s_cert_exists ? 1 : 0
  depends_on                    = [vault_pki_secret_backend_intermediate_set_signed.k8s_intermediate_ca_v1]
  backend                       = vault_mount.k8s_intermediate_ca_v1.path
  name                          = "k8s-cert-manager"
  ttl                           = local.default_1hr_in_sec * 24 * 30  # 30 days
  max_ttl                       = local.default_1y_in_sec
  allow_ip_sans                 = true
  allow_localhost               = true
  allow_any_name                = true
  enforce_hostnames             = false
  allow_wildcard_certificates   = true
  allow_bare_domains            = true
  allow_subdomains              = true
  server_flag                   = true
  client_flag                   = true
  key_type                      = "rsa"
  key_bits                      = 2048
  use_csr_common_name           = true
  use_csr_sans                  = true
  organization                  = ["AJP"]
  country                       = ["US"]
}

# Vault policy granting cert-manager permissions for certificate operations
resource "vault_policy" "k8s_cert_manager" {
  name = "k8s-cert-manager"

  policy = <<EOT
# Allow cert-manager to issue certificates
path "k8s/intermediate-ca/v1/issue/k8s-cert-manager" {
  capabilities = ["create", "update"]
}

# Allow cert-manager to sign CSRs
path "k8s/intermediate-ca/v1/sign/k8s-cert-manager" {
  capabilities = ["create", "update"]
}

# Allow cert-manager to revoke certificates
path "k8s/intermediate-ca/v1/revoke" {
  capabilities = ["create", "update"]
}

# Allow cert-manager to read CA certificate
path "k8s/intermediate-ca/v1/cert/ca" {
  capabilities = ["read"]
}

# Allow cert-manager to read CA configuration
path "k8s/intermediate-ca/v1/config/ca" {
  capabilities = ["read"]
}

# Allow cert-manager to read CRL configuration
path "k8s/intermediate-ca/v1/config/crl" {
  capabilities = ["read"]
}
EOT
}

# Static authentication token for cert-manager (bound to k8s-cert-manager policy)
resource "vault_token" "k8s_cert_manager" {
  count     = local.k8s_cert_exists ? 1 : 0
  policies  = [vault_policy.k8s_cert_manager.name]
  ttl       = "8760h"  # 1 year - requires manual rotation
  renewable = false
  no_parent = true
}
