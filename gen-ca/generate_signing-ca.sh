#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2025 NONE
#
# SPDX-License-Identifier: Unlicense

set -euo pipefail

function main() {
    root_dir="$1"
    signing_dir="$2"

    setup_signing_structure "${signing_dir}"
    generate_signing_csr "${signing_dir}"
    sign_signing_cert "${root_dir}" "${signing_dir}"
}

function setup_signing_structure() {
    signing_dir="$1"

    install /app/signing-ca.conf "${signing_dir}"
    install -m 0700 -d "${signing_dir}/private"
    install -d "${signing_dir}/certs"
    install -d "${signing_dir}/db"
    install -d "${signing_dir}/bundles"
    touch "${signing_dir}/db/index"
    openssl rand -hex 16  > "${signing_dir}/db/serial"
    echo 1001 > "${signing_dir}/db/crlnumber"
}

function generate_signing_csr() {
    signing_dir="$1"

    openssl req -new \
        -config "${signing_dir}/signing-ca.conf" \
        -out "${signing_dir}/signing-ca.csr" \
        -keyout "${signing_dir}/private/signing-ca.key"

    chmod 0400 "${signing_dir}/private/signing-ca.key"
}

function sign_signing_cert() {
    root_dir="$1"
    signing_dir="$2"

    openssl ca \
        -config "${root_dir}/root-ca.conf" \
        -in "${signing_dir}/signing-ca.csr" \
        -out "${signing_dir}/signing-ca.crt" \
        -extensions signing_ca_ext
}

main "$@"
