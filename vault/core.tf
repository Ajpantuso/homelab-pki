# SPDX-FileCopyrightText: 2025 NONE
#
# SPDX-License-Identifier: Unlicense

# Certificate issuance integration for core cluster

# Intermediate CA PKI Backend
resource "vault_mount" "home_v1_ica1_v1" {
  path                      = "home/v1/ica1/v1"
  type                      = "pki"
  description               = "PKI engine hosting intermediate CA1 v1 for home org"
  default_lease_ttl_seconds = local.default_1hr_in_sec
  max_lease_ttl_seconds     = local.default_3y_in_sec
}

# Generate intermediate CA CSR (to be signed by offline root CA)
resource "vault_pki_secret_backend_intermediate_cert_request" "home_v1_ica1_v1" {
  depends_on   = [vault_mount.home_v1_ica1_v1]
  backend      = vault_mount.home_v1_ica1_v1.path
  type         = "internal"
  key_type     = "rsa"
  key_bits     = 4096
  common_name  = "AJP Intermediate CA1 v1"
  organization = "AJP"
  country      = "US"
  locality     = ""
  province     = ""
}

# Output the CSR so you can sign it with your offline root CA
output "intermediate_ca_csr" {
  description = "CSR to be signed by offline root CA"
  value       = vault_pki_secret_backend_intermediate_cert_request.home_v1_ica1_v1.csr
  sensitive   = false
}

# Set the signed intermediate certificate (apply this after signing the CSR)
resource "vault_pki_secret_backend_intermediate_set_signed" "home_v1_ica1_v1" {
  depends_on  = [vault_pki_secret_backend_intermediate_cert_request.home_v1_ica1_v1]
  backend     = vault_mount.home_v1_ica1_v1.path
  certificate = file("${path.module}/intermediate-ca1-v1.crt")
}

# Configure URLs for the intermediate CA
resource "vault_pki_secret_backend_config_urls" "home_v1_ica1_v1" {
  depends_on              = [vault_pki_secret_backend_intermediate_set_signed.home_v1_ica1_v1]
  backend                 = vault_mount.home_v1_ica1_v1.path
  issuing_certificates    = ["https://vault.ajphome.com/v1/home/v1/ica1/v1/ca"]
  crl_distribution_points = ["https://vault.ajphome.com/v1/home/v1/ica1/v1/crl"]
}

# PKI role for cert-manager
resource "vault_pki_secret_backend_role" "cert_manager" {
  depends_on                    = [vault_pki_secret_backend_intermediate_set_signed.home_v1_ica1_v1]
  backend                       = vault_mount.home_v1_ica1_v1.path
  name                          = "cert-manager"
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

# PKI role for server certificates
resource "vault_pki_secret_backend_role" "server" {
  depends_on                    = [vault_pki_secret_backend_intermediate_set_signed.home_v1_ica1_v1]
  backend                       = vault_mount.home_v1_ica1_v1.path
  name                          = "server"
  ttl                           = local.default_1hr_in_sec * 24 * 30  # 30 days
  max_ttl                       = local.default_1hr_in_sec * 24 * 90  # 90 days
  allow_ip_sans                 = true
  allow_localhost               = true
  allowed_domains               = ["ajphome.com", "local", "localhost"]
  allow_subdomains              = true
  allow_wildcard_certificates   = true
  allow_bare_domains            = false
  server_flag                   = true
  client_flag                   = false
  key_type                      = "rsa"
  key_bits                      = 2048
  organization                  = ["AJP"]
  country                       = ["US"]
}

# Create policy for cert-manager
resource "vault_policy" "cert_manager" {
  name = "cert-manager"

  policy = <<EOT
# Allow cert-manager to read PKI secrets
path "home/v1/ica1/v1/issue/*" {
  capabilities = ["create", "update"]
}

path "home/v1/ica1/v1/sign/*" {
  capabilities = ["create", "update"]
}

path "home/v1/ica1/v1/cert/ca" {
  capabilities = ["read"]
}

path "home/v1/ica1/v1/config/ca" {
  capabilities = ["read"]
}

path "home/v1/ica1/v1/config/crl" {
  capabilities = ["read"]
}
EOT
}

# Create a token for cert-manager with the cert-manager policy
resource "vault_token" "cert_manager" {
  policies  = [vault_policy.cert_manager.name]
  ttl       = "8760h"
  renewable = false
  no_parent = true
}
