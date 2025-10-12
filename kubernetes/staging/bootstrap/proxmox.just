set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

vmids := '1 2 3'
vmips := '10.12.0.16 10.12.0.17 10.12.0.18'
vmid-prefix := '20'

[private]
default:
  just -l proxmox

[doc('Reset staging cluster')]
reset:
  just log info "Running stage..." "stage" "$0"
  just proxmox destroy
  just proxmox create
  just proxmox wait-for-startup

[doc('Destroy staging cluster')]
destroy:
  just log info "Running stage..." "stage" "$0"
  for vmid in {{vmids}}; do \
    just proxmox destroy-vm "$vmid"; \
  done

[doc('Create staging cluster')]
create:
  just log info "Running stage..." "stage" "$0"
  just proxmox create-vm 1 'DE:CA:FF:10:12:10'
  just proxmox create-vm 2 'DE:CA:FF:10:12:11'
  just proxmox create-vm 3 'DE:CA:FF:10:12:12'

[doc('Wait for staging cluster machines to start')]
wait-for-startup:
  just log info "Running stage..." "stage" "$0"
  for vmip in {{vmips}}; do \
    just proxmox wait-for-startup-vm "$vmip"; \
  done

[doc('Start staging cluster')]
start:
  just log info "Running stage..." "stage" "$0"
  for vmid in {{vmids}}; do \
    just proxmox start-vm "$vmid"; \
  done

[doc('Stop staging cluster')]
stop:
  just log info "Running stage..." "stage" "$0"
  for vmid in {{vmids}}; do \
    just proxmox stop-vm "$vmid"; \
  done

[doc('Unmount CD-ROM')]
unmount-cdrom:
  just log info "Running stage..." "stage" "$0"
  for vmid in {{vmids}}; do \
    just proxmox unmount-cdrom-vm "$vmid"; \
  done

[private]
destroy-vm vmid:
  just proxmox stop-vm {{vmid}}
  -ssh ares -- qm destroy {{vmid-prefix}}{{vmid}}

[private]
create-vm vmid mac:
  ssh ares -- qm create {{vmid-prefix}}{{vmid}} \
    --name stage-{{vmid}} \
    --description stage-{{vmid}} \
    --ide0 local:iso/metal-amd64.iso,media=cdrom \
    --boot 'order=ide0\;scsi0' \
    --memory 24576 \
    --balloon 0 \
    --sockets 1 \
    --cores 8 \
    --cpu host \
    --scsihw 'virtio-scsi-pci' \
    --vga type=virtio,memory=32 \
    --scsi0 local-lvm:50,backup=0 \
    --scsi1 local-lvm:100,backup=0 \
    --net0 model=virtio,bridge=vmbr0,macaddr={{mac}},mtu=1500,firewall=0,tag=12,queues=0,rate=0 \
    --start 1


[private]
wait-for-startup-vm ip:
  ping -o -q {{ip}}

[private]
stop-vm vmid:
  -ssh ares -- qm stop {{vmid-prefix}}{{vmid}}

[private]
start-vm vmid:
  -ssh ares -- qm start {{vmid-prefix}}{{vmid}}

[private]
unmount-cdrom-vm vmid:
  -ssh ares -- qm set {{vmid-prefix}}{{vmid}} -ide0 media=cdrom,file=none
