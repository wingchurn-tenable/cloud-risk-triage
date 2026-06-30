# Reusable UDM Query Templates — Four-Check Posture Sweep

Copy these into `mcp__tcs__udm_execute_query`. Always pass `skip` and `take`. UUIDs
only need to be internally consistent (`queryId` must equal the parent query `id`).
Use `mcp__tcs__udm_get_query_results_count` with the same rule group for totals.

---

## Check 1 — AWS root users without MFA

`udm_execute_query` with `skip: 0`, `take: 100`:

```json
{
  "typeName": "UdmQuery",
  "id": "e1111111-1111-1111-1111-111111111111",
  "objectTypeName": "AwsIamRootUser",
  "collapsed": false, "objectResultHidden": false, "groupProperties": null, "timeZoneId": null, "joins": [],
  "properties": [
    {"identifier": "EntityName", "queryId": "e1111111-1111-1111-1111-111111111111", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "AwsEntityArn", "queryId": "e1111111-1111-1111-1111-111111111111", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "AwsEntityTenant", "queryId": "e1111111-1111-1111-1111-111111111111", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "UserMfaEnabled", "queryId": "e1111111-1111-1111-1111-111111111111", "sort": null, "startOfWeek": null, "transform": null}
  ],
  "ruleGroup": {
    "typeName": "UdmQueryRuleGroup", "id": "e2222222-2222-2222-2222-222222222222",
    "collapsed": false, "ignored": false, "not": false, "name": "", "operator": "And",
    "rules": [
      {"typeName": "UdmQueryRule", "id": "e3333333-3333-3333-3333-333333333333", "ignored": false, "not": false, "operator": "Equals", "propertyIdentifier": "UserMfaEnabled", "values": [false]}
    ]
  }
}
```

## Check 2 — Third-party identities with sensitive-data access

`udm_execute_query` with `skip: 0`, `take: 100` (page if `hasMore`). Select
`EntityAttributes` to show which sensitive categories and risk flags apply.

```json
{
  "typeName": "UdmQuery",
  "id": "f1111111-1111-1111-1111-111111111111",
  "objectTypeName": "IIdentity",
  "collapsed": false, "objectResultHidden": false, "groupProperties": null, "timeZoneId": null, "joins": [],
  "properties": [
    {"identifier": "EntityName", "queryId": "f1111111-1111-1111-1111-111111111111", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "EntityTypeName", "queryId": "f1111111-1111-1111-1111-111111111111", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "PrincipalMail", "queryId": "f1111111-1111-1111-1111-111111111111", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "EntityTenant", "queryId": "f1111111-1111-1111-1111-111111111111", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "EntityAttributes", "queryId": "f1111111-1111-1111-1111-111111111111", "sort": null, "startOfWeek": null, "transform": null}
  ],
  "ruleGroup": {
    "typeName": "UdmQueryRuleGroup", "id": "f2222222-2222-2222-2222-222222222222",
    "collapsed": false, "ignored": false, "not": false, "name": "", "operator": "And",
    "rules": [
      {"typeName": "UdmQueryRule", "id": "f3333333-3333-3333-3333-333333333333", "ignored": false, "not": false, "operator": "In", "propertyIdentifier": "EntityAttributes", "values": ["VendorServiceIdentityAttribute", "AadDirectoryUserExternalAttribute", "AadDirectoryUserGuestAttribute"]},
      {"typeName": "UdmQueryRule", "id": "f4444444-4444-4444-4444-444444444444", "ignored": false, "not": false, "operator": "In", "propertyIdentifier": "EntityAttributes", "values": ["SensitiveResourcePermissionActionPrincipalAttribute", "ApplicationPciDataResourcePermissionActionPrincipalAttribute", "ApplicationPhiDataResourcePermissionActionPrincipalAttribute", "ApplicationPiiDataResourcePermissionActionPrincipalAttribute", "ApplicationSecretsDataResourcePermissionActionPrincipalAttribute"]}
    ]
  }
}
```

## Check 3 — Publicly exposed resources (+ endpoint flag)

