resource "vault_mount" "ssh_ca" {
  path                      = "ssh-ca"
  type                      = "ssh"
  description               = "SSH Certificate Authority for signing SSH certificates"
  default_lease_ttl_seconds = local.default_1hr_in_sec
  max_lease_ttl_seconds     = local.default_1y_in_sec
}

resource "vault_ssh_secret_backend_ca" "ssh_ca" {
  depends_on                = [vault_mount.ssh_ca]
  backend                   = vault_mount.ssh_ca.path
  generate_signing_key      = true
}

resource "vault_ssh_secret_backend_role" "client_role" {
  depends_on             = [vault_ssh_secret_backend_ca.ssh_ca]
  backend                = vault_mount.ssh_ca.path
  name                   = "client-role"
  key_type               = "ca"
  allow_user_certificates = true
  allowed_users          = "*"
  default_extensions = {
    permit-pty = ""
  }
  default_user    = "labadm"
  ttl             = local.default_1y_in_sec
}
