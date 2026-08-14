provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = var.proxmox_tls_insecure

  # Necessaire uniquement pour l'etape d'import du disque du template
  # (limitation de l'API Proxmox, voir DECISIONS.txt). Cle dediee, distincte
  # de celle injectee via Cloud-Init dans les VM.
  ssh {
    username    = var.pve_ssh_username
    private_key = file(var.pve_ssh_private_key_path)
  }
}
