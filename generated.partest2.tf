# VM de service : partest2 (generee automatiquement par le portail de
# provisioning on-demand le 2026-08-17T20:58:39.908Z).
# NE PAS MODIFIER A LA MAIN - fichier gere par le portail
# (voir CODE-PLATFORME-PROVISIONING-ONDEMDAND).
module "partest2" {
  source = "./modules/vm"

  proxmox_node   = var.proxmox_node
  vm_name        = "partest2"
  vm_id          = 205
  template_vm_id = module.template.vm_id
  pool_id        = var.iac_pool_id

  cpu_cores    = 2
  memory_mb    = 4096
  disk_size_gb = 20
  storage      = var.storage_vm

  network_bridge = var.network_bridge
  # dhcp (choix "DHCP" dans le formulaire)

  ci_user        = var.ci_user
  ssh_public_key = var.ssh_public_key

  tags = ["iac", "portal", "apache"]
}
