output "template_vm_id" {
  description = "VMID du template Cloud-Init"
  value       = module.template.vm_id
}

output "lpransible01_vm_id" {
  value = module.lpransible01.vm_id
}

output "lpransible01_vm_name" {
  value = module.lpransible01.vm_name
}

output "lpransible01_ip_address" {
  value = "192.168.10.120"
}

output "web01_vm_id" {
  value = module.web01.vm_id
}

output "web01_vm_name" {
  value = module.web01.vm_name
}

output "web01_ipv4_addresses" {
  description = "Adresses IPv4 rapportees par le qemu-guest-agent (VM en DHCP)"
  value       = module.web01.ipv4_addresses
}

output "portal01_vm_id" {
  value = module.portal01.vm_id
}

output "portal01_vm_name" {
  value = module.portal01.vm_name
}

output "portal01_ip_address" {
  value = "192.168.10.121"
}
