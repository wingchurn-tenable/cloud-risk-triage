# Tenable Cloud Security GraphQL — Reference Queries

All queries are POSTed to `$TENABLE_CS_API_URL` (the Tenable Cloud Security GraphQL
endpoint, e.g. `https://app.tenable.com/api/graph`) with
`Authorization: Bearer $TENABLE_CS_API_TOKEN`. Pipe them through the helper:

```bash
echo '<query>' | "${CLAUDE_PLUGIN_ROOT}/scripts/tcs_graphql.sh" | jq '.data'
```

Fields below are from Tenable's documented public GraphQL use-cases. Exact filter
enums (Providers, Statuses, Types) and policy names vary by tenant — discover them
with introspection if a query is rejected.

---

## 0. Preflight

```graphql
{ __typename }
```

Expect `{"data":{"__typename":"Query"}}`. Empty/errors → check URL, token, and
partner-validated access before continuing.

## 1. Open findings (input for all four checks)

Paginate with `first`/`after`. Filter to open status. Findings drive all four posture
checks — match each finding to a check via its `Policy.Name` / `Policy.Category`.

```graphql
query($after: String) {
  Findings(first: 100, after: $after, filter: { Statuses: [Open] }) {
    nodes {
      Id
      AccountId
      AccountName
      Provider
      Severity
      Status
      SubStatus
      OpenTime
      Description
      Policy { Name Category }
      Resources { Id Name }
      Remediation { Console { Steps } }
    }
    pageInfo { hasNextPage endCursor }
  }
}
```

> The helper sends a plain query string. To page without GraphQL variables, inline
> the cursor: `Findings(first: 100, after: "cursor10", filter: { Statuses: [Open] })`.

## 2. Inventory / entities (exposure context)

```graphql
query($after: String) {
  Entities(first: 100, after: $after, filter: { Providers: [] }) {
    nodes {
      Id
      Name
      Type: __typename
      AccountId
      AccountName
      Provider
      Region
      Labels
      Tags { Key Value }
      ... on AwsResource { Arn }
    }
    pageInfo { hasNextPage endCursor }
  }
}
```

## 3. Vulnerability instances (optional enrichment)

```graphql
query($after: String) {
  VulnerabilityInstances(first: 100, after: $after,
      filter: { VulnerabilitySeverities: [Critical, High] }) {
    nodes {
      Resolved
      Software { Name }
      Resource { Id Name }
      Vulnerability { Id Severity CvssScore Description }
    }
    pageInfo { hasNextPage endCursor }
  }
}
```

## 4. Vulnerability-only findings (optional)

```graphql
query {
  Findings(filter: { Types: [
    VirtualMachineOperatingSystemUnpatchedFinding,
    VirtualMachineVulnerabilityFinding
  ] }) {
    nodes { Id Policy { Name } Status Description Resources { Id Name } }
    pageInfo { hasNextPage endCursor }
  }
}
```

---

## Discovering filter values (introspection)

If a filter enum is rejected, introspect it:

```graphql
{ __type(name: "FindingFilter") { inputFields { name type { name kind ofType { name } } } } }
```

Swap `FindingFilter` for the relevant input type name reported in the error.

## Mapping the four posture checks to Findings (primary output)

The public `Entities` query lacks the UDM attributes used by the MCP version, so map
each of the four posture checks onto finding **policy categories/names** (match
case-insensitively on keywords; exact names differ per tenant). These four checks are
the deliverable — there is no separate highest-risk ranking in this edition:

| Check | Match findings where Policy.Name / Category contains |
|---|---|
| 1. Root user without MFA | "root", "MFA" |
| 2. 3rd-party identity + sensitive data | "third party" / "external" / "vendor" AND "sensitive"/"PII"/"PHI"/"PCI"/"secret" |
| 3. Publicly exposed resources | "public", "publicly exposed", "internet" |
| 4. Exposed secrets | "secret", "exposed secret" |
| 5. Inactive identities | "inactive" / "unused" + "identity"/"user"/"role" |
| 6. Unused credentials | "unused"/"inactive" + "access key"/"credential"/"password" |
| 7. Unused security groups | "unused"/"unattached" + "security group" |

Checks 1–4 are "Address critical findings"; checks 5–7 are "Address low-hanging fruits".

## Discover AI risk

**Step 1 — Discover AI assets.** Use the `Entities` query and keep AI resource types by
`__typename` (Bedrock agents/custom models, SageMaker, Azure Cognitive Services/OpenAI,
GCP Vertex notebooks, etc.):

```graphql
query($after: String) {
  Entities(first: 100, after: $after) {
    nodes { Id Name Type: __typename AccountId Provider Region }
    pageInfo { hasNextPage endCursor }
  }
}
```

Filter the returned nodes client-side to AI `__typename`s.

**Step 2 — Correlate AI resources to training data.** The public schema may not expose
the Bedrock custom-model training/output bucket lineage that the MCP edition reads from
`AwsBedrockCustomModel` (`InputTrainingBucket`, `OutputBucket`). Introspect the model
type and, if those fields aren't present, state so and fall back to the model's related
data resources. Flag any AI data bucket that is public or holds sensitive data.

## Toxic combination — public workload + critical-VPR vuln + privileged

The MCP edition expresses this with `IVirtualMachine` (network exposure type + scope,
`VirtualMachineIdentityPermissionActionSeverity`, and a nested
`VulnerabilityVprSeverity = Critical`). The public GraphQL schema may not expose all
three dimensions on `Entities`. Best-effort:

- Look for a built-in toxic-combination / attack-path **Finding** policy (Policy.Name
  contains "public" + "vulnerab" + "privileg") and list its resources.
- Otherwise, query `Entities` for VM/compute types, keep the internet-exposed ones, and
  cross-reference each against vulnerability findings (Critical) and privilege/permission
  findings. State explicitly any of the three dimensions the public schema can't confirm.

Always output each section even if the match set is empty (state "EMPTY — no findings").
