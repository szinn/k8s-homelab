# Homelab Repository Context

GitOps-managed Kubernetes homelab using Flux and Talos.

## Documentation

@docs/ai-context/README.md

The rest of `docs/ai-context/` is read on demand - open the file that matches the task.

### System Context

- `docs/ai-context/ARCHITECTURE.md` - Architecture, capsules, patterns
- `docs/ai-context/NETWORKING.md` - Traffic flows, DNS, gateways, OIDC
- `docs/ai-context/DOMAIN.md` - Rules, state machines, glossary
- `docs/ai-context/WORKFLOWS.md` - How to deploy, update, troubleshoot
- `docs/ai-context/TOOLS.md` - MCP servers, CLI commands
- `docs/ai-context/CONVENTIONS.md` - Naming, structure, style

### Writing Guides

Read these before writing or editing anything in `docs/ai-context/`.

- `docs/ai-context/Ethos.md` - Hard rules, guidance, values
- `docs/ai-context/PLANNING.md` - Collaborative planning lifecycle
- `docs/ai-context/writing-documentation.md` - Wisdom triggers
- `docs/ai-context/writing-capsules.md` - Capsule format
- `docs/ai-context/mermaid-diagram-guide.md` - Diagram rules

## Critical Invariants

### Clusters: Location of Source

There are two independent clusters:

main: root of the main cluster is `kubernetes/main`
staging: root of the staging cluster is `kubernetes/staging`

The clusters do not share code. When making changes, it is important
to know which cluster is being worked on. Make sure to know this in advance
of any planning or changes.

### Capsule: GitOpsReconciliation

**Invariant**: Cluster state converges to match Git; Flux reverts manual changes.

### Capsule: AppTemplateChart

**Invariant**: Apps use `bjw-s/app-template` chart; vendor charts are exceptions.

## Quick Reference

| Task         | Command                                         |
| ------------ | ----------------------------------------------- |
| Validate     | `task kubernetes:kubeconform cluster=main` (or `staging`) |
| Check status | `flux get helmreleases -A`                      |
| Force sync   | `task flux:sync cluster=main` (or `staging`)    |
| Find apps    | `ls kubernetes/<cluster>/apps/<namespace>/`     |

## Directory Structure

```
kubernetes/<cluster>/apps/          # Static app manifests - edit directly
kubernetes/<cluster>/talos/**/*.j2  # Jinja2 sources for Talos node configs
kubernetes/<cluster>/bootstrap/     # resources.yaml.j2 + helmfile.d for bootstrap
```

## Non-Obvious Truths

- **Jinja2 scope**: only the Talos and bootstrap `.j2` files are templates (minijinja, standard `{{ }}`/`{% %}`, variables from the environment); app manifests are plain YAML
- **Gateway API routing**: Use `route` not `ingress` for main traffic
- **Image tags**: Use plain version tags; don't add `@sha256:` digests to new or changed tags
- **SOPS files**: End in `.sops.yaml`, encrypted before commit

## Insights

This project uses `.insights/` for research, triage docs, specs, plans, and personal notes
managed by the `insights` CLI.

**At the start of brainstorming, spec writing, or planning work**, dispatch the
`insights-locator` agent to check for prior context before proceeding. Use
`insights-analyzer` to read the most relevant documents. Use the `insights-research`
skill to orchestrate both and save a research document.

Directory layout:

- `.insights/issues/` — triage documents (IB-XX-triage-*.md)
- `.insights/shared/specs/` — specs (IB-XX-spec-*.md)
- `.insights/shared/plans/` — plans (IB-XX-plan-*.md)
- `.insights/shared/research/` — research documents
- `.insights/scotte/` — personal notes
- `.insights/searchable/` — hardlink mirror for grep/search (read-only; strip "searchable/"
  from any path before reporting or editing)

All `.insights/` artifact files must include YAML front-matter.
See `.insights/shared/schema.md` for the full schema and vocabulary.
