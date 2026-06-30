---
name: cloud-risk-triage-api
description: >-
  Autonomously run a four-check cloud security posture sweep using the Tenable Cloud
  Security public GraphQL API with a Bearer API token (no MCP connection). Use when
  the user asks to run a cloud posture sweep / cloud triage with an API token, or
  specifically to find AWS root users without MFA, list third-party identities with
  access to sensitive data, list publicly exposed resources, or list exposed secrets.
  Always reports every check, marking empty results EMPTY.
---

# Cloud Posture Sweep Agent — API-token / GraphQL (4 checks)

Autonomously run four cloud-security posture checks and write a SOC-ready report,
using the Tenable Cloud Security **public GraphQL API** with a **Bearer API token**.
No MCP connector required. Never fabricate data. **Always output every check section,
even when it returns no rows (mark "EMPTY — no findings").**

## Prerequisites (the run fails without these)

- `TENABLE_CS_API_URL` — Tenable Cloud Security GraphQL endpoint
  (commercial: `https://app.tenable.com/api/graph`; other regions/platforms may differ).
- `TENABLE_CS_API_TOKEN` — API token, sent as `Authorization: Bearer <token>`.
- `curl` and `jq` available.

Caller: `${CLAUDE_PLUGIN_ROOT}/scripts/tcs_graphql.sh` (reads a GraphQL query on
stdin, returns JSON).

**Preflight:** verify both env vars and run `{ __typename }`. If it errors or returns
empty, stop and tell the user to check the endpoint, token, and that their API access
is partner-validated — do not fabricate results.

## Scope note vs the MCP edition

The public GraphQL schema lacks the rich UDM attributes the MCP uses. The four checks
are therefore mapped onto **`Findings` policy categories/names** (and `Entities` where
available), matched case-insensitively on keywords. Exact policy names vary per
tenant; use introspection if a filter is rejected. If a mapped check cannot be
evaluated, still output the section and say so explicitly.

Reference queries are in `references/graphql-queries.md`.

## Workflow

### 1. Preflight
Confirm env vars and connectivity.

### 2. Pull open findings
Query `Findings(filter: { Statuses: [Open] })`, paginating with `first`/`after`.
Select Id, AccountId, AccountName, Provider, Severity, Status, Policy{Name,Category},
Resources{Id,Name}, OpenTime, Description, Remediation{Console{Steps}}.

### 3. Evaluate the checks (always list each; EMPTY if none)
Match findings (and entities) to each check, grouped into two report sections.

**Section A — Address critical findings**
1. **AWS root users without MFA** — policy name/category contains "root" + "MFA".
2. **Third-party identities with sensitive-data access** — policy concerns
   vendor/external/guest identities AND sensitive data (PII/PHI/PCI/secret).
3. **Publicly exposed resources** — policy contains "public"/"publicly exposed"/
   "internet"; flag entries whose resource is internet-reachable where indicated.
4. **Exposed secrets** — policy contains "secret"/"exposed secret"; flag entries on
   network-reachable resources where indicated.

**Section B — Address low-hanging fruits**
5. **Inactive identities** — policy contains "inactive"/"unused" + identity/user/role.
6. **Unused credentials** — policy contains "unused"/"inactive" + "access key"/
   "credential"/"password".
7. **Unused security groups** — policy contains "unused"/"unattached" + "security group".

For each check, report the count and a table; if the match set is empty, output the
section and state "EMPTY — no findings."

**Section C — Discover AI risk**
- **Step 1 — Discover AI assets.** Query `Entities` and keep AI resource types
  (`__typename` containing Bedrock/SageMaker/CognitiveServices/Notebook/Vertex, etc.).
  List asset, type, account, region.
- **Step 2 — Correlate AI resources to training data.** The public GraphQL schema may
  not expose the Bedrock custom-model training/output bucket lineage that the MCP
  edition reads from `AwsBedrockCustomModel`. Attempt it via the AI/inventory query and
  introspection; if the lineage fields aren't available, state so explicitly and fall
  back to listing each model's attached/related data resources. Flag any AI data bucket
  that is publicly exposed or holds sensitive data (cross-reference Checks 3 and 4).

**Section D — Toxic combination**
- **Public workload + critical (VPR) vulnerability + high privilege.** Identify
  workloads that are internet-exposed AND carry a Critical-VPR vulnerability AND are
  privileged. Via the public API: query `Findings` for a toxic-combination / attack-path
  policy if present (policy name contains "public" + "vulnerab" + "privileg"), and/or
  query `Entities` for VM/compute types that are network-exposed and cross-reference
  their vulnerability and privilege findings. The MCP edition expresses this precisely
  with `IVirtualMachine` (network exposure + scope + `VirtualMachineIdentityPermissionActionSeverity`
  + nested `VulnerabilityVprSeverity = Critical`); the public schema may not expose all
  three dimensions, so state any dimension you cannot evaluate. This is the highest-priority
  finding — list it first in the report. Output columns must include **network exposure
  scope** (wide vs specific IP) and **network endpoint identified** (Yes/No) where the
  schema exposes them.

### 4. Remediation order
Short prioritized order across the four checks.

### 5. Deliver
Write `cloud-risk-triage-YYYY-MM-DD.md` to the user's working folder: Summary table of
the four counts, one section per check (each always present, with flag columns where
applicable), Remediation order, Verification notes (exact GraphQL filters + counts, and
a note that checks are mapped to finding categories under the public API). Present the
file and give a 2–3 sentence summary.

## Style
Concise and SOC-actionable. Quote resource Ids and account Ids verbatim. State plainly
where the public API limits a check relative to the MCP edition.
