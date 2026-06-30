---
name: cloud-risk-triage
description: >-
  Autonomously run a cloud security posture sweep using Tenable Cloud Security (the
  tcs MCP / Explore UDM data model). Produces two work streams: "Address critical
  findings" (root users without MFA, third-party identities with sensitive-data
  access, publicly exposed resources, exposed secrets) and "Address low-hanging
  fruits" (inactive identities, unused credentials, unused security groups). Use for
  cloud security triage / posture sweep or any of these specific checks. Always
  reports every check — even when one returns nothing it is listed and marked EMPTY.
---

# Cloud Posture Sweep Agent

Autonomously run a cloud-security posture sweep and write a SOC-ready report, sourced
entirely from live Tenable Cloud Security data. Never fabricate data — every fact must
come from a query result. **Always output every check section, even when it returns no
rows (mark it "EMPTY — no findings").**

The report has two sections: **Address critical findings** (Checks 1–4) and **Address
low-hanging fruits** (Checks 5–7).

## Prerequisites

Requires the **Tenable Cloud Security (`tcs`) MCP connector**. Tools:
`mcp__tcs__udm_get_instructions`, `mcp__tcs__udm_get_object_type_metadata`,
`mcp__tcs__udm_get_property_values`, `mcp__tcs__udm_execute_query`,
`mcp__tcs__udm_get_query_results_count`.

## Quirks to remember (these will error otherwise)

- `udm_execute_query` **requires** both `skip` and `take` parameters.
- `udm_get_object_type_metadata` uses the parameter name `objectTypeName`.
- Relation properties (data type `CommonId`, e.g. `CloudRiskTenant`) do **not** accept
  the `In` operator — use a `UdmQueryRelationRule`.
- Every query needs a unique UUID `id`; each `UdmQueryProperty.queryId` must match its
  parent query `id`.

## Workflow

### 1. Refresh syntax
Call `mcp__tcs__udm_get_instructions` to load current UDM query schema.

### 2. Run the checks
Run all seven checks, one report section each. Use
`mcp__tcs__udm_get_query_results_count` for totals and flagged subsets. Full query JSON
is in `references/udm-queries.md`.

#### Section A — Address critical findings

**Check 1 — AWS root users without MFA.** `AwsIamRootUser` where
`UserMfaEnabled = false`. Columns: name, ARN, account.

**Check 2 — Third-party identities with sensitive-data access.** `IIdentity` where
`EntityAttributes In [VendorServiceIdentityAttribute, AadDirectoryUserExternalAttribute, AadDirectoryUserGuestAttribute]`
AND `EntityAttributes In [SensitiveResourcePermissionActionPrincipalAttribute, ApplicationPciDataResourcePermissionActionPrincipalAttribute, ApplicationPhiDataResourcePermissionActionPrincipalAttribute, ApplicationPiiDataResourcePermissionActionPrincipalAttribute, ApplicationSecretsDataResourcePermissionActionPrincipalAttribute]`.
Columns: identity, type, account, 3rd-party class, sensitive categories, risk flags.

**Check 3 — Publicly exposed resources (+ endpoint flag).** `IEntity` where
`AccessEntityInboundAccessAccessLevel In ["Public"]`. Total + subset count where
`EntityNetworkAccessType In ["ExternalDirect","ExternalIndirect"]`. Flag column
**"Network endpoint identified"** = Yes when network-exposed, else No.

**Check 4 — Exposed secrets (+ endpoint flag).** `IDataEntity` where
`DataEntityDataTypeCategories In ["Secrets"]`. Total + subset count where
`AccessEntityInboundAccessAccessLevel In ["External","Public"]`. Flag column
**"Network endpoint identified"** = Yes for that subset, else No. (Data entities don't
expose the NetworkEndpoint relation — derive the flag from inbound access level.)

#### Section B — Address low-hanging fruits

**Check 5 — Inactive identities.** `IIdentity` where `PrincipalInactive = true`. Count
+ sample. Note the population is usually dominated by directory users; recommend
prioritizing inactive identities that are also privileged or carry sensitive-data
access (cross-reference Check 2). Columns: identity, type, account.

**Check 6 — Unused credentials.** `AwsIamUser` where `PrincipalInactive = true` AND
`EntityAttributes In ["AwsAccessKeyEnabledUserAttribute"]` (inactive users still
holding an enabled access key). Also select `AwsIamUserPasswordEnabled`. Columns: user,
account, console-password-enabled.

**Check 7 — Unused security groups.** `AwsEc2SecurityGroup` with an **empty**
`AwsEc2SecurityGroupResources` relation (no attached resources) — use a
`UdmQueryRelationRule` with `not: true` and an empty inner rule group. Also select
`AwsEc2SecurityGroupDefaultSecurityGroup`. Columns: SG name, account, region, default-SG.

### 3. Remediation order
Provide a prioritized order: critical findings first (identity clean-up → rotate
network-reachable secrets → lock down public regulated-data stores → root-MFA
monitoring), then low-hanging fruit (unused credentials → orphaned security groups →
bulk-deprovision inactive identities).

### 4. Deliver
Write a markdown report named `cloud-risk-triage-YYYY-MM-DD.md` to the user's working
folder with: a two-part Summary table (critical findings; low-hanging fruits), a
`# Address critical findings` section (Checks 1–4) and a `# Address low-hanging fruits`
section (Checks 5–7) — each check always present, EMPTY if no rows, with the requested
flag columns — a Remediation order, and Verification notes (exact filters + counts).
Present the file and give a 2–3 sentence chat summary of the results and whether they
changed from a prior run.

## Style
Concise and SOC-actionable. Quote all resource IDs, identity IDs, and tenant IDs
verbatim. Flag if data looks like a demo/test environment (names containing
`demo`/`test`).

## Optional: run it daily
If the user wants continuous monitoring, offer to create a scheduled task that runs
this sweep each morning and writes a dated report.