Total: `udm_get_query_results_count` on `IEntity` with rule
`AccessEntityInboundAccessAccessLevel In ["Public"]`.
Flagged subset: add a second rule `EntityNetworkAccessType In ["ExternalDirect","ExternalIndirect"]`.
List query (`skip: 0`, `take: 100`, page as needed) — select the endpoint property to
set the flag per row:

```json
{
  "typeName": "UdmQuery",
  "id": "11111111-aaaa-1111-1111-111111111111",
  "objectTypeName": "IEntity",
  "collapsed": false, "objectResultHidden": false, "groupProperties": null, "timeZoneId": null, "joins": [],
  "properties": [
    {"identifier": "EntityName", "queryId": "11111111-aaaa-1111-1111-111111111111", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "EntityTypeName", "queryId": "11111111-aaaa-1111-1111-111111111111", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "EntityTenant", "queryId": "11111111-aaaa-1111-1111-111111111111", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "EntityNetworkAccessType", "queryId": "11111111-aaaa-1111-1111-111111111111", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "NetworkDynamicAnalysisResourceNetworkEndpoints", "queryId": "11111111-aaaa-1111-1111-111111111111", "sort": null, "startOfWeek": null, "transform": null}
  ],
  "ruleGroup": {
    "typeName": "UdmQueryRuleGroup", "id": "11111111-aaaa-2222-1111-111111111111",
    "collapsed": false, "ignored": false, "not": false, "name": "", "operator": "And",
    "rules": [
      {"typeName": "UdmQueryRule", "id": "11111111-aaaa-3333-1111-111111111111", "ignored": false, "not": false, "operator": "In", "propertyIdentifier": "AccessEntityInboundAccessAccessLevel", "values": ["Public"]}
    ]
  }
}
```

Flag rule: **Network endpoint identified = Yes** when `EntityNetworkAccessType` is
`ExternalDirect`/`ExternalIndirect` (or the row has a non-empty
`NetworkDynamicAnalysisResourceNetworkEndpoints`), else No.

## Check 4 — Exposed secrets (+ endpoint flag)

Total: `udm_get_query_results_count` on `IDataEntity` with rule
`DataEntityDataTypeCategories In ["Secrets"]`.
Flagged subset: add a second rule `AccessEntityInboundAccessAccessLevel In ["External","Public"]`.
List query (`skip: 0`, `take: 100`, page as needed):

```json
{
  "typeName": "UdmQuery",
  "id": "22222222-bbbb-1111-1111-111111111111",
  "objectTypeName": "IDataEntity",
  "collapsed": false, "objectResultHidden": false, "groupProperties": null, "timeZoneId": null, "joins": [],
  "properties": [
    {"identifier": "EntityName", "queryId": "22222222-bbbb-1111-1111-111111111111", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "EntityTypeName", "queryId": "22222222-bbbb-1111-1111-111111111111", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "EntityTenant", "queryId": "22222222-bbbb-1111-1111-111111111111", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "DataEntityDataTypeSensitivities", "queryId": "22222222-bbbb-1111-1111-111111111111", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "AccessEntityInboundAccessAccessLevel", "queryId": "22222222-bbbb-1111-1111-111111111111", "sort": null, "startOfWeek": null, "transform": null}
  ],
  "ruleGroup": {
    "typeName": "UdmQueryRuleGroup", "id": "22222222-bbbb-2222-1111-111111111111",
    "collapsed": false, "ignored": false, "not": false, "name": "", "operator": "And",
    "rules": [
      {"typeName": "UdmQueryRule", "id": "22222222-bbbb-3333-1111-111111111111", "ignored": false, "not": false, "operator": "In", "propertyIdentifier": "DataEntityDataTypeCategories", "values": ["Secrets"]}
    ]
  }
}
```

Flag rule: **Network endpoint identified = Yes** when
`AccessEntityInboundAccessAccessLevel` is `External`/`Public`, else No. (`IDataEntity`
does not expose `NetworkDynamicAnalysisResourceNetworkEndpoints`.)

---

## Check 5 — Inactive identities

Total: `udm_get_query_results_count` on `IIdentity` with rule
`PrincipalInactive Equals true`. List (`skip`/`take`, page as needed):

