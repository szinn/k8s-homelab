---
description: Documentation philosophy, hard rules, and values for k8s-homelab AI context
tags: ["Philosophy", "Documentation", "Ethos", "Principles"]
audience: ["LLMs", "Humans"]
categories: ["Meta[100%]", "Guidance[95%]"]
---

# Ethos: Documentation Philosophy and Principles

**Purpose**: The values, principles, and rules that guide what we capture in this knowledge base.

**Audience**: AI agents and humans contributing to repository documentation.

---

## The Philosophy

This knowledge base exists to answer: **"How does this dual-cluster homelab infrastructure work as a coherent whole?"**

Not "how do I use kubectl?" or "what's the Helm chart syntax?" - those belong in external docs. This is the **context layer** that explains why the system is designed this way, how components relate, and what invariants must be preserved.

**After 10-15 minutes reading**, you should understand:

1. **What it does** - GitOps-managed dual Kubernetes clusters (main + staging)
2. **How it does it** - Taskfile + Jinja2 + Flux + Talos
3. **What must stay true** - Invariants and constraints
4. **How to find more** - Pointers to specific manifests and configs

**This is not classical documentation.** Classical docs explain how to use a tool. This explains how tools work together to manage infrastructure declaratively across two independent clusters.

---

## The Hard Rules (Never Violate)

These are non-negotiable. Violating them undermines the entire knowledge base.

### Rule 1: Only Record What You Can Verify

**Why**: Wrong information is worse than missing information.

**Hierarchy of evidence** (prefer higher levels):

1. **Code** - Directly observed in manifests, Taskfile, scripts
2. **Documentation** - Stated in existing docs or READMEs
3. **Synthesis** - Derived from multiple verified sources
4. **User** - Confirmed by the operator
5. **Intuition** - Inferred from patterns (mark as low confidence)

**Evidence table format**:

```markdown
| Claim                    | Source                               | Confidence |
| ------------------------ | ------------------------------------ | ---------- |
| Flux reconciles every 1h | kubernetes/main/apps/\*/install.yaml | Verified   |
```

### Rule 2: When in Doubt, Omit

**Why**: Missing information prompts questions. Wrong information causes failed deployments and wasted debugging.

Better to say "see the HelmRelease for details" than guess incorrectly.

**The cost calculation**:

- **Wrong information** - Incorrect manifests, broken deployments, hours of debugging
- **Missing information** - Extra research time, asking for clarification

Missing is recoverable. Wrong is destructive.

### Rule 3: Never Use Actual Domain Names or Secrets

**Why**: This is a public repository. Actual values leak information and create security exposure.

**Always use placeholders**:

- `${SECRET_DOMAIN}` - The primary domain (in hostnames, URLs, DNS records)
- `${SECRET_*}` - Any other sensitive values from 1Password
- `<REDACTED>` - When showing example values in documentation

**In documentation**:

- Write `app.${SECRET_DOMAIN}` not the actual URL
- Write `id.${SECRET_DOMAIN}` not the actual identity provider URL
- Use "DOMAIN" in ASCII diagrams where variable syntax breaks formatting

**The test**: Grep for known secrets should return zero results in docs.

### Rule 4: Always Specify Which Cluster

**Why**: This repo manages TWO independent clusters that don't share code.

**Critical distinction**:

- **Main cluster**: `kubernetes/main/` - Production workloads on physical hardware
- **Staging cluster**: `kubernetes/staging/` - Testing workloads on Proxmox

**When documenting**:

- Always specify "main cluster" or "staging cluster" or "both clusters"
- Never say "the cluster" - which one?
- File paths must include `kubernetes/main/` or `kubernetes/staging/`

**Example**:

- ✅ "Home Assistant runs in the `home` namespace on the main cluster"
- ❌ "Home Assistant runs in the `home` namespace"

---

## Strong Guidance (Follow Unless You Have Good Reason)

These patterns create durable, useful documentation. Deviation should be intentional and justified.

### Capture Temporally Stable Information

**Prefer documenting**:

- Architectural patterns (GitOps, Flux reconciliation, Talos immutability)
- Infrastructure constraints (SOPS encryption, 1Password integration, storage requirements)
- Operational invariants (task configure before commit, never edit generated files)
- Critical dependencies (Flux depends on secrets, pods depend on PVCs)
- Multi-cluster relationships (how main/staging differ, what they share)

**Avoid documenting**:

- Specific versions ("Flux 2.3.0") - unless they create understanding
- Point-in-time info ("recently added", "planned upgrade")
- Configuration values (belong in manifests)
- Step-by-step tutorials (belong in external docs)
- Exact counts ("47 HelmReleases") - unless critical to understanding

**The test**: Will this still be true in 6 months? If not, consider omitting unless it substantially aids understanding.

### Document Shape, Not Detail

