#! /usr/bin/env bash

# SPDX-FileCopyrightText: 2025 NONE
#
# SPDX-License-Identifier: Unlicense

set -eo pipefail

function main() {
    case "$1" in
        "generate-root-ca")
            ./generate_root-ca.sh "${ROOT_CA_DIR}"
            ;;
        "generate-signing-ca")
            ./generate_signing-ca.sh "${ROOT_CA_DIR}" "${SIGNING_CA_DIR}"
            ;;
        "issue-client-cert")
            if [ $# -lt 2 ]; then
                usage
                exit 1
            fi

            name="$2"
            shift 2
            ./issue_certificate.sh "client" "${SIGNING_CA_DIR}" "${OUTPUT_DIR}" "${name}" "$@"
            ;;
        "issue-server-cert")
            if [ $# -lt 2 ]; then
                usage
                exit 1
            fi

            name="$2"
            shift 2
            ./issue_certificate.sh "server" "${SIGNING_CA_DIR}" "${OUTPUT_DIR}" "${name}" "$@"
            ;;
        "sign-intermediate-ca")
            if [ $# -lt 2 ]; then
                usage
                exit 1
            fi

            name="$2"
            shift 2
            ./sign_intermediate_ca.sh "${ROOT_CA_DIR}" "${OUTPUT_DIR}" "${name}"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

function usage() {
cat << EOF
Usage: $0 COMMAND
EOF
}

main "$@"
