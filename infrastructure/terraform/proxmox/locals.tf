locals {
  pm_api_token_id     = module.onepassword_item_proxmox.fields.PM_API_TOKEN_ID
  pm_api_token_secret = module.onepassword_item_proxmox.fields.PM_API_TOKEN_SECRET
  pm_host_ip          = module.onepassword_item_proxmox.fields.PM_HOST_IP
  pm_host_name        = module.onepassword_item_proxmox.fields.PM_HOST_NAME
  pm_password         = module.onepassword_item_proxmox.fields.PM_PASSWORD

  talos_iso = "local:iso/metal-amd64.iso"

  control_plane_nodes = {
    "stage-1" = {
      vmid     = 201
      hostname = "stage-1"
      macaddr  = "DE:CA:FF:10:12:10"
    },
    "stage-2" = {
      vmid     = 202
      hostname = "stage-2"
      macaddr  = "DE:CA:FF:10:12:11"
    },
    "stage-3" = {
      vmid     = 203
      hostname = "stage-3"
      macaddr  = "DE:CA:FF:10:12:12"
    }
  }

  worker_nodes = {
    "stage-4" = {
      vmid     = 204
      hostname = "stage-4"
      macaddr  = "DE:CA:FF:10:12:13"
    },
    "stage-5" = {
      vmid     = 205
      hostname = "stage-5"
      macaddr  = "DE:CA:FF:10:12:14"
    },
    "stage-6" = {
      vmid     = 206
      hostname = "stage-6"
      macaddr  = "DE:CA:FF:10:12:15"
    }
  }
}