**Good**: "Each app follows the install.yaml + HelmRelease + ExternalSecret triad"

**Bad**: "The immich app has env vars IMMICH_DB_HOST, IMMICH_DB_PORT, IMMICH_DB_NAME..."

**Why**: Implementation details change. The conceptual structure persists.

### Focus on Why, Not Just What

**Good**: "Secrets use 1Password because the repo is public and values must not be committed"

**Bad**: "Add ExternalSecret with onepassword-connect store reference"

**Why**: The "why" teaches the principle. The "what" becomes obvious once you understand why.

### Document Patterns, Not Instances

**Good**: "HelmReleases define persistence sections with existingClaim, tmpfs, or NFS mounts"

**Bad**: "immich uses immich-data claim, plex uses plex-data claim, sonarr uses..."

**Why**: Patterns are durable. Instance lists go stale and create maintenance burden.

### Provide Trails, Not Destinations

**Good**: "For storage configuration, see kubernetes/main/apps/media/immich/app/helmrelease.yaml:89-120"

**Bad**: Duplicating the entire persistence section here

**Why**: This knowledge base points to specific locations; it doesn't replace reading the actual configs.

---

## The Values (These Guide Our Choices)

### We Value Context Over Completeness

Every component must answer: **"Where does this fit in the wider system?"**

Required context:

- What layer? (Flux, Talos, app, infrastructure)
- Which cluster? (main, staging, both)
- What depends on this? (blast radius)
- What does this depend on? (prerequisites)
- What breaks if this changes?

### We Document Non-Obvious Truths

Capture things that:

- Surprise newcomers to the system
- Waste significant time when misunderstood
- Reflect infrastructure complexity (not just tooling quirks)
- Matter in operations (not just theory)

Examples:

- Flux reverts manual kubectl changes (GitOps fundamental)
- ExternalSecrets must sync before pods can start (ordering dependency)
- Main and staging clusters don't share code (critical invariant)
- Jinja2 uses `#{var}#` delimiters not `{{var}}` (avoids Helm conflicts)

### We Create Maps, Not Transcripts

**We document the durable conceptual structure**, not the ephemeral implementation details.

**We capture why the system exists and how components relate**, then point to manifests for specifics.

**We create wisdom triggers** that activate understanding, not dumps of information.

---

## The Right Level of Abstraction

### Conceptual Understanding

**Capture**: Mental models that explain behavior across many scenarios

**Example**: "GitOps means the cluster converges to match Git state; manual changes are reverted"

### Structural Relationships

**Capture**: How components relate and depend on each other

**Example**: "Taskfile renders Jinja2 templates, Flux applies manifests, Talos manages nodes, 1Password provides secrets"

### Architectural Constraints

**Capture**: Why the system works this way, not just how

**Example**: "Two independent clusters ensure production isolation from staging experiments"

### Integration Points

**Capture**: How components connect, what protocols, what data flows

**Example**: "ExternalSecrets pull from 1Password, populate Kubernetes secrets, HelmReleases reference them via secretRef"

---

## Success Looks Like

### Quick Orientation (10-15 minutes)

- Understand what both clusters run and how they differ
- Know how deployments flow from Git to clusters
- Identify key constraints and invariants
- Find pointers to specific configs

### Confident Decision Making

- Which cluster should this app deploy to?
- Where should new apps go within a cluster?
- What are the prerequisites for a deployment?
- What invariants must be preserved?
- What breaks if I change this?

### Effective Troubleshooting

- Which components are involved in a failure?
- Where are likely failure points?
- What commands reveal state?
- How do changes flow through the system?

---

## Failure Looks Like

- **False Confidence** - Wrong information leading to broken deployments
- **Cluster Confusion** - Not specifying which cluster, causing cross-cluster mistakes
- **Analysis Paralysis** - Too much detail without clear patterns
- **Maintenance Burden** - Information that goes stale quickly
- **Knowledge Silos** - Details without context of wider system

---

## When to Break the Guidance

The strong guidance exists to create durable, useful documentation. But **if breaking it aids understanding, break it**.

**Example**: We generally avoid specific timings. But "Flux reconciles every 1 hour" substantially improves understanding of operational behavior. Keep it.

**The test**: Does this create the "aha!" moment? Does it explain why the system works this way? If yes, keep it even if it technically violates guidance.

**Remember**: The hard rules are never negotiable. The guidance is strong but not absolute. The philosophy explains why we do what we do.

---

## The Meta-Principle

**Test**: Could someone read this and make informed decisions about:

- Which cluster to deploy to?
- Where new functionality belongs?
- What the implications would be?
- How to troubleshoot failures?

If yes, the documentation succeeds.

---

**Hierarchy**:

1. **Hard Rules** - Never violate
2. **Strong Guidance** - Follow unless you have good reason
3. **Philosophy** - Understand the why behind our choices
