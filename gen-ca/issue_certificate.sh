#! /usr/bin/env bash

set -euo pipefail

function main() {
    cert_type="$1"
    signing_ca_dir="$2"
    out_dir="$3"
    name="$4"

    generate_csr "${out_dir}" "${name}"
    issue_certificate "${cert_type}" "${signing_ca_dir}" "${out_dir}" "${name}"
}

function generate_csr() {
    out_dir="$1"
    name="$2"

    openssl req -new \
        -out "${out_dir}/${name}.csr" \
        -keyout "${out_dir}/${name}.key"

    chmod 0400 "${out_dir}/${name}.key"
}

function issue_certificate() {
    cert_type="$1"
    signing_ca_dir="$2"
    out_dir="$3"
    name="$4"

    openssl ca \
        -config "${signing_ca_dir}/signing-ca.conf" \
        -in "${out_dir}/${name}.csr" \
        -out "${out_dir}/${name}.crt" \
        -extensions "${cert_type}_ext"
}

main "$@"
