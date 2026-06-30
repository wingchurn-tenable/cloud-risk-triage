---
name: cloud-risk-triage
description: >-
  Autonomously run a four-check cloud security posture sweep using Tenable Cloud
  Security (the tcs MCP / Explore UDM data model). Use whenever the user asks to
  run a cloud security triage / posture sweep, or specifically to: find AWS root
  users without MFA, list third-party identities with access to sensitive data,
  list publicly exposed resources, or list exposed secrets. Always reports every
  check — even when a check returns nothing it is listed and marked EMPTY.
---

# Cloud Posture Sweep Agent (4 checks)

Autonomously run four cloud-security posture checks and write a SOC-ready report,
sourced entirely from live Tenable Cloud Security data. Never fabricate data — every
fact must come from a query result. **Always output every check section, even when it
returns no rows (mark it "EMPTY — no findings").**

## Prerequisites

Requires the **Tenable Cloud Security (`tcs`) MCP connector**. Tools:
`mcp__tcs__udm_get_instructions`, `mcp__tcs__udm_get_object_type_metadata`,
`mcp__tcs__udm_get_property_values`, `mcp__tcs__udm_execute_query`,
`mcp__tcs__udm_get_query_results_count`.

## Quirks to remember (these will error otherwise)

- `udm_execute_query` **requires** both `skip` and `take` parameters.
- `udm_get_object_type_metadata` uses the parameter name `objectTypeName`.
- Relation properties (data type `CommonId`, e.g. `CloudRiskTenant`) do **not** accept
  the `In` operator.
- Every query needs a unique UUID `id`; each `UdmQueryProperty.queryId` must match its
  parent query `id`.

## Workflow

### 1. Refresh syntax
Call `mcp__tcs__udm_get_instructions` to load current UDM query schema.

### 2. Run the four checks
Run each check below and produce one report section per check. Use
`mcp__tcs__udm_get_query_results_count` for totals and flagged subsets. Full query
JSON is in `references/udm-queries.md`.

**Check 1 — AWS root users without MFA.** `AwsIamRootUser` where
`UserMfaEnabled = false`. Columns: name, ARN, account.

**Check 2 — Third-party identities with sensitive-data access.** `IIdentity` where
`EntityAttributes In [VendorServiceIdentityAttribute, AadDirectoryUserExternalAttribute, AadDirectoryUserGuestAttribute]`
AND `EntityAttributes In [SensitiveResourcePermissionActionPrincipalAttribute, ApplicationPciDataResourcePermissionActionPrincipalAttribute, ApplicationPhiDataResourcePermissionActionPrincipalAttribute, ApplicationPiiDataResourcePermissionActionPrincipalAttribute, ApplicationSecretsDataResourcePermissionActionPrincipalAttribute]`.
Get the count. Columns: identity, type, account, 3rd-party class, sensitive
categories, risk flags (inactive / MFA-disabled). Prioritize inactive vendor roles
with excessive perms and MFA-disabled guest admins.

**Check 3 — Publicly exposed resources (+ endpoint flag).** `IEntity` where
`AccessEntityInboundAccessAccessLevel In ["Public"]`. Get total count and the subset
count where `EntityNetworkAccessType In ["ExternalDirect","ExternalIndirect"]`. The
table must include a flag column **"Network endpoint identified"** = Yes when
network-exposed, else No.

**Check 4 — Exposed secrets (+ endpoint flag).** `IDataEntity` where
`DataEntityDataTypeCategories In ["Secrets"]`. Get total count and the subset count
where `AccessEntityInboundAccessAccessLevel In ["External","Public"]`. Table flag
column **"Network endpoint identified"** = Yes for that subset, else No. (Data entities
do not expose the NetworkEndpoint relation, so derive the flag from inbound network
access level.)

### 3. Remediation order
Add a short prioritized remediation order across the four checks (typically: identity
clean-up → rotate network-reachable secrets → lock down public regulated-data stores
→ root-MFA monitoring).

### 4. Deliver
Write a markdown report named `cloud-risk-triage-YYYY-MM-DD.md` to the user's working
folder with: a Summary table of the four counts, one section per check (each always
present, EMPTY if no rows, with the requested flag columns), Remediation order, and
Verification notes (exact filters + counts). Present the file and give a 2–3 sentence
chat summary of the four results and whether they changed from a prior run.

## Style
Concise and SOC-actionable. Quote all resource IDs, identity IDs, and tenant IDs
verbatim from query results. Flag if data looks like a demo/test environment (names
containing `demo`/`test`).

## Optional: run it daily
If the user wants continuous monitoring, offer to create a scheduled task that runs
this four-check sweep each morning and writes a dated report.
