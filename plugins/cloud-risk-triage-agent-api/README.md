# Cloud Posture Sweep Agent — API-token / GraphQL edition

An autonomous cloud security posture agent for **Tenable Cloud Security** that uses
the **public GraphQL API with a Bearer API token** — **no MCP connection required**.
It runs four triage checks and writes a SOC-ready report. Every check is always
reported, even when it returns nothing (marked **EMPTY**).

This is the standalone sibling of `cloud-risk-triage-agent` (which runs through the
`tcs` MCP connector). Pick this edition when you'd rather authenticate with an API
token in a script/CI context.

## The checks

**Address critical findings**

1. **AWS root users without MFA**
2. **Third-party identities with access to sensitive data**
3. **Publicly exposed resources** (flag: network endpoint identified)
4. **Exposed secrets** (flag: network-reachable resource)

**Address low-hanging fruits**

5. **Inactive identities**
6. **Unused credentials**
7. **Unused security groups**

**Discover AI risk**

- Step 1 — Discover AI assets in your inventory
- Step 2 — Correlate AI resources to training data

**Toxic combination**

- Public workload + critical (VPR) vulnerability + high-privilege permission

Under the public API the checks are mapped onto **finding policy categories**
rather than UDM attributes, and the AI training-data lineage may not be exposed in the
public schema (the MCP edition reads it from `AwsBedrockCustomModel`); see below.

## How it differs from the MCP edition (read this first)

The public GraphQL schema is **smaller** than Tenable's internal Explore/UDM model
that the MCP exposes:

- Primary query roots are `Findings`, `Entities`, and `VulnerabilityInstances`.
- `Entities` filtering is limited (account / provider / region / type); the rich UDM
  attributes (vendor & sensitive-data flags, inbound access level, data categories)
  aren't exposed, so the four posture checks are mapped onto **finding policy
  categories** instead — exact policy names vary per tenant.
- The documented query use-cases require **partner-validated API access**; without it
  queries may return no rows.

If you need the richest results (direct UDM attribute matches for each check), use the
MCP edition.

## Requirements

- `curl` and `jq` available in the shell.
- Two environment variables:
  - `TENABLE_CS_API_URL` — the Tenable Cloud Security GraphQL endpoint. Commercial
    platform: `https://app.tenable.com/api/graph` (other regions/platforms may differ —
    confirm in the Tenable Cloud Security console / docs).
  - `TENABLE_CS_API_TOKEN` — an API token from Tenable Cloud Security, sent as
    `Authorization: Bearer <token>`.

## Setup

```bash
export TENABLE_CS_API_URL="https://app.tenable.com/api/graph"
export TENABLE_CS_API_TOKEN="••••••••"
chmod +x scripts/tcs_graphql.sh

# preflight
echo '{ __typename }' | ./scripts/tcs_graphql.sh
```

A `{"data":{"__typename":"Query"}}` response means auth + endpoint are good.

## Usage

Ask naturally ("run a cloud posture sweep", "list publicly exposed resources",
"find root users without MFA"). The `cloud-risk-triage-api` skill triggers, runs the
preflight, queries Findings, evaluates the four checks, and writes a dated report.

Run a raw query yourself:

```bash
echo 'query { Findings(first: 5, filter:{Statuses:[Open]}) { nodes { Severity Policy{Name} Resources{Id} } } }' \
  | ./scripts/tcs_graphql.sh | jq '.data.Findings.nodes'
```

## Layout

```
cloud-risk-triage-agent-api/
├── .claude-plugin/plugin.json
├── skills/cloud-risk-triage-api/
│   ├── SKILL.md
│   └── references/graphql-queries.md
├── scripts/tcs_graphql.sh
└── README.md
```

## Security

The token is read from an environment variable and never written to disk or
committed. Do not hardcode it. Scope the token to read-only where possible.

## Status

The GraphQL queries are built from Tenable's documented public schema but are **not
tested against a live tenant in this package** — confirm your region endpoint, token,
and validated access on first run. Field/enum names can vary by tenant; use the
introspection snippet in `references/graphql-queries.md` if a filter is rejected.

## License

MIT