```json
{
  "typeName": "UdmQuery", "id": "a0000000-0000-0000-0000-000000000001", "objectTypeName": "IIdentity",
  "collapsed": false, "objectResultHidden": false, "groupProperties": null, "timeZoneId": null, "joins": [],
  "properties": [
    {"identifier": "EntityName", "queryId": "a0000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "EntityTypeName", "queryId": "a0000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "EntityTenant", "queryId": "a0000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null}
  ],
  "ruleGroup": {"typeName": "UdmQueryRuleGroup", "id": "a0000000-0000-0000-0000-000000000002", "collapsed": false, "ignored": false, "not": false, "name": "", "operator": "And",
    "rules": [{"typeName": "UdmQueryRule", "id": "a0000000-0000-0000-0000-000000000003", "ignored": false, "not": false, "operator": "Equals", "propertyIdentifier": "PrincipalInactive", "values": [true]}]}}
```

The result is usually large and dominated by directory users — prioritize inactive
identities that are also privileged or carry sensitive-data access (cross-ref Check 2).

## Check 6 — Unused credentials

`AwsIamUser` that are inactive yet still have an enabled access key. Total via
`udm_get_query_results_count` with the same rule group.

```json
{
  "typeName": "UdmQuery", "id": "b0000000-0000-0000-0000-000000000001", "objectTypeName": "AwsIamUser",
  "collapsed": false, "objectResultHidden": false, "groupProperties": null, "timeZoneId": null, "joins": [],
  "properties": [
    {"identifier": "EntityName", "queryId": "b0000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "AwsEntityArn", "queryId": "b0000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "AwsEntityTenant", "queryId": "b0000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "AwsIamUserPasswordEnabled", "queryId": "b0000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null}
  ],
  "ruleGroup": {"typeName": "UdmQueryRuleGroup", "id": "b0000000-0000-0000-0000-000000000002", "collapsed": false, "ignored": false, "not": false, "name": "", "operator": "And",
    "rules": [
      {"typeName": "UdmQueryRule", "id": "b0000000-0000-0000-0000-000000000003", "ignored": false, "not": false, "operator": "Equals", "propertyIdentifier": "PrincipalInactive", "values": [true]},
      {"typeName": "UdmQueryRule", "id": "b0000000-0000-0000-0000-000000000004", "ignored": false, "not": false, "operator": "In", "propertyIdentifier": "EntityAttributes", "values": ["AwsAccessKeyEnabledUserAttribute"]}
    ]}}
```

## Check 7 — Unused security groups

`AwsEc2SecurityGroup` with **no attached resources** — a negated relation rule on
`AwsEc2SecurityGroupResources` (empty inner rule group + `not: true`). Total via
`udm_get_query_results_count` with the same rule group.

```json
{
  "typeName": "UdmQuery", "id": "c0000000-0000-0000-0000-000000000001", "objectTypeName": "AwsEc2SecurityGroup",
  "collapsed": false, "objectResultHidden": false, "groupProperties": null, "timeZoneId": null, "joins": [],
  "properties": [
    {"identifier": "EntityName", "queryId": "c0000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "AwsEntityArn", "queryId": "c0000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "AwsEntityTenant", "queryId": "c0000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "AwsEc2SecurityGroupDefaultSecurityGroup", "queryId": "c0000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null}
  ],
  "ruleGroup": {"typeName": "UdmQueryRuleGroup", "id": "c0000000-0000-0000-0000-000000000002", "collapsed": false, "ignored": false, "not": false, "name": "", "operator": "And",
    "rules": [
      {"typeName": "UdmQueryRelationRule", "id": "c0000000-0000-0000-0000-000000000003", "ignored": false, "not": true, "relationPropertyIdentifier": "AwsEc2SecurityGroupResources",
        "ruleGroup": {"typeName": "UdmQueryRuleGroup", "id": "c0000000-0000-0000-0000-000000000004", "collapsed": false, "ignored": false, "not": false, "name": "", "operator": "And", "rules": []}}
    ]}}
```

Some results are default security groups (`AwsEc2SecurityGroupDefaultSecurityGroup = true`)
— call those out for lock-down rather than deletion.

---

## AI Risk — Step 1: Discover AI assets

`IAiResource` with no filter returns all AI assets across providers (Bedrock,
SageMaker, Azure Cognitive Services/OpenAI, GCP Vertex, etc.). Count via
`udm_get_query_results_count`.

