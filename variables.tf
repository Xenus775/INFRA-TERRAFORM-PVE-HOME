variable "proxmox_endpoint" {
  type        = string
  description = "URL de l'API Proxmox (ex: https://192.168.10.160:8006/)"
}

variable "proxmox_api_token_id" {
  type        = string
  description = "Token ID Proxmox, format user@realm!tokenid"
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  type        = string
  description = "Secret du token API Proxmox"
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  type        = bool
  description = "Ignorer la validation du certificat TLS (certificat auto-signe Proxmox)"
  default     = true
}

variable "proxmox_node" {
  type        = string
  description = "Nom du noeud Proxmox cible"
  default     = "PVE-INFRA-MATT-01"
}

variable "network_bridge" {
  type        = string
  description = "Bridge reseau Proxmox utilise par les VM"
  default     = "vmbr0"
}

variable "network_gateway" {
  type        = string
  description = "Passerelle du reseau 192.168.10.0/24"
  default     = "192.168.10.254"
}

variable "storage_vm" {
  type        = string
  description = "Storage Proxmox utilise pour les disques des VM (rapide, thin)"
  default     = "local-lvm"
}

variable "storage_template" {
  type        = string
  description = "Storage Proxmox utilise pour importer l'image cloud de base"
  default     = "local"
}

variable "iac_pool_id" {
  type        = string
  description = "Pool Proxmox regroupant les VM gerees par Terraform"
  default     = "IAC"
}

variable "ssh_public_key" {
  type        = string
  description = "Cle publique SSH injectee via Cloud-Init sur toutes les VM provisionnees"
}

variable "ci_user" {
  type        = string
  description = "Nom du compte cree par Cloud-Init sur les VM"
  default     = "ansible"
}
