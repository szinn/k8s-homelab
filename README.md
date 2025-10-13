<div align="center">

<img src="https://raw.githubusercontent.com/szinn/k8s-homelab/main/docs/assets/logo.png" align="center" width="144px" height="144px"/>

<!-- markdownlint-disable no-trailing-punctuation -->

### My home operations repository :octocat:

_... managed with Flux, Renovate and GitHub_ 🤖

</div>

<div align="center">

[![Talos](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.zinn.ca%2Ftalos_version&style=for-the-badge&logo=talos&logoColor=white&color=blue&label=%20)](https://talos.dev)&nbsp;&nbsp;
[![Kubernetes](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.zinn.ca%2Fkubernetes_version&style=for-the-badge&logo=kubernetes&logoColor=white&color=blue&label=%20)](https://kubernetes.io)&nbsp;&nbsp;
[![Flux](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.zinn.ca%2Fflux_version&style=for-the-badge&logo=flux&logoColor=white&color=blue&label=%20)](https://fluxcd.io)&nbsp;&nbsp;
[![Renovate](https://img.shields.io/github/actions/workflow/status/szinn/k8s-homelab/renovate.yaml?branch=main&label=&logo=renovatebot&style=for-the-badge&color=blue)](https://github.com/szinn/k8s-homelab/actions/workflows/renovate.yaml)

</div>

<div align="center">

[![Age-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.zinn.ca%2Fcluster_age_days&style=flat-square&label=Age)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![Uptime-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.zinn.ca%2Fcluster_uptime_days&style=flat-square&label=Uptime)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![Node-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.zinn.ca%2Fcluster_node_count&style=flat-square&label=Nodes)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![Pod-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.zinn.ca%2Fcluster_pod_count&style=flat-square&label=Pods)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![CPU-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.zinn.ca%2Fcluster_cpu_usage&style=flat-square&label=CPU)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![Memory-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.zinn.ca%2Fcluster_memory_usage&style=flat-square&label=Memory)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![Power-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.zinn.ca%2Fcluster_power_usage&style=flat-square&label=Power)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;

</div>

---

## Overview

This is my mono repo for my home infrastructure. It's based loosely on the template at [onedr0p/flux-cluster-template](https://github.com/onedr0p/flux-cluster-template) as well as many of the exemplar repos, searchable via [https://nanne.dev/k8s-at-home-search](https://nanne.dev/k8s-at-home-search/).

It follows the concept of Infrastructure as Code and by using tools such [Flux](https://github.com/fluxcd/flux2),
[Renovate](https://github.com/renovatebot/renovate),
[go-task](https://github.com/go-task/task) and shell scripts, creates a reproducible, mostly self-managing implementation.

My original implementation was running on the Ryzen using custom shell scripts and 35+ docker containers managed by hand. Any upgrades, system resets, etc, all had to be manually resolved.
It mostly ran just fine. Applying the principle "If it ain't broke, it isn't complicated enough" led me to add machines, memory, functionality to achieve a much more automated, self-managing cluster. Plus I have learned a lot!

At the bottom of this page, is the bringup process that I follow for this cluster. I recommend reading top-to-bottom to understand the cluster structure which will help understand what's needed for the bringup.

---

## Hardware

My HomeLab consists of a bunch of machines and Ubiquity networking.

| Device                                             | Count | OS Disk Size | Data Disk Size        | RAM  | Operating System          |
| -------------------------------------------------- | ----- | ------------ | --------------------- | ---- | ------------------------- |
| Ryzen 3900 12c24t NAS server                       | 1     | 1TB          | 1TB NVME, 6x16Tb SATA | 64GB | TrueNAS Scale - Ragnar    |
| Raspberry Pi                                       | 1     |              |                       |      | OctoPrint                 |
| Raspberry Pi 4B                                    | 1     |              |                       |      | Artemis - AdGuardHome DNS |
| Raspberry Pi 5                                     | 1     |              |                       |      | Raspberry PiOS            |
| TESmart 16-port HDMI Switch                        | 1     |              |                       |      |                           |
| PiKVM                                              | 1     |              |                       |      |                           |
| Intel NUC11PAHi7 (worker nodes)                    | 3     | 500GB SSD    | 1TB NVMe              | 64GB | Talos                     |
| Beelink MiniPC, Celeron J4125 (controlplane nodes) | 3     | 256GB SSD    |                       | 8GB  | Talos                     |
| Synology 1019+ (NFS server)                        | 1     |              | 5x12TB SATA           |      |                           |
| UniFi UDM SE                                       | 1     |              |                       |      |                           |
| USW-Pro-24-PoE                                     | 1     |              |                       |      |                           |
| USW-Aggregation                                    | 1     |              |                       |      |                           |
| USW-Enterprise-8-PoE                               | 2     |              |                       |      |                           |
| USW-Flex XG                                        | 1     |              |                       |      | Desktop Hub               |
| USW-Flex                                           | 1     |              |                       |      | Outside Camera Hub        |
| UNVR                                               | 1     |              | 3x4TB SATA            |      |                           |
| USP-PDU Pro                                        | 2     |              |                       |      |                           |
| 6-port NUC                                         | 1     | 512GB SSD    |                       | 32GB | Fedora, AdGuardHome DNS   |
| Intel NUC11TNHi7                                   | 1     | 1Tb          |                       | 64GB | Proxmox                   |
| Intel NUC13 Pro                                    | 1     | 1Tb          |                       | 32GB | Fedora - Hera             |
| UVC G4 Doorbell                                    | 1     |              |                       |      | Front Door Camera         |
| UVC G4 Pro                                         | 3     |              |                       |      | Additional Cameras        |

The Proxmox Intel NUC runs a 3-node Talos staging cluster where I can try out various patterns before deploying in the main cluster.

The Intel NUC13 (Hera) is a spare NUC that I'm currently using as a Fedora platform with a graphical UI.

Titan used to be the VyOS router which has since gone out of favour. It now runs AdGuardHome DNS as a secondary DNS on Fedora.

Artemis runs services that need to be outside the cluster:

- DNS (AdGuard Home)
- Cloudflare DDNS
- gatus to track machine and non-cluster services

## Kubernetes

The cluster is based on [Talos](https://www.talos.dev) with 3 control-plane nodes running on the Beelink MiniPCs and 3 worker nodes running on the Intel NUCs.

### Core Components

- [kubernetes/ingress-nginx](https://github.com/kubernetes/ingress-nginx): Manages reverse-proxy access to Kubernetes services.
- [rook/rook](https://github.com/rook/rook): Distributed block storage for persistent storage.
- [jetstack/cert-manager](https://cert-manager.io/docs/): Creates SSL certificates for services in my Kubernetes cluster.
- [kubernetes-sigs/external-dns](https://github.com/kubernetes-sigs/external-dns): Automatically manages DNS records from my cluster in a cloud DNS provider.

### GitOps

[Flux](https://github.com/fluxcd/flux2) watches my [main cluster](./kubernetes/main) folder (see Directories below) and makes the changes to my cluster based on the YAML manifests.

[Renovate](https://github.com/renovatebot/renovate) watches my **entire** repository looking for dependency updates, when they are found a PR is automatically created.
When PRs are merged [Flux](https://github.com/fluxcd/flux2) applies the changes to my cluster.

Charts and images are tagged in the various YAML files to enable Renovate to watch and update them as needed.

## Network Configuration

See [diagram](./docs/Network-Backbone.png) of the backbone.

The external network is connected to the UDM SE with a [Wireguard](https://www.wireguard.com) port being the only exposed access.
This allows me to connect into the network when I'm traveling.
Inbound services are managed with cloudflared.

The main cluster and IPs are on the 10.11.x.x subnet on VLAN HOMELAB.
The stagint cluster and IPs are on the 10.12.x.x subnet on VLAN STAGING.
External machines (Synology, etc) are SERVERS VLAN subnet. IoT devices are on an isolated IoT VLAN.
They cannot reach the other VLANs directly but will answer when spoken to.

DNS is managed by CoreDNS in the cluster which then forwards unresolved requests to DNS running on the Titan server.
Titan will forward accepted addresses onto the UDM-SE for resolution.

The external DNS is managed via [Cloudflare](https://www.cloudflare.com/en-ca/).
External names are managed by [external-dns](https://github.com/kubernetes-sigs/external-dns) on the cluster and, since my home IP can be changed at any time, DDNS is maintained by the
[oznu/cloudflare-ddns](https://hub.docker.com/r/oznu/cloudflare-ddns/) docker image. Certificates are managed through CloudFlare as well using cert-manager and the DNS01 challenge protocol.

## Repository Structure

The repository supports multiple clusters -- in particular, I have a "main" cluster which runs on the above hardware. I previously had a staging cluster that could use the same source, but have since
moved that to a separate repo.

Adding something new to the cluster usually requires a lot of trial and error initially. When I am trying something out, I will work in a staging environment as much as possible and then move to the main cluster.
If additional iterations are required, I will usually try and do amended commits rather than a chain of commits with comments such as "Trying again" or "Maybe this will work", etc.

The repository directories are:

- **.github**: GitHub support files and renovate configuration.
- **.taskfiles**: Auxiliary files used for the task command-line tool.
- **kubernetes**: The clusters themselves.
  - **main**: The main cluster
    - **apps**: The applications to load.
    - **bootstrap**: The initial code loaded on the cluster to bootstrap it.
    - **flux**: The definition of the cluster.
      - **cluster**: The configuration of the cluster to use flux.
  - **repositories**: Sources of code for the cluster.
  - **staging**: The staging cluster that follows the same structure as the main cluster.
- **hack**: Miscellaneous stuff that really has nothing to do with managing the cluster.

### Environment Setup

Install pre-commit with

```shell
pre-commit install --install-hooks
```

And update the hooks occasionally with (they should auto-update themselves though)

```shell
pre-commit auto-update
```

## Cluster Configuration

### External Environment Configuration

All values are defined as shell environment variables.

### Application Secrets

Application secrets are maintained by using [external-secrets](https://external-secrets.io).

## Persistent Volume Management

Applications usually require data to work well. Persistent volumes on the cluster are stored in two places - Rook/Ceph and an external NFS.

### Rook/Ceph

Each worker has a 1Tb NVMe drive that is managed with Rook/Ceph. The data stored here is replicated across the multiple workers so it will be fast and available locally.

### NFS

I'm still experimenting with NAS storage with regards to the cluster. Most of my home data is stored on the NAS drive, but file-level permission management has been a bit of a pain.

Applications that don't require fast access to data or only use it for temporary storage (e.g., a download directory) will store the data in NFS.
The NFS drives are available across the cluster but are at a slower speed than the Rook/Ceph storage.

### Data Backup and Recovery

Currently, I use a combination of built-in application backups (e.g., \*arr applications will backup weekly),
a backup job in cluster that will backup databases (mysql and postgres),
I am also using volsync to backup the PVCs to NFS that will automatically restore the most recent backup (if it exists) .

## Installation

The initial bootstrap relies on some configuration, including secrets stored in 1Password such as:

- 1Password credentials required for access by external-secrets
- TLS keys that pre-seed the certificates to prevent hammering on lets-encrypt.

### Cluster Bringup

The initial bootstrap of the cluster is launched by the task `bootstrap:main` or `bootstrap:staging` which apply the initial configuration
in the `{{cluster}}/bootstrap` directories.

### Adding a New Package / Updating Configuration

Adding a new package is simply done by following the patterns of an existing, similar package and pushing the commit to GitHub.
Flux will then notice the change and apply it.

### Ongoing Maintenance

Maintenance of the cluster is fairly minimal.

- renovate creates PRs to update helm charts, flux system files, or docker images in the cluster;
- flux applies any merged PRs or changes to the repo to the cluster automatically.

Through Wireguard and [Kubenav](https://kubenav.io), I can pretty much manage the cluster remotely from my phone.
On my desktop/laptop, I use [Lens](https://k8slens.dev) and `k9s` to manage the cluster which works remotely through Wireguard as well.

## Gratitude and Thanks

Many thanks to the folks at [k8s-at-home](https://github.com/k8s-at-home) that maintain the many great Helm charts, have opened their own repos for the rest of us to learn, and answer many questions on the discord server.
A special thanks to Devin (@onedr0p) who's cluster I modelled mine after.
Another special thanks to Nat (@Truxnell) who answered a bunch of my questions about Talos while I was on vacation reading github repos and docs on my iPhone.
A tongue-in-cheek thanks to Jeff (@billimek) who's dang YouTube video on Home Assistant and his cluster repo led me into this rabbit hole.
