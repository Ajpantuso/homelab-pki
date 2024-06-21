#! /usr/bin/env bash

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

            ./issue_certificate.sh "client" "${SIGNING_CA_DIR}" "${OUTPUT_DIR}" "$2"
            ;;
        "issue-server-cert")
            if [ $# -lt 2 ]; then
                usage
                exit 1
            fi

            ./issue_certificate.sh "server" "${SIGNING_CA_DIR}" "${OUTPUT_DIR}" "$2"
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