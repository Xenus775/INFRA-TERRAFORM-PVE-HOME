# Module `vm`

Clone une VM a partir du template Cloud-Init produit par le module `template`.

## Ce que fait ce module

1. Clone complet (`full = true`) du template designe par `template_vm_id`.
2. Redimensionne le disque a `disk_size_gb`.
3. Injecte via Cloud-Init : le compte `ci_user`, la cle publique SSH `ssh_public_key`, et la configuration IP (`ip_address` = `dhcp` ou une adresse statique en notation CIDR).
4. Rattache la VM au pool `pool_id` s'il est fourni (permet de scoper les permissions Proxmox et de visualiser d'un coup d'oeil les VM gerees par Terraform).

## Adressage IP

- `ip_address = "dhcp"` (valeur par defaut) : convient aux VM de service classiques.
- `ip_address = "192.168.10.120/24"` + `gateway = "192.168.10.254"` : pour les VM d'administration, qui doivent avoir une IP stable et previsible (plage reservee : `192.168.10.120` a `192.168.10.130`).

## Exemple d'utilisation

```hcl
module "lpransible01" {
  source         = "./modules/vm"
  proxmox_node   = var.proxmox_node
  vm_name        = "LPRANSIBLE01"
  vm_id          = 200
  template_vm_id = module.template.vm_id
  pool_id        = var.iac_pool_id
  storage        = var.storage_vm
  network_bridge = var.network_bridge
  ip_address     = "192.168.10.120/24"
  gateway        = var.network_gateway
  ci_user        = var.ci_user
  ssh_public_key = var.ssh_public_key
  tags           = ["iac", "control-node"]
}
```
