variable "proxmox_node" {
  type        = string
  description = "Noeud Proxmox cible"
}

variable "vm_name" {
  type        = string
  description = "Nom de la VM"
}

variable "vm_id" {
  type        = number
  description = "VMID de la VM (convention: plage 200-299 reservee aux VM gerees par Terraform)"
}

variable "template_vm_id" {
  type        = number
  description = "VMID du template Cloud-Init a cloner"
}

variable "pool_id" {
  type        = string
  description = "Pool Proxmox auquel rattacher la VM"
  default     = null
}

variable "cpu_cores" {
  type    = number
  default = 2
}

variable "memory_mb" {
  type    = number
  # 4096 par defaut (pas 2048) : une VM sous-provisionnee en RAM a rendu
  # l'agent QEMU tres lent a repondre pendant le boot/cloud-init sur
  # plusieurs VM cette session (LPRANSIBLE01, web01, portal01, demo01,
  # toutes a 2048 Mo).
  default = 4096
}

variable "disk_size_gb" {
  type    = number
  default = 20
}

variable "storage" {
  type        = string
  description = "Storage Proxmox pour le disque de la VM"
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "ip_address" {
  type        = string
  description = "Adresse IPv4 en notation CIDR (ex: 192.168.10.120/24) ou \"dhcp\""
  default     = "dhcp"
}

variable "gateway" {
  type        = string
  description = "Passerelle (ignoree si ip_address = dhcp)"
  default     = null
}

variable "ci_user" {
  type        = string
  description = "Nom du compte cree par Cloud-Init"
}

variable "ssh_public_key" {
  type        = string
  description = "Cle publique SSH injectee via Cloud-Init"
}

variable "tags" {
  type    = list(string)
  default = []
}
