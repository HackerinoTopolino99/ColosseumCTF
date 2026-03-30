#!/bin/bash
set -eux
set -o pipefail

find /root -type f \( -name 'compose.yaml' -o -name 'compose.yml' -o -name 'docker-compose.yaml' -o -name 'docker-compose.yml' \) -exec sh -c 'cd "$(dirname "{}")" && docker compose up -d' \;