```json
{
  "typeName": "UdmQuery", "id": "d1000000-0000-0000-0000-000000000001", "objectTypeName": "IAiResource",
  "collapsed": false, "objectResultHidden": false, "groupProperties": null, "timeZoneId": null, "joins": [],
  "properties": [
    {"identifier": "EntityTypeName", "queryId": "d1000000-0000-0000-0000-000000000001", "sort": {"direction": "Ascending", "ordinal": 0}, "startOfWeek": null, "transform": null},
    {"identifier": "EntityName", "queryId": "d1000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "EntityTenant", "queryId": "d1000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "EntityRegion", "queryId": "d1000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null}
  ],
  "ruleGroup": {"typeName": "UdmQueryRuleGroup", "id": "d1000000-0000-0000-0000-000000000002", "collapsed": false, "ignored": false, "not": false, "name": "", "operator": "And", "rules": []}}
```

## AI Risk — Step 2: Correlate AI model to training data

`AwsBedrockCustomModel` exposes the data lineage relations. Selecting them returns the
related S3 bucket references directly (no Join needed).

```json
{
  "typeName": "UdmQuery", "id": "d2000000-0000-0000-0000-000000000001", "objectTypeName": "AwsBedrockCustomModel",
  "collapsed": false, "objectResultHidden": false, "groupProperties": null, "timeZoneId": null, "joins": [],
  "properties": [
    {"identifier": "EntityName", "queryId": "d2000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "AwsEntityArn", "queryId": "d2000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "AwsEntityTenant", "queryId": "d2000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "AwsBedrockCustomModelCustomizationType", "queryId": "d2000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "AwsBedrockCustomModelSourceModelArn", "queryId": "d2000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "AwsBedrockCustomModelInputTrainingBucket", "queryId": "d2000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "AwsBedrockCustomModelInputValidationBuckets", "queryId": "d2000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "AwsBedrockCustomModelOutputBucket", "queryId": "d2000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null}
  ],
  "ruleGroup": {"typeName": "UdmQueryRuleGroup", "id": "d2000000-0000-0000-0000-000000000002", "collapsed": false, "ignored": false, "not": false, "name": "", "operator": "And", "rules": []}}
```

- `AwsBedrockCustomModelInputTrainingBucket` → **Training Input Data** (S3 bucket used to fine-tune).
- `AwsBedrockCustomModelOutputBucket` → **Output Data** (bucket storing model outputs).
- Flag when input and output are the same bucket, or when a bucket is public / holds
  sensitive data (cross-reference Checks 3 and 4).

---

## Toxic combination — public workload + critical-VPR vuln + privileged

`IVirtualMachine` requiring all three conditions. The Critical-VPR vulnerability is a
**nested** relation rule (entity → vulnerability instance → vulnerability). Count via
`udm_get_query_results_count` with the same rule group.

