output "vm_id" {
  description = "VMID du template Cloud-Init"
  value       = proxmox_virtual_environment_vm.template.vm_id
}
