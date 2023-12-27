provider "proxmox" {
  pm_api_url      = "https://${local.pm_host_ip}:8006/api2/json"
  pm_tls_insecure = true
  pm_user         = "root@pam"
  pm_password     = local.pm_password
  # pm_api_token_id = local.pm_api_token_id
  # pm_api_token_secret = local.pm_api_token_secret

  # pm_log_enable       = true
  # pm_log_file         = "terraform-plugin-proxmox.log"
  # pm_debug            = true
  # pm_log_levels       = {
  #   _default          = "debug"
  #   _capturelog       = ""
  # }
}