```json
{
  "typeName": "UdmQuery", "id": "e2000000-0000-0000-0000-000000000001", "objectTypeName": "IVirtualMachine",
  "collapsed": false, "objectResultHidden": false, "groupProperties": null, "timeZoneId": null, "joins": [],
  "properties": [
    {"identifier": "EntityName", "queryId": "e2000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "EntityTypeName", "queryId": "e2000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "EntityTenant", "queryId": "e2000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "EntityRegion", "queryId": "e2000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "EntityNetworkAccessType", "queryId": "e2000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "EntityNetworkAccessScope", "queryId": "e2000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "VirtualMachineIdentityPermissionActionSeverity", "queryId": "e2000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null},
    {"identifier": "NetworkDynamicAnalysisResourceNetworkEndpoints", "queryId": "e2000000-0000-0000-0000-000000000001", "sort": null, "startOfWeek": null, "transform": null}
  ],
  "ruleGroup": {"typeName": "UdmQueryRuleGroup", "id": "e2000000-0000-0000-0000-000000000002", "collapsed": false, "ignored": false, "not": false, "name": "", "operator": "And",
    "rules": [
      {"typeName": "UdmQueryRule", "id": "e2000000-0000-0000-0000-000000000003", "ignored": false, "not": false, "operator": "In", "propertyIdentifier": "EntityNetworkAccessType", "values": ["ExternalDirect", "ExternalIndirect"]},
      {"typeName": "UdmQueryRule", "id": "e2000000-0000-0000-0000-000000000004", "ignored": false, "not": false, "operator": "In", "propertyIdentifier": "EntityNetworkAccessScope", "values": ["Wide", "All"]},
      {"typeName": "UdmQueryRule", "id": "e2000000-0000-0000-0000-000000000005", "ignored": false, "not": false, "operator": "In", "propertyIdentifier": "VirtualMachineIdentityPermissionActionSeverity", "values": ["Critical", "High"]},
      {"typeName": "UdmQueryRelationRule", "id": "e2000000-0000-0000-0000-000000000006", "ignored": false, "not": false, "relationPropertyIdentifier": "EntityPackageVulnerabilityInstances",
        "ruleGroup": {"typeName": "UdmQueryRuleGroup", "id": "e2000000-0000-0000-0000-000000000007", "collapsed": false, "ignored": false, "not": false, "name": "", "operator": "And",
          "rules": [
            {"typeName": "UdmQueryRelationRule", "id": "e2000000-0000-0000-0000-000000000008", "ignored": false, "not": false, "relationPropertyIdentifier": "PackageVulnerabilityInstanceVulnerability",
              "ruleGroup": {"typeName": "UdmQueryRuleGroup", "id": "e2000000-0000-0000-0000-000000000009", "collapsed": false, "ignored": false, "not": false, "name": "", "operator": "And",
                "rules": [
                  {"typeName": "UdmQueryRule", "id": "e2000000-0000-0000-0000-00000000000a", "ignored": false, "not": false, "operator": "In", "propertyIdentifier": "VulnerabilityVprSeverity", "values": ["Critical"]}
                ]}}
          ]}}
    ]}}
```

- Public = `EntityNetworkAccessType` (Network Exposure) + `EntityNetworkAccessScope`
  (None/Restricted/Wide/All — use Wide/All).
- Output columns include **network exposure scope** (`EntityNetworkAccessScope`: Wide/All
  → "Wide", Restricted → "Specific IP") and **network endpoint identified**
  (`NetworkDynamicAnalysisResourceNetworkEndpoints` non-empty → Yes, else No).
- Privileged = `VirtualMachineIdentityPermissionActionSeverity` (Critical/High).
- Critical vuln = `Vulnerability.VulnerabilityVprSeverity = Critical` (VPR, not CVSS),
  reached via the nested `EntityPackageVulnerabilityInstances` →
  `PackageVulnerabilityInstanceVulnerability` relation.

---

## Property value references
- `AwsIamRootUser.UserMfaEnabled` — boolean.
- `IIdentity.EntityAttributes` (third-party): `VendorServiceIdentityAttribute`,
  `AadDirectoryUserExternalAttribute`, `AadDirectoryUserGuestAttribute`;
  (sensitive perm): `SensitiveResourcePermissionActionPrincipalAttribute`,
  `Application{Pci,Phi,Pii,Secrets}DataResourcePermissionActionPrincipalAttribute`;
  (risk flags): `MfaDisabledUserAttribute`, `InactivePrincipalAttribute`,
  `SevereExcessivePermissionActionPrincipalAttribute`.
- `IEntity.AccessEntityInboundAccessAccessLevel`: `Internal`, `TrustedExternal`,
  `CrossTenant`, `External`, `Public`.
- `IEntity.EntityNetworkAccessType`: `Internal`, `ExternalIndirect`, `ExternalDirect`.
- `IDataEntity.DataEntityDataTypeCategories`: `Pci`, `Phi`, `Pii`, `Secrets`.
- `IIdentity.PrincipalInactive` / `AwsIamUser.PrincipalInactive` — boolean (inactive).
- `AwsIamUser.EntityAttributes` (credentials): `AwsAccessKeyEnabledUserAttribute`,
  `CredentialsDisabledUserAttribute`; `AwsIamUserPasswordEnabled` — boolean.
- `AwsEc2SecurityGroup.AwsEc2SecurityGroupResources` — relation to attached resources
  (empty = unused); `AwsEc2SecurityGroupDefaultSecurityGroup` — boolean.
