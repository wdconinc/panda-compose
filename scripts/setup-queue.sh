#!/usr/bin/env bash
# setup-queue.sh — register the PANDA_COMPOSE_LOCAL compute queue via the PanDA REST API.
#
# The PanDA server must already be healthy before calling this script.
# See: https://panda-wms.readthedocs.io/en/latest/
set -euo pipefail

PANDA_URL="${PANDA_URL:-http://localhost:25080/server/panda}"
QUEUE_NAME="PANDA_COMPOSE_LOCAL"

echo "Registering queue '${QUEUE_NAME}' at ${PANDA_URL}..."

# Build the schedconfig payload for a minimal local queue.
# Fields match what JEDI expects from the CRIC-compatible schedconfig endpoint.
PAYLOAD=$(cat <<EOF
{
  "siteid": "${QUEUE_NAME}",
  "panda_resource": "${QUEUE_NAME}",
  "status": "online",
  "queue_type": "unified",
  "maxmemory": 2000,
  "maxtime": 3600,
  "corecount": 1,
  "type": "analysis",
  "harvester": "panda-compose-harvester",
  "vo": "wlcg",
  "catchall": "singularity=false"
}
EOF
)

HTTP_STATUS=$(curl -sf -o /dev/null -w "%{http_code}" \
    -X POST "${PANDA_URL}/addSiteToScheduler" \
    -H "Content-Type: application/json" \
    -d "${PAYLOAD}" || true)

if [[ "${HTTP_STATUS}" =~ ^2 ]]; then
    echo "Queue '${QUEUE_NAME}' registered successfully (HTTP ${HTTP_STATUS})."
else
    echo "WARNING: Queue registration returned HTTP ${HTTP_STATUS}." >&2
    echo "The queue may need to be registered manually via the PanDA admin interface." >&2
    echo "Payload was:" >&2
    echo "${PAYLOAD}" >&2
fi
