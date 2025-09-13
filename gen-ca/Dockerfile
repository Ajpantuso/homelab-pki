# SPDX-FileCopyrightText: 2025 NONE
#
# SPDX-License-Identifier: Unlicense

FROM registry.access.redhat.com/ubi9/ubi

WORKDIR /app

COPY . .

ENV ROOT_CA_DIR="/root-ca"
ENV SIGNING_CA_DIR="/signing-ca"
ENV OUTPUT_DIR="/output"

VOLUME [ "/root-ca", "/signing-ca", "/output" ]

ENTRYPOINT ["/app/entrypoint.sh"]
