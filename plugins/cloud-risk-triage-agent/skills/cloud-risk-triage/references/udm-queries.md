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
