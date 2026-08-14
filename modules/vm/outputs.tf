output "vm_id" {
  value = proxmox_virtual_environment_vm.this.vm_id
}

output "vm_name" {
  value = proxmox_virtual_environment_vm.this.name
}

output "ipv4_addresses" {
  description = "Adresses IPv4 rapportees par le qemu-guest-agent (utile pour les VM en DHCP)"
  value       = proxmox_virtual_environment_vm.this.ipv4_addresses
}
