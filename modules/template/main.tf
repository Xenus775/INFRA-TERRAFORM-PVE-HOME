resource "proxmox_download_file" "cloud_image" {
  content_type = "import"
  datastore_id = var.storage_import
  node_name    = var.proxmox_node
  url          = var.cloud_image_url
  file_name    = var.cloud_image_filename
  overwrite    = false
}

resource "proxmox_virtual_environment_vm" "template" {
  name      = var.name
  node_name = var.proxmox_node
  vm_id     = var.vm_id
  pool_id   = var.pool_id
  template  = true

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = var.network_bridge
  }

  disk {
    datastore_id = var.storage_vm
    file_id      = proxmox_download_file.cloud_image.id
    interface    = "scsi0"
    # Pas de "size" ici : on garde la taille native de l'image cloud pour eviter
    # un redimensionnement a l'import, qui necessiterait un acces SSH au noeud
    # Proxmox (limitation connue du provider bpg/proxmox). Chaque clone (module
    # vm) redimensionne son propre disque via l'API, sans avoir ce probleme.
  }

  initialization {
    datastore_id = var.storage_vm

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  serial_device {}
}
