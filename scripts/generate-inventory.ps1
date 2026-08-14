<#
Genere l'inventaire Ansible (inventories/home/hosts.yml) a partir des outputs Terraform.
A executer depuis la racine du depot Terraform, apres un `terraform apply` reussi.
Suppose que INFRA-ANSIBLE-PVE-HOME est clone au meme niveau que ce depot (../INFRA-ANSIBLE-PVE-HOME).
#>

$ErrorActionPreference = "Stop"

$outputs = terraform output -json | ConvertFrom-Json

$ansibleRepo = Join-Path (Split-Path $PSScriptRoot -Parent) "..\INFRA-ANSIBLE-PVE-HOME"
$inventoryDir = Join-Path $ansibleRepo "inventories\home"
$inventoryFile = Join-Path $inventoryDir "hosts.yml"

if (-not (Test-Path $ansibleRepo)) {
    Write-Error "Depot Ansible introuvable a $ansibleRepo. Ajustez le chemin dans ce script si besoin."
}

New-Item -ItemType Directory -Force -Path $inventoryDir | Out-Null

$content = @"
all:
  children:
    control_node:
      hosts:
        $($outputs.lpransible01_vm_name.value):
          ansible_host: $($outputs.lpransible01_ip_address.value)
          ansible_user: ansible
"@

Set-Content -Path $inventoryFile -Value $content -Encoding utf8
Write-Output "Inventaire genere : $inventoryFile"
