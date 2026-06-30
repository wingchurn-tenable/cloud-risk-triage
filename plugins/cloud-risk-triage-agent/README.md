# Cloud Posture Sweep Agent (MCP edition)

An autonomous cloud security posture agent for **Tenable Cloud Security**. It runs
four triage checks and writes a SOC-ready report — all from live data, nothing
fabricated. Every check is always reported, even when it returns nothing (marked
**EMPTY**).

Built for cloud security architects and SOC analysts who want a fast daily posture
read.

## The checks

**Address critical findings**

1. **AWS root users without MFA**
2. **Third-party identities with access to sensitive data** (vendor / external / guest
   identities holding PCI/PHI/PII/Secrets access)
3. **Publicly exposed resources** — with a flag for those that have a network endpoint
   identified
4. **Exposed secrets** — with a flag for those on a network-reachable resource

**Address low-hanging fruits**

5. **Inactive identities**
6. **Unused credentials** (inactive IAM users with an enabled access key)
7. **Unused security groups** (no attached resources)

## Requirements

- **Claude Cowork** (or Claude Code).
- The **Tenable Cloud Security (`tcs`) MCP connector** connected in your client. No
  credentials are bundled — it uses your existing connection.

## Install

In Cowork: install the `.plugin` file from Settings → Capabilities, or accept the
plugin preview in chat. In Claude Code: add this repo as a plugin / marketplace.

## Usage

Ask naturally:

- "Run a cloud posture sweep / cloud risk triage."
- "Find AWS root users without MFA."
- "List third-party identities with access to sensitive data."
- "List publicly exposed resources."
- "List exposed secrets."

The `cloud-risk-triage` skill triggers automatically and produces a dated report with
a summary table, one section per check (with the requested flag columns), a
remediation order, and verification notes.

### Run it daily

Ask the agent to "run the cloud posture sweep every morning" to set up a scheduled
task that writes a dated report each day.

## Layout

```
cloud-risk-triage-agent/
├── .claude-plugin/plugin.json
├── skills/cloud-risk-triage/
│   ├── SKILL.md
│   └── references/udm-queries.md
└── README.md
```

## Notes

The agent flags when data looks like a demo/test environment (names containing
`demo`/`test`). Data entities don't expose the network-endpoint relation, so the
exposed-secrets endpoint flag is derived from inbound network access level. Validate
remediation against your change-control process.

## License

MIT
