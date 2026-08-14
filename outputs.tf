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
