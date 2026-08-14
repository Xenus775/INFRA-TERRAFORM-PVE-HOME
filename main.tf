module "template" {
  source = "./modules/template"

  proxmox_node   = var.proxmox_node
  storage_import = var.storage_template
  storage_vm     = var.storage_vm
  network_bridge = var.network_bridge
  pool_id        = var.iac_pool_id
}

# VM d'administration : control-node Ansible.
# IP statique fixe dans la plage reservee aux VM d'administration (192.168.10.120-130).
module "lpransible01" {
  source = "./modules/vm"

  proxmox_node   = var.proxmox_node
  vm_name        = "LPRANSIBLE01"
  vm_id          = 200
  template_vm_id = module.template.vm_id
  pool_id        = var.iac_pool_id

  cpu_cores    = 2
  memory_mb    = 2048
  disk_size_gb = 20
  storage      = var.storage_vm

  network_bridge = var.network_bridge
  ip_address     = "192.168.10.120/24"
  gateway        = var.network_gateway

  ci_user        = var.ci_user
  ssh_public_key = var.ssh_public_key

  tags = ["iac", "control-node", "ansible"]
}

# VM de service : serveur web (Apache), configuree par le role/playbook
# webserver.yml du depot Ansible (groupe d'inventaire "webservers").
module "web01" {
  source = "./modules/vm"

  proxmox_node   = var.proxmox_node
  vm_name        = "web01"
  vm_id          = 201
  template_vm_id = module.template.vm_id
  pool_id        = var.iac_pool_id

  cpu_cores    = 2
  memory_mb    = 2048
  disk_size_gb = 20
  storage      = var.storage_vm

  network_bridge = var.network_bridge
  # dhcp par defaut : VM de service, pas d'IP fixe requise.

  ci_user        = var.ci_user
  ssh_public_key = var.ssh_public_key

  tags = ["iac", "webserver"]
}

# VM d'administration : portail de provisioning on-demand
# (CODE-PLATFORME-PROVISIONING-ONDEMDAND). Detient le token API Proxmox et
# execute Terraform pour creer les VM a la demande ; ne lance jamais
# ansible-playbook lui-meme (voir DECISIONS.txt).
# IP statique fixe dans la plage reservee aux VM d'administration (192.168.10.120-130).
module "portal01" {
  source = "./modules/vm"

  proxmox_node   = var.proxmox_node
  vm_name        = "portal01"
  vm_id          = 202
  template_vm_id = module.template.vm_id
  pool_id        = var.iac_pool_id

  cpu_cores    = 2
  memory_mb    = 2048
  disk_size_gb = 20
  storage      = var.storage_vm

  network_bridge = var.network_bridge
  ip_address     = "192.168.10.121/24"
  gateway        = var.network_gateway

  ci_user        = var.ci_user
  ssh_public_key = var.ssh_public_key

  tags = ["iac", "control-node", "portal"]
}
