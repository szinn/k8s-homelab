# Homelab Repository Context

Flux reconciles Talos Kubernetes clusters from this repo. Git is the source of truth; Flux reverts manual `kubectl` changes.

## Clusters

Two independent clusters that share no code. Confirm which one a task targets before planning or editing.

- **main**: `kubernetes/main/`
- **staging**: `kubernetes/staging/` (Proxmox VMs; a subset of main's namespaces)

## Layout (per cluster)

```text
apps/<namespace>/kustomization.yaml   # lists namespace.yaml + each <app>/install.yaml; pulls in components
apps/<namespace>/<app>/install.yaml   # Flux Kustomization(s) -> app/ (and db/ when the app has a CNPG database)
apps/<namespace>/<app>/app/           # HelmRelease, ExternalSecret, PVCs, etc.
cluster/config/cluster.yaml           # root `cluster-apps` Kustomization; patches HelmRelease defaults onto every child
components/                           # Kustomize components (app-template OCIRepository, alerts, kopiur, ...)
talos/                                # Talos machine config (*.j2) + mod.just
bootstrap/                            # helmfile.d + resources.yaml.j2
```

A new app has to be added to its namespace's `kustomization.yaml` `resources:`, or Flux won't deploy it.

## Conventions

- **Charts**: apps use bjw-s `app-template` through `chartRef: {kind: OCIRepository, name: app-template}`. Vendor charts are the exception.
- **Routing**: use app-template's `route:` (Gateway API), not Ingress. Gateways are `envoy-internal` and `envoy-external` in namespace `network`.
- **Hostnames**: real domains are hardcoded. There is no `${SECRET_DOMAIN}` substitution.
- **Secrets**: an `ExternalSecret` reads from the ClusterSecretStore `onepassword-connect` (1Password). SOPS files end in `.sops.yaml` and are encrypted before commit.
- **Storage classes**: `ceph-block`, `ceph-filesystem`, `miroir-slow`, `openebs-hostpath`, plus per-app NFS classes.
- **Image tags**: write plain version tags and don't add `@sha256:` digests yourself. Renovate pins digests on many images; leave existing ones in place.
- **Jinja2**: only the `talos/` and `bootstrap/` `.j2` files are templates (minijinja, standard `{{ }}`, variables from the environment). Everything under `apps/` is plain YAML.

## Commands

| Task | Command |
| --- | --- |
| Validate | `task kubernetes:kubeconform cluster=<main\|staging>` |
| Force sync | `task flux:sync cluster=<main\|staging>` |
| Talos/bootstrap recipes | `just <main\|staging> <recipe>` (sets KUBECONFIG/TALOSCONFIG) |
| kubectl/flux | pass `--context main` or `--context staging` |

## Insights

This project uses `.insights/` for research, triage docs, specs, plans, and personal notes
managed by the `insights` CLI.

**At the start of brainstorming, spec writing, or planning work**, use the
`issueboss:insights-research` skill to check for prior context before proceeding. It
finds and reads the relevant documents and returns the findings inline.

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
