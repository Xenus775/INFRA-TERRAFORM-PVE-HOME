resource "proxmox_virtual_environment_vm" "this" {
  name      = var.vm_name
  node_name = var.proxmox_node
  vm_id     = var.vm_id
  pool_id   = var.pool_id
  tags      = var.tags

  clone {
    vm_id = var.template_vm_id
    full  = true
  }

  cpu {
    cores = var.cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.memory_mb
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = var.network_bridge
  }

  disk {
    datastore_id = var.storage
    interface    = "scsi0"
    size         = var.disk_size_gb
  }

  initialization {
    datastore_id = var.storage

    user_account {
      username = var.ci_user
      keys     = [var.ssh_public_key]
    }

    ip_config {
      ipv4 {
        address = var.ip_address
        gateway = var.ip_address == "dhcp" ? null : var.gateway
      }
    }
  }
}
