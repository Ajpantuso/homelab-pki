# SPDX-FileCopyrightText: 2025 NONE
#
# SPDX-License-Identifier: Unlicense

resource "vault_mount" "home_v1_ica1_v1" {
  path                      = "home/v1/ica1/v1"
  type                      = "pki"
  description               = "PKI engine hosting intermediate CA1 v1 for home org"
  default_lease_ttl_seconds = local.default_1hr_in_sec
  max_lease_ttl_seconds     = local.default_3y_in_sec
}

resource "vault_pki_secret_backend_intermediate_cert_request" "home_v1_ica1_v1" {
  depends_on   = [vault_mount.home_v1_ica1_v1]
  backend      = vault_mount.home_v1_ica1_v1.path
  type         = "internal"
  key_type     = "rsa"
  key_bits     = "4096"
  common_name  = "Intermediate CA1 v1"
  organization = "AJP"
  country      = "US"
}
