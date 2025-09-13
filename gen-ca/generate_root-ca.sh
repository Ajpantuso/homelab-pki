#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2025 NONE
#
# SPDX-License-Identifier: Unlicense

set -euo pipefail

function main() {
    root_dir="$1"

    setup_root_structure "${root_dir}"
    generate_root_csr "${root_dir}"
    selfsign_root_cert "${root_dir}"
}

function setup_root_structure() {
    root_dir="$1"

    install /app/root-ca.conf "${root_dir}"
    install -m 0700 -d "${root_dir}/private"
    install -d "${root_dir}"/certs
    install -d "${root_dir}"/db
    touch "${root_dir}/db/index"
    openssl rand -hex 16  > "${root_dir}/db/serial"
    echo 1001 > "${root_dir}/db/crlnumber"
}

function generate_root_csr() {
    root_dir="$1"

    openssl req -new \
        -config "${root_dir}/root-ca.conf" \
        -out "${root_dir}/root-ca.csr" \
        -keyout "${root_dir}/private/root-ca.key"

    chmod 0400 "${root_dir}/private/root-ca.key"
}

function selfsign_root_cert() {
    root_dir="$1"

    openssl ca -selfsign \
        -config "${root_dir}/root-ca.conf" \
        -in "${root_dir}/root-ca.csr" \
        -out "${root_dir}/root-ca.crt" \
        -extensions ca_ext
}

main "$@"
