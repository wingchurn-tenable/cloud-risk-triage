#!/usr/bin/env bash
# Tenable Cloud Security GraphQL caller (Bearer API token).
# Reads a GraphQL query from stdin and POSTs it to the /graphql endpoint.
#
# Required environment variables:
#   TENABLE_CS_API_URL    Tenable Cloud Security GraphQL endpoint.
#                         Default/commercial: https://app.tenable.com/api/graph
#                         (other regions/platforms may differ — confirm in the console / docs)
#   TENABLE_CS_API_TOKEN  API token generated in Tenable Cloud Security (used as a Bearer token)
#
# Usage:
#   echo '{ Findings { nodes { Status } } }' | ./tcs_graphql.sh
#   ./tcs_graphql.sh < query.graphql | jq '.data'
set -euo pipefail

: "${TENABLE_CS_API_URL:?Set TENABLE_CS_API_URL to the GraphQL endpoint, e.g. https://app.tenable.com/api/graph}"
: "${TENABLE_CS_API_TOKEN:?Set TENABLE_CS_API_TOKEN to your Tenable Cloud Security API token}"

QUERY="$(cat)"

# Build a JSON body { "query": "..." } safely, then POST with Bearer auth.
jq -nc --arg q "$QUERY" '{query: $q}' \
  | curl -sS --fail-with-body -X POST "$TENABLE_CS_API_URL" \
      -H "Authorization: Bearer ${TENABLE_CS_API_TOKEN}" \
      -H "Content-Type: application/json" \
      -H "User-Agent: cloud-risk-triage-agent/1.0" \
      --data-binary @-
