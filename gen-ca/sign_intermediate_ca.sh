#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2025 NONE
#
# SPDX-License-Identifier: Unlicense

set -euo pipefail

function main() {
    root_dir="$1"
    intermediate_dir="$2"
    name="$3"

    # TODO: setup root ca if not done
    install /app/root-ca.conf "${root_dir}"

    sign_intermediate_ca "${root_dir}" "${intermediate_dir}" "${name}"
}

function sign_intermediate_ca() {
    root_dir="$1"
    intermediate_dir="$2"
    name="$3"

    cat "${root_dir}/root-ca.conf"

    openssl ca \
        -config "${root_dir}/root-ca.conf" \
        -in "${intermediate_dir}/${name}.csr" \
        -out "${intermediate_dir}/${name}.crt" \
        -extensions signing_ca_ext
}

main "$@"
