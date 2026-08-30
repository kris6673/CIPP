#!/usr/bin/env bash
# macOS/Linux dev-loop launcher.
#
# Wraps `docker compose ... up` and AUTO-ENABLES Proxyman interception when the
# exported CA is present: if build/config/proxyman-ca.pem exists (and is non-empty),
# the docker-compose-proxyman.yml overlay is layered on automatically. Delete/rename
# the PEM and the next launch is a plain, un-proxied stack — no flags to remember.
#
# Usage (run from anywhere):
#   build/tools/Start-CippDev.sh                 # up --pull always --watch (default)
#   build/tools/Start-CippDev.sh up -d           # any `docker compose` args pass through
#   BASE_COMPOSE=docker-compose-no-frontend.yml build/tools/Start-CippDev.sh
#
# To turn interception on: pwsh build/tools/Export-ProxymanCert.ps1
set -euo pipefail

# build/ dir holds the compose files and the relative ./config path they reference.
BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BUILD_DIR"

BASE_COMPOSE="${BASE_COMPOSE:-docker-compose-all.yml}"
CERT="config/proxyman-ca.pem"

FILES=(-f "$BASE_COMPOSE")
if [ -s "$CERT" ]; then
    FILES+=(-f docker-compose-proxyman.yml)
    echo "🔎 Proxyman cert detected ($CERT) — interception overlay ENABLED."
    echo "   (outbound HTTPS from cipp-api routes through host.docker.internal:9090)"
else
    echo "ℹ️  No Proxyman cert ($CERT) — running the plain dev stack."
    echo "   Enable interception with: pwsh build/tools/Export-ProxymanCert.ps1"
fi

# Default action mirrors the documented header of docker-compose-all.yml; anything
# the caller passes (e.g. `up -d`, `down`, `logs -f`) overrides it verbatim.
if [ "$#" -eq 0 ]; then
    set -- up --pull always --watch
fi

set -x
exec docker compose -p cipp "${FILES[@]}" "$@"
