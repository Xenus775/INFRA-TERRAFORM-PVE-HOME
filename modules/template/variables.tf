variable "proxmox_node" {
  type        = string
  description = "Noeud Proxmox cible"
}

variable "vm_id" {
  type        = number
  description = "VMID du template"
  default     = 9000
}

variable "name" {
  type        = string
  description = "Nom du template"
  default     = "debian-13-cloudinit"
}

variable "pool_id" {
  type        = string
  description = "Pool Proxmox auquel rattacher le template"
  default     = null
}

variable "storage_import" {
  type        = string
  description = "Storage utilise pour importer l'image cloud (content-type: import)"
}

variable "storage_vm" {
  type        = string
  description = "Storage utilise pour le disque du template"
}

variable "network_bridge" {
  type        = string
  description = "Bridge reseau"
}

variable "cloud_image_url" {
  type        = string
  description = "URL de l'image cloud Debian 13 (qcow2)"
  default     = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2"
}

variable "cloud_image_filename" {
  type        = string
  description = "Nom de fichier local de l'image cloud une fois telechargee"
  default     = "debian-13-generic-amd64.qcow2"
}
