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
    size         = var.disk_size_gb
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
