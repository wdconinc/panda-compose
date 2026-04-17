#!/usr/bin/env bash
# init.sh — first-run initialization for the panda-compose stack.
#
# Run this script after `docker compose up -d` on a fresh deployment to:
#   1. Wait for the PanDA server to become healthy.
#   2. Register the local compute queue (PANDA_COMPOSE_LOCAL) via the REST API.
#
# Environment variables can be overridden; defaults match .env.example.
set -euo pipefail

PANDA_URL="${PANDA_URL:-http://localhost:25080/server/panda}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== panda-compose init ==="

# 1. Wait for server health.
"${SCRIPT_DIR}/healthcheck.sh" 180

# 2. Register the local compute site/queue.
echo "Registering PANDA_COMPOSE_LOCAL queue..."
"${SCRIPT_DIR}/setup-queue.sh"

echo "=== Initialization complete ==="
echo "PanDA server: ${PANDA_URL}"
echo "Admin queue:  PANDA_COMPOSE_LOCAL (status: online)"
