#!/bin/bash
set -eux
set -o pipefail

find /root -type f -name 'deploy.sh' -exec sh -c 'cd "$(dirname "{}")" && ./deploy.sh' \;
