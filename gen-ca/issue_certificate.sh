#! /usr/bin/env bash

set -euo pipefail

function main() {
    cert_type="$1"
    signing_ca_dir="$2"
    out_dir="$3"
    name="$4"
    shift 4
    req_flags=("$@")

    # TODO: setup signing ca if not done
    install /app/signing-ca.conf "${signing_ca_dir}"

    if [ ! -f "${out_dir}/${name}.csr" ]; then
        generate_csr "${out_dir}" "${name}" "${req_flags[@]}"
    fi

    issue_certificate "${cert_type}" "${signing_ca_dir}" "${out_dir}" "${name}"
}

function generate_csr() {
    out_dir="$1"
    name="$2"
    shift 2
    req_flags=("$@")

    args=(
        -out "${out_dir}/${name}.csr"
        -keyout "${out_dir}/${name}.key"
    )

    args+=("${req_flags[@]}")

    openssl req -new "${args[@]}"

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
