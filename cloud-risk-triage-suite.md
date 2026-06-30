---
name: "Cloud Risk Triage Suite"
author: "wingchurn-tenable"
github_url: "https://github.com/wingchurn-tenable/cloud-risk-triage"
description: "Autonomous four-check cloud posture sweep for Tenable Cloud Security: root MFA, 3rd-party access, exposure, secrets."
license: "MIT"
type: "agent"
tier: "unreviewed"
tags: [cloud-security, tenable, cspm, posture, soc, triage, cnapp]
framework: "Claude Code SKILL"
integrations: [Tenable Cloud Security, AWS, Azure, GCP]
date_added: 2026-06-30
---

The Cloud Risk Triage Suite is an autonomous cloud security posture agent for
Tenable Cloud Security, built for cloud security architects and SOC analysts who
want a fast, repeatable daily posture read. It runs four targeted checks against
live Tenable Cloud Security data and writes a SOC-ready report — every check is
always reported, even when it returns nothing (marked EMPTY).

It ships in two editions: an **MCP edition** that runs through the Tenable Cloud
Security (`tcs`) MCP connector for the richest results, and an **API-token edition**
that uses the public GraphQL API with a Bearer token and no connector — pick whichever
matches how you connect.

## What it does

Each run executes four posture checks and produces a summary table, one section per
check (with the requested flag columns), a remediation order, and verification notes:

1. **AWS root users without MFA**
2. **Third-party identities with access to sensitive data** — vendor / external / guest
   identities holding PCI/PHI/PII/Secrets access
3. **Publicly exposed resources** — flagged for those with an identified network endpoint
4. **Exposed secrets** — flagged for those on a network-reachable resource

It never fabricates data; every value is quoted from query results, and it flags when
data looks like a demo/test environment.

## How it works

The MCP edition queries Tenable Cloud Security's Explore / UDM data model via the
`tcs` MCP tools (`AwsIamRootUser`, `IIdentity` entity attributes, `IEntity` public
exposure + network access type, `IDataEntity` secret categories), using count queries
for totals and flagged subsets. The API-token edition calls the public GraphQL
`/graphql` endpoint with `Authorization: Bearer`, mapping each check onto Findings
policy categories. Both write a dated markdown report to the working folder and can be
scheduled to run automatically each morning.
