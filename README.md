<h1 align="center"><div align="center">

<img src="https://camo.githubusercontent.com/5b298bf6b0596795602bd771c5bddbb963e83e0f/68747470733a2f2f692e696d6775722e636f6d2f7031527a586a512e706e67" align="center" width="144px" height="144px"/>

### My home operations repository

... managed with Flux, Renovate and GitHub

</div>
</h1>

---

## Overview

This is my mono repo for my home infrastructure. It's based on the template at [k8s-at-home/template-cluster-k3](https://github.com/k8s-at-home/template-cluster-k3s) as well as many of the exemplar repos
at [k8s-at-home/awesome-home-kubernetes](https://github.com/k8s-at-home/awesome-home-kubernetes).

It follows the concept of Infrastructure as Code and by using tools such as [Ansible](https://www.ansible.com/), [Flux](https://github.com/fluxcd/flux2), [Renovate](https://github.com/renovatebot/renovate),
[go-task](https://github.com/go-task/task) and shell scripts, creates a reproducible, mostly self-managing implementation.

My original implementation was running on the Ryzen using custom shell scripts and 35+ docker containers managed by hand. Any upgrades, system resets, etc, all had to be manually resolved.
It mostly ran just fine. Applying the principle "If it ain't broke, it isn't complicated enough" led me to add machines, memory, functionality to achieve a much more automated, self-managing cluster. Plus I have learned a lot!

At the bottom of this page, is the bringup process that I follow for this cluster. I recommend reading top-to-bottom to understand the cluster structure which will help understand what's needed for the bringup.

---

## Hardware

| Device                                    | Count | OS Disk Size | Data Disk Size | RAM   | Operating System |
|----------------------------|-------|--------------|----------------|-------|--------------------|
| Ryzen 3900 12c24t server | 1          | 1TB                 |  4x4TB SATA    | 64GB | [Proxmox](https://www.proxmox.com/en/)                   |
| * K8s control plane nodes  | 3         | 40GB              |                            | 8GB    | Ubuntu 20.04         |
| * Router                                 | 1         | 20GB              |                            | 8GB    | Ubuntu 21.10          |
| * TrueNAS Core                    | 1         |                         | (on 4x4TB)       | 16GB | TrueNAS Core 12    |
| Raspberry Pi                         | 1         |                         |                            |             | PiHole                     |
| Raspberry Pi                         | 1         |                         |                            |             | OctoPrint                |
| Intel NUC11PAHi7 (worker nodes)                | 3          | 500GB SSD    | 1TB NVMe         | 64GB | Ubuntu 20.04          |
| Synology 1019+               | 1           |                        | 5x8TB SATA      |            |                                    |
| UDMPro                               | 1           |                        |                             |            |                                    |
| USW-Pro-24-PoE              | 1            |                       |                              |            |                                   |
| USW-Enterprise-8-PoE    | 1            |                       |                              |            |                                    |
| UNVR                                  | 1             |                      | 3x4TB SATA        |            |                                    |

## Kubernetes

The cluster is [k3s](https://k3s.io) with 3 control-plane nodes running in Proxmox Ubuntu 20.04 VMs (these will likely get replaced with Raspberry Pi 4s when/if they become available) and
3 worker nodes running on bare-metal Ubuntu 20.04 VMs.

### Core Components

- [mozilla/sops](https://toolkit.fluxcd.io/guides/mozilla-sops/): Manages secrets for Kubernetes and Ansible.
- [traefik/traefik](https://traefik.io): Manages reverse-proxy access to Kubernetes services.
- [metallb/metallb](https://metallb.universe.tf): Manages IP assignment for exposed Kubernetes services.
- [rook/rook](https://github.com/rook/rook): Distributed block storage for persistent storage.
- [jetstack/cert-manager](https://cert-manager.io/docs/): Creates SSL certificates for services in my Kubernetes cluster.
- [projectcalico/calico](https://github.com/projectcalico/calico): Internal Kubernetes networking plugin.
- [kubernetes-sigs/external-dns](https://github.com/kubernetes-sigs/external-dns): Automatically manages DNS records from my cluster in a cloud DNS provider.
- [kubernetes-sigs/nfs-subdir-external-provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner): Manages dynamic NFS persistent storage if Rook/NFS don't apply.
- [rancher/system-upgrade-controller](https://github.com/rancher/system-upgrade-controller): Manages updating the k3s system.
- [weaveworks/kured](https://github.com/weaveworks/kured): Manages rebooting the worker nodes when Ubuntu updates are applied that require a system reset.

### GitOps

[Flux](https://github.com/fluxcd/flux2) watches my [cluster](./cluster/) folder (see Directories below) and makes the changes to my cluster based on the YAML manifests.

[Renovate](https://github.com/renovatebot/renovate) watches my **entire** repository looking for dependency updates, when they are found a PR is automatically created.
When PRs are merged [Flux](https://github.com/fluxcd/flux2) applies the changes to my cluster.

Charts and images are tagged in the various YAML files to enable Renovate to watch and update them as needed.

## Network Configuration

The external is connected to the UDMPro with a [Wireguard](https://www.wireguard.com) port forwarded to the router VM and ports 80/443 forwarded to the Traefik IP in the cluster.

The 3 worker nodes and Ryzen server are connected to the 8-port switch with 2.5Gb ethernet. The Unifi components are connected with 10Gb ethernet connections.
Multiple wired access points are scattered around the house and backyard.

The Kubernetes cluster and IPs are on the 10.0.40.x subnet with VLAN tagging. Pods and services are on the 10.40.x.x and 10.41.x.x subnets respectively.
External machines (PiHole, Synology, etc) are on the main household VLAN subnet. IoT devices are on an isolated 10.0.80.x VLAN. They cannot reach the other VLANs directly but will answer when spoken to.

MetalLB is used to assign visible IP addresses to Kubernetes services(e.g., MySQL). Traefik is used to reverse-proxy other services within the cluster.

DNS is managed by CoreDNS in the cluster which then forwards unresolved requests to PiHole which is also running an [unbound](https://docs.pi-hole.net/guides/dns/unbound/) recursive DNS server.
The PiHole has a local DNS configuration to map names to either IPs (assigned by MetalLB) or CNAME records that map to the Traefik IP.

The external DNS is managed via [Cloudflare](https://www.cloudflare.com/en-ca/).
External names are managed by [external-dns](https://github.com/kubernetes-sigs/external-dns) on the cluster and, since my home IP can be changed at any time, DDNS is maintained by the
[oznu/cloudflare-ddns](https://hub.docker.com/r/oznu/cloudflare-ddns/) docker image. Certificates are managed through CloudFlare as well using cert-manager and the DNS01 challenge protocol.

Any services that are exposed externally use [Authentik](https://goauthentik.io) for access authentication via a Traefik middleware.
Most/all internal services have a Traefik middleware to verify that the requesting IP address is on the internal network.

## Repository Structure

The repository supports multiple clusters -- in particular, I have a "production" cluster which runs on the above hardware, and then I can also deploy to a "staging" cluster which can run on
VMs/nodes that are created through [k3d](https://k3d.io/v5.3.0/) or Proxmox VMs. The staging cluster lets me try out new packages, figure out configuration etc, before committing to the main repo.

Adding something new to the cluster usually requires a lot of trial and error initially. When I am trying something out, I will work in a staging environment as much as possible and then move to the production cluster.
If additional iterations are required, I will usually try and do amended commits rather than a chain of commits with comments such as "Trying again" or "Maybe this will work", etc.

The repository directories are:

- **.github**: GitHub support files and renovate configuration.
- **.taskfiles**: Auxiliary files used for the task command-line tool.
- **ansible**: Ansible configuration for managing the cluster machinery.
- **charts**: Charts used for local customized helm charts.
- **cluster**: The cluster itself.
  - **apps**: The applications to load.
  - **config**: Where cluster-config.yaml and cluster-secrets.sops.yaml will be created.
  - **core**: The core packages loaded prior to the applications.
  - **crds**: CRD resources that must be loaded prior to any helm package processing.
  - **helm-charts**: The locations for any of the helm charts required in the cluster.
  - **production**: The production cluster.
- **setup**: Scripts to configure and create the cluster.
- **utils**: Miscellaneous utilities for managing the cluster.

### Cluster Setup

Install pre-commit with

```shell
pre-commit install --install-hooks
```

And update the hooks occasionally with (they should auto-update themselves though)

```shell
pre-commit auto-update
```

## Cluster Configuration

The cluster is configured through multiple levels:

- cluster configuration;
- cluster secrets;
- application secrets.

All values for the configurations are stored in a set of environment variables described below.

There should be at least one cluster `production` that will be used from the `main` branch of the repo.
Any other cluster types will be synced out of a branch with the same name as the cluster type (e.g., the staging cluster will be synced from the staging branch of the repo)

### External Environment Configuration

A base file [setup/env.base](./setup/env.base.template) is used to define any configuration about the external devices on the network (e.g., NAS drives) and config/secrets that are common to all of the cluster configurations.

Each cluster configuration (e.g. production or staging) has a file [setup/env.<cluster_type>](./setup/env.production.template) that is used to define any configuration that is specific to that cluster.
For example, the IP addresses that should be reserved through MetalLB for services such as Traefik for MySQL.

All values are defined as shell environment variables.

The shell script [setup/build-config.sh](./setup/build-config.sh) is responsible for traversing the whole repo and creating the appropriate YAML files and encrypting them when necessary.
With this structure, all files can be checked in to the repo with no risk of leaking secret values. `build-config.sh` will also create a `.sha256` file for each of the `.cfg` files processed.
This file is used as an optimization so that the YAML files will only be regenerated if the actual values change, which keeps the number of files in an updating PR smaller.

### Setup Configuration

The file [setup/cluster-config.cfg] defines a ConfigMap resource that will be filled in with values from the `env.XXX` configuration files and will be placed in the `/cluster/config/<cluster_type>` directory.
Flux will load this file to the cluster at the beginning of the resolve phase so that the ConfigMap values are available through the Kustomization post-build step.
Since the configuration values are stored in a ConfigMap resource, the resulting YAML file will make them visible in the repo. If you do not wish to have them visible, use the `cluster-secrets.sops.cfg` file described below.

### Cluster Secrets

The file [setup/cluster-secrets.sops.cfg] defines a Secret resource that will be filled in with values from the `env.XXX` configuration files and then encrypted with Mozilla/sops.
The resulting Secret resource will be placed in the `/cluster/config/<cluster_type>` directory and will also be loaded prior to the resolve phase so that the secrets will be available through the Kustomization post-build step.

### Application Secrets

Each application may require a Secret resource for configuration in the helm chart. In each package, an `application-config.cfg` or `application-secret.sops.cfg` files should be created.
As with cluster secrets, the `setup/build-config.sh` script will convert the secrets template into a SOPS-encrypted YAML file.

## Persistent Volume Management

Applications usually require data to work well. Persistent volumes on the cluster are stored in two places - Rook/Ceph and an external NFS.

### Rook/Ceph

Each worker has a 1Tb NVMe drive that is managed with Rook/Ceph. The data stored here is replicated across the multiple workers so it will be fast and available locally.

### NFS

I'm still experimenting with NAS storage with regards to the cluster. Most of my home data is stored on the Synology drive, but file-level permission management has been a bit of a pain.
I'm also going to use the TrueNAS Core storage running on the Ryzen server.

Applications that don't require fast access to data or only use it for temporary storage (e.g., a download directory) will store the data in NFS.
The NFS drives are available across the cluster but are at a slower speed than the Rook/Ceph storage.

### Data Backup and Recovery

This is a work in progress, but I'm currently experimenting with [Kasten.io K10](https://www.kasten.io/product/).

## Installation

### Initial Machine Configuration

The scripts in the `ansible/` directory can be used to update/install packages on Ubuntu 20.04 and install the base k3s components.
You will need to review all of the files here for configuration examples. You are free to bring up your machines manually or however you want.

The expectation is that at the end of this step, your machines are up and running and the command line tool `kubectl` can be used to interact with the cluster.

### Cluster Bringup

You will need to have installed `flux` and the Mozilla sops tool for this bringup.

The bringup of this cluster sort of follows the template cluster at [k8s-at-home/template-cluster-k3](https://github.com/k8s-at-home/template-cluster-k3s).
A Mozilla/sops secret needs to be created and the [.sops.yaml](./.sops.yaml) file updated appropriately. This is a one-time operation.

There are env.XXX.template files in the setup directory. These should be filled in as appropriate with values needed. I've included descriptions in the template file.
Again, filling these in is typically a one-time operation, but as you add functionality to your cluster, you will likely need to add configuration and/or secrets to the file.

Pairing with the env.XXX files, you will need to expose your configuration in the `cluster-config.cfg` and `cluster-secrets.sops.cfg` files. You don't need to hard-code any values there, just follow the template.

The file [setup/env-setup.sh](./setup/env-setup.sh) contains minimal information required for the setup scripts.
`SETUP_ENV_FILES_DIR` defines the location where the env.XXX files reside. I keep mine in `$HOME/.config/k8s-homelab`. `SETUP_CLUSTER_TYPES` defines the types of clusters that are supported.

Once the environment and the cluster config/secret file templates are created, run the `build-config.sh` script file and fix any errors.
Examine all the updated `.YAML` files to ensure that the appropriate configuration is filled in.
For example, if there is an environment typo, the YAML file may contain a blank or null rather than the desired value.

When you've got everything created and to your liking, create a commit and push to GitHub.

At this point you should have your machines up and running with the base k3s install of control planes and workers.

The final step is to run the `bootstrap-cluster.sh` script as

```shell
bootstrap-cluster.sh <cluster-type>

```

This will connect flux to your repo, put the Flux controllers onto your cluster which will then load up your cluster. Pick your favourite tool (e.g., Lens) to watch your cluster come alive.

### Adding a New Package / Updating Configuration

If you ever need to change any of the configuration or want to add a new package to your repo, modify the env.XXX files appropriately, create the package files with
.cfg or .sops.cfg files as needed and then run `build-config.sh` from the `setup` directory. This will update any of the config / secret files throughout the repo.
Commit and push the change and Flux will take care of updating your cluster with the changes.

### Ongoing Maintenance

Maintenance of the cluster is fairly minimal.

- system-upgrade-controller keeps the k3s distribution up to date;
- kured reboots worker nodes when an Ubuntu update requires a system reset;
- renovate creates PRs to update helm charts, flux system files, or docker images in the cluster;
- flux applies any merged PRs or changes to the repo to the cluster automatically.

Occasionally, the cluster doesn't come fully back when kured reboots it and some of the pods need a nudge to get back to running.

I manually keep the router VM and PiHole up to date through Anisble scripts.

Through Wireguard and [Kubenav](https://kubenav.io), I can pretty much manage the cluster remotely from my phone. On my desktop/laptop, I use [Lens](https://k8slens.dev) to manage the cluster which works remotely through Wireguard as well.

## Gratitude and Thanks

Many thanks to the folks at [k8s-at-home](https://github.com/k8s-at-home) that maintain the many great Helm charts, have opened their own repos for the rest of us to learn, and answer many questions on the discord server.
A special thanks to Devin (@onedr0p) who's cluster I modelled mine after.
Another tongue-in-cheek thanks to Jeff (@billimek) who's dang YouTube video on Home Assistant and his cluster repo led me into this rabbit hole.
