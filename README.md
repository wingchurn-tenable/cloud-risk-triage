# Cloud Risk Triage Suite — for Tenable Cloud Security

Autonomous cloud security posture-sweep agents for **Tenable Cloud Security**. Each
morning (or on demand) they run **four triage checks** and write a SOC-ready report —
all from live data, nothing fabricated. Every check is always reported, even when it
returns nothing (marked **EMPTY**).

**Address critical findings:**

1. AWS root users without MFA
2. Third-party identities with access to sensitive data
3. Publicly exposed resources (flag: network endpoint identified)
4. Exposed secrets (flag: network-reachable resource)

**Address low-hanging fruits:**

5. Inactive identities
6. Unused credentials
7. Unused security groups

This repo ships **two editions** of the same agent. Install whichever matches how you
connect to Tenable Cloud Security.

## Which edition do I use?

| | **MCP edition** | **API-token edition** |
|---|---|---|
| Plugin | `cloud-risk-triage-agent` | `cloud-risk-triage-agent-api` |
| Connectivity | Tenable Cloud Security **`tcs` MCP connector** | Public **GraphQL API** + **Bearer token** |
| Data model | Full Explore/UDM (entity attributes, data categories, access levels) | Documented public schema (`Findings`, `Entities`, `VulnerabilityInstances`) |
| Four posture checks | ✅ Direct UDM attribute matches | ⚠️ Mapped onto finding policy categories |
| Setup | Connect the connector | Set 2 env vars |
| Best when | You want the richest results | You can't/don't want to connect the MCP, or run in a script/CI context |

**Recommendation:** use the **MCP edition** for the richest results. Use the
**API-token edition** when an MCP connection isn't available and you'd rather
authenticate with a token. They can coexist.

## Repo layout

```
cloud-risk-triage-suite/
├── .claude-plugin/marketplace.json   # makes both plugins installable from this repo
├── build.sh                          # builds both .plugin files into ./dist
├── plugins/
│   ├── cloud-risk-triage-agent/      # MCP edition  (see its own README)
│   └── cloud-risk-triage-agent-api/  # API-token edition (see its own README)
├── README.md
└── LICENSE
```

Each plugin has its own README with full detail; this root page is the overview and
install guide.

## Install

### As a marketplace (both editions, recommended)

In Claude Code:

```
/plugin marketplace add <your-github-username>/cloud-risk-triage-suite
/plugin install cloud-risk-triage-agent@cloud-risk-triage-suite
/plugin install cloud-risk-triage-agent-api@cloud-risk-triage-suite
```

In Cowork: add the repo as a plugin marketplace, then install either plugin from
Settings → Capabilities.

### As a single `.plugin` file

Run `./build.sh` to produce `dist/cloud-risk-triage-agent.plugin` and
`dist/cloud-risk-triage-agent-api.plugin`, then install the one you want (drag in, or
accept the in-chat preview).

## Setup per edition

### MCP edition — `cloud-risk-triage-agent`
1. Install the plugin.
2. Connect the **Tenable Cloud Security (`tcs`) MCP connector** in your client.
3. Ask: "run a cloud risk triage." Optionally have it schedule a daily run.

No credentials live in the plugin — it uses your existing connector session.

### API-token edition — `cloud-risk-triage-agent-api`
1. Install the plugin.
2. Export your environment:
   ```bash
   export TENABLE_CS_API_URL="https://<your-region>.app.ermetic.com/graphql"
   export TENABLE_CS_API_TOKEN="••••••••"
   ```
3. Preflight: `echo '{ __typename }' | plugins/cloud-risk-triage-agent-api/scripts/tcs_graphql.sh`
4. Ask: "run a cloud risk triage."

The token is read from the environment, never written to disk or committed.
Note: the public GraphQL use-cases require **partner-validated API access**; without
it, queries may return no rows.

## What each run does (both editions)

Each run executes seven checks across two sections and writes a report with summary
count tables, one section per check (with the requested flag columns), a remediation
order, and verification notes. Every check section is **always output, marked
"EMPTY — no findings" when there are none**:

**Address critical findings**

1. AWS root users without MFA
2. Third-party identities with access to sensitive data
3. Publicly exposed resources (flag: network endpoint identified)
4. Exposed secrets (flag: related resource has a network endpoint)

**Address low-hanging fruits**

5. Inactive identities
6. Unused credentials
7. Unused security groups

In the API edition these are mapped onto finding policy categories rather than UDM
attributes (see that plugin's README for the differences).

## Contributing / building

`./build.sh` zips each plugin under `plugins/` into `dist/*.plugin` (excludes
`.DS_Store` and nested `*.plugin`). Bump the `version` in each plugin's
`.claude-plugin/plugin.json` and in `marketplace.json` when you change them.

## License

MIT — see [LICENSE](LICENSE).
