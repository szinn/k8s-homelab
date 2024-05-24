<div align="center">

<img src="https://raw.githubusercontent.com/szinn/k8s-homelab/main/docs/assets/logo.png" align="center" width="144px" height="144px"/>

<!-- markdownlint-disable no-trailing-punctuation -->

### My home operations repository :octocat:

_... managed with Flux, Renovate and GitHub_ 🤖

</div>

<div align="center">

[![Age-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.zinn.ca%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_age_days&style=flat-square&label=Age)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![Uptime-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.zinn.ca%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_uptime_days&style=flat-square&label=Uptime)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![Node-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.zinn.ca%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_node_count&style=flat-square&label=Nodes)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![Pod-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.zinn.ca%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_pod_count&style=flat-square&label=Pods)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![CPU-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.zinn.ca%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_cpu_usage&style=flat-square&label=CPU)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![Memory-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.zinn.ca%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_memory_usage&style=flat-square&label=Memory)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![Power-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.zinn.ca%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_power_usage&style=flat-square&label=Power)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;

</div>

---

## Overview

This is my mono repo for my home infrastructure. It's based loosely on the template at [onedr0p/flux-cluster-template](https://github.com/onedr0p/flux-cluster-template) as well as many of the exemplar repos, searchable via [https://nanne.dev/k8s-at-home-search](https://nanne.dev/k8s-at-home-search/).
It follows the concept of Infrastructure as Code and by using tools such [Flux](https://github.com/fluxcd/flux2), [Renovate](https://github.com/renovatebot/renovate), [go-task](https://github.com/go-task/task) and shell scripts, creates a reproducible, mostly self-managing implementation.

My original implementation was running on the Ryzen using custom shell scripts and 35+ docker containers managed by hand. Any upgrades, system resets, etc, all had to be manually resolved.
It mostly ran just fine. Applying the principle "If it ain't broke, it isn't complicated enough" led me to add machines, memory, functionality to achieve a much more automated, self-managing cluster. Plus I have learned a lot!

At the bottom of this page, is the bringup process that I follow for this cluster. I recommend reading top-to-bottom to understand the cluster structure which will help understand what's needed for the bringup.

---

## Hardware

| Device                                             | Count | OS Disk Size | Data Disk Size        | RAM  | Operating System     |
| -------------------------------------------------- | ----- | ------------ | --------------------- | ---- | -------------------- |
| Ryzen 3900 12c24t NAS server                       | 1     | 1TB          | 1TB NVME, 6x16Tb SATA | 64GB | NixOS 23.11 - Ragnar |
| Raspberry Pi                                       | 1     |              |                       |      | OctoPrint            |
| Raspberry Pi 4B                                    | 1     |              |                       |      | BirdNet              |
| Raspberry Pi 5                                     | 1     |              |                       |      | Raspberry PiOS       |
| TESmart 16-port HDMI Switch                        | 1     |              |                       |      |                      |
| PiKVM                                              | 1     |              |                       |      |                      |
| Intel NUC11PAHi7 (worker nodes)                    | 3     | 500GB SSD    | 1TB NVMe              | 64GB | Talos                |
| Beelink MiniPC, Celeron J4125 (controlplane nodes) | 3     | 256GB SSD    |                       | 8GB  | Talos                |
| Synology 1019+ (NFS server)                        | 1     |              | 5x12TB SATA           |      |                      |
| UniFi UDM SE                                       | 1     |              |                       |      |                      |
| USW-Pro-24-PoE                                     | 1     |              |                       |      |                      |
| USW-Aggregation                                    |       |              |                       |      |                      |
| USW-Enterprise-8-PoE                               | 2     |              |                       |      |                      |
| USW-Flex XG                                        | 1     |              |                       |      | Desktop Hub          |
| USW-Flex                                           | 1     |              |                       |      | Outside Camera Hub   |
| UNVR                                               | 1     |              | 3x4TB SATA            |      |                      |
| USP-PDU Pro                                        | 2     |              |                       |      |                      |
| 6-port NUC                                         | 1     | 512GB SSD    |                       | 32GB | NixOS - Titan        |
| Intel NUC11TNHi7                                   | 1     | 1Tb          |                       | 64GB | Proxmox              |
| Intel NUC13 Pro                                    | 1     | 1Tb          |                       | 32GB | NixOS - Hera         |
| UVC G4 Doorbell                                    | 1     |              |                       |      | Front Door Camera    |
| UVC G4 Pro                                         | 3     |              |                       |      | Additional Cameras   |

The Proxmox Intel NUC runs a 6-node Talos staging cluster where I can try out various patterns before deploying in the main cluster.

The Intel NUC13 (Hera) is a spare NUC that I'm currently using as a NixOS platform with a graphical UI.

Titan used to be the VyOS router which has since gone out of favour. It now runs critical services that used to run on the VyOS router including:

- DNS (dnsdist, bind, blocky)
- ntpd (chrony)
- onepassword-connect

## Kubernetes

The cluster is based on [Talos](https://www.talos.dev) with 3 control-plane nodes running on the Beelink MiniPCs and 3 worker nodes running on the Intel NUCs.

### Core Components

- [mozilla/sops](https://toolkit.fluxcd.io/guides/mozilla-sops/): Manages secrets for Kubernetes.
- [kubernetes/ingress-nginx](https://github.com/kubernetes/ingress-nginx): Manages reverse-proxy access to Kubernetes services.
- [rook/rook](https://github.com/rook/rook): Distributed block storage for persistent storage.
- [jetstack/cert-manager](https://cert-manager.io/docs/): Creates SSL certificates for services in my Kubernetes cluster.
- [kubernetes-sigs/external-dns](https://github.com/kubernetes-sigs/external-dns): Automatically manages DNS records from my cluster in a cloud DNS provider.

### GitOps

[Flux](https://github.com/fluxcd/flux2) watches my [cluster](./kubernetes/) folder (see Directories below) and makes the changes to my cluster based on the YAML manifests.

[Renovate](https://github.com/renovatebot/renovate) watches my **entire** repository looking for dependency updates, when they are found a PR is automatically created.
When PRs are merged [Flux](https://github.com/fluxcd/flux2) applies the changes to my cluster.

Charts and images are tagged in the various YAML files to enable Renovate to watch and update them as needed.

## Network Configuration

See [diagram](./docs/Network-Backbone.png) of the backbone.

The external network is connected to the UDM SE with a [Wireguard](https://www.wireguard.com) port forwarded to the router VM. Inbound services are managed with cloudflared.

The 3 worker nodes and Ryzen server are connected to the 8-port switch with 2.5Gb ethernet. The Unifi components are connected with 10Gb ethernet connections.
Multiple wired access points are scattered around the house and backyard.

The Kubernetes cluster and IPs are on the 10.11.0.x subnet with VLAN tagging.
External machines (Synology, etc) are on the main household VLAN subnet. IoT devices are on an isolated 191.168.1.x VLAN. They cannot reach the other VLANs directly but will answer when spoken to.

Cilium works with the router using BGP to route external IPs to Kubernetes services(e.g., MySQL). Ingress-nginx is used to reverse-proxy services within the cluster.

DNS is managed by CoreDNS in the cluster which then forwards unresolved requests to DNSdist running on the Titan server that will forward to either bind (for local home traffic) or
Blocky for ad blocking for external traffic.

The external DNS is managed via [Cloudflare](https://www.cloudflare.com/en-ca/).
External names are managed by [external-dns](https://github.com/kubernetes-sigs/external-dns) on the cluster and, since my home IP can be changed at any time, DDNS is maintained by the
[oznu/cloudflare-ddns](https://hub.docker.com/r/oznu/cloudflare-ddns/) docker image. Certificates are managed through CloudFlare as well using cert-manager and the DNS01 challenge protocol.

Any services that are exposed externally use [Authelia](https://www.authelia.com) for access authentication via a ingress-nginx.

## Repository Structure

The repository supports multiple clusters -- in particular, I have a "main" cluster which runs on the above hardware. I previously had a staging cluster that could use the same source, but have since
moved that to a separate repo.

Adding something new to the cluster usually requires a lot of trial and error initially. When I am trying something out, I will work in a staging environment as much as possible and then move to the main cluster.
If additional iterations are required, I will usually try and do amended commits rather than a chain of commits with comments such as "Trying again" or "Maybe this will work", etc.

The repository directories are:

- **.github**: GitHub support files and renovate configuration.
- **.taskfiles**: Auxiliary files used for the task command-line tool.
- **infrastructure**: Code to manage the infrastructure of the cluster.
  - **setup**: Scripts to configure and create the cluster.
  - **talos**: Talos machine configuration.
  - **terraform**: Terraform configuration.
- **kubernetes**: The cluster itself.
  - **apps**: The applications to load.
  - **bootstrap**: The initial code loaded on the cluster to bootstrap it.
  - **cluster**: The definition of the cluster.
    - **config**: The configuration of the cluster to use flux.
    - **repositories**: Sources of code for the cluster.
    - **vars**: The ConfigMap and Secret used for variable substitution by Flux.
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

The task `bootstrap:config` is responsible for traversing the whole repo and creating the appropriate YAML files and encrypting them when necessary.
With this structure, all files can be checked in to the repo with no risk of leaking secret values. `build-config.sh` will also create a `.sha256` file for each of the `.cfg` files processed.
This file is used as an optimization so that the YAML files will only be regenerated if the actual values change, which keeps the number of files in an updating PR smaller.

### Setup Configuration

The file [cluster-settings.cfg](./kubernetes/main/cluster/vars/cluster-settings.cfg) defines a ConfigMap resource that will be filled in with values from the `env.XXX` configuration files.
Flux will load this file to the cluster at the beginning of the resolve phase so that the ConfigMap values are available through the Kustomization post-build step.
Since the configuration values are stored in a ConfigMap resource, the resulting YAML file will make them visible in the repo. If you do not wish to have them visible, use the `cluster-secrets.sops.cfg` file described below.

### Cluster Secrets

The file [cluster-secrets.sops.cfg](./kubernetes/main/cluster/vars/cluster-secrets.sops.cfg) defines a Secret resource that will be filled in with values from the `env.XXX` configuration files and then encrypted with Mozilla/sops.

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

Currently, I use a combination of built-in application backups (e.g., \*arr applications will backup weekly), an external shell script that will backup databases (mysql and postgres),
and a couple of apps that I have backed up their configuration as it doesn't change frequently and it gets automatically restored upon the very first startup.
I am also using poor man's backup (PMB) that is based on kopia as well as volsync which is based on restic and puts the backups into my Minio storage.

## Installation

### Initial Machine Configuration

The machines are configured using Talos (see [Getting Started](https://www.talos.dev/v0.14/introduction/getting-started/) for a walkthrough).

The tasks I used for generating the Talos configuration are found in `./.taskfiles/Talos`.

The expectation is that at the end of this step, your machines are up and running and the command line tool `kubectl` can be used to interact with the cluster.

### Cluster Bringup

You will need to have installed `flux` and the Mozilla sops tool for this bringup.

The bringup of this cluster sort of follows the template cluster at [onedr0p/flux-cluster-template](https://github.com/onedr0p/flux-cluster-template).
A Mozilla/sops secret needs to be created and the [.sops.yaml](./.sops.yaml) file updated appropriately. This is a one-time operation.

There are env.XXX.template files in the setup directory. These should be filled in as appropriate with values needed. I've included descriptions in the template file.
Again, filling these in is typically a one-time operation, but as you add functionality to your cluster, you will likely need to add configuration and/or secrets to the file.

Pairing with the env.XXX files, you will need to expose your configuration in the `cluster-config.cfg` and `cluster-secrets.sops.cfg` files. You don't need to hard-code any values there, just follow the template.

Once the environment and the cluster config/secret file templates are created, run the `build-config.sh` script file and fix any errors.
Examine all the updated `.YAML` files to ensure that the appropriate configuration is filled in.
For example, if there is an environment typo, the YAML file may contain a blank or null rather than the desired value.

When you've got everything created and to your liking, create a commit and push to GitHub.

At this point you should have your machines up and running with the base k3s install of control planes and workers.

The final step is to run the `bootstrap-cluster.sh` script as

```shell
bootstrap-cluster.sh
```

This will connect flux to your repo, put the Flux controllers onto your cluster which will then load up your cluster. Pick your favourite tool (e.g., Lens) to watch your cluster come alive.

### Adding a New Package / Updating Configuration

If you ever need to change any of the configuration or want to add a new package to your repo, modify the env.XXX files appropriately, create the package files with
.cfg or .sops.cfg files as needed and then run `build-config.sh` from the `setup` directory. This will update any of the config / secret files throughout the repo.
Commit and push the change and Flux will take care of updating your cluster with the changes.

### Ongoing Maintenance

Maintenance of the cluster is fairly minimal.

- renovate creates PRs to update helm charts, flux system files, or docker images in the cluster;
- flux applies any merged PRs or changes to the repo to the cluster automatically.

I manually keep the router VM and PiHole up to date through Anisble scripts.

Through Wireguard and [Kubenav](https://kubenav.io), I can pretty much manage the cluster remotely from my phone.
On my desktop/laptop, I use [Lens](https://k8slens.dev) to manage the cluster which works remotely through Wireguard as well.

## Gratitude and Thanks

Many thanks to the folks at [k8s-at-home](https://github.com/k8s-at-home) that maintain the many great Helm charts, have opened their own repos for the rest of us to learn, and answer many questions on the discord server.
A special thanks to Devin (@onedr0p) who's cluster I modelled mine after.
Another special thanks to Nat (@Truxnell) who answered a bunch of my questions about Talos while I was on vacation reading github repos and docs on my iPhone.
A tongue-in-cheek thanks to Jeff (@billimek) who's dang YouTube video on Home Assistant and his cluster repo led me into this rabbit hole.
