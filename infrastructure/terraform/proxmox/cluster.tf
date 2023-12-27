resource "proxmox_vm_qemu" "control_planes" {
  for_each = local.control_plane_nodes

  name        = each.value.hostname
  target_node = local.pm_host_name
  vmid        = each.value.vmid
  desc        = each.value.hostname
  iso         = local.talos_iso
  onboot      = false
  boot        = "order=ide2;scsi0"
  memory      = "4096"
  balloon     = 0
  sockets     = 1
  cores       = 8
  cpu         = "host"
  scsihw      = "virtio-scsi-pci"

  vga {
    type   = "virtio"
    memory = 32
  }
  disk {
    size     = "20G"
    type     = "scsi"
    storage  = "local-lvm"
    iothread = 0
  }
  network {
    model    = "virtio"
    bridge   = "vmbr0"
    macaddr  = each.value.macaddr
    tag      = 12
    firewall = false
    mtu      = 1500
    queues   = 0
    rate     = 0
  }
  lifecycle {
    ignore_changes = [qemu_os, args, clone, hagroup, target_node, full_clone, network]
  }
}

resource "proxmox_vm_qemu" "workers" {
  for_each = local.worker_nodes

  name        = each.value.hostname
  target_node = local.pm_host_name
  vmid        = each.value.vmid
  cpu         = "host"
  memory      = "16384"
  balloon     = 0
  sockets     = 1
  cores       = 8
  scsihw      = "virtio-scsi-pci"
  boot        = "order=ide2;scsi0"
  iso         = local.talos_iso

  vga {
    type   = "virtio"
    memory = 32
  }
  disk {
    size     = "200G"
    type     = "scsi"
    storage  = "local-lvm"
    iothread = 0
  }
  disk {
    size     = "100G"
    type     = "scsi"
    storage  = "local-lvm"
    iothread = 0
  }
  network {
    model    = "virtio"
    bridge   = "vmbr0"
    macaddr  = each.value.macaddr
    tag      = 12
    firewall = false
    mtu      = 1500
    queues   = 0
    rate     = 0
  }
  lifecycle {
    ignore_changes = [qemu_os, args, clone, hagroup, target_node, full_clone, network]
  }
}
