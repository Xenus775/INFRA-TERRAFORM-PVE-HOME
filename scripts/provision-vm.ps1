<#
A executer apres un `terraform apply` ayant cree une nouvelle VM Linux.

Declenche le playbook Ansible exploitation-account.yml (depot
INFRA-ANSIBLE-PVE-HOME) sur la VM nommee -VmName, qui cree un compte local
"exploitation" (groupe sudo) avec un mot de passe genere aleatoirement.
Le mot de passe est affiche a la fin de ce script : c'est le seul moment ou
il est visible en clair, il n'est stocke nulle part.

Prerequis :
- La VM doit deja etre presente dans inventories/home/hosts.yml du depot
  Ansible (ajoutez-la au groupe approprie avant d'executer ce script).
- Le depot Ansible est clone au meme niveau que ce depot Terraform
  (../INFRA-ANSIBLE-PVE-HOME), comme pour generate-inventory.ps1.
- Cle SSH dediee au control-node (~/.ssh/id_ed25519_pve_admin) disponible
  localement pour joindre LPRANSIBLE01.

Exemple :
    .\scripts\provision-vm.ps1 -VmName web01
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$VmName,

    [string]$ControlNodeHost = "192.168.10.120",
    [string]$ControlNodeUser = "ansible",
    [string]$ControlNodeKey = "$HOME\.ssh\id_ed25519_pve_admin"
)

$ErrorActionPreference = "Stop"

$ansibleRepo = Join-Path (Split-Path $PSScriptRoot -Parent) "..\INFRA-ANSIBLE-PVE-HOME"
if (-not (Test-Path $ansibleRepo)) {
    Write-Error "Depot Ansible introuvable a $ansibleRepo. Ajustez le chemin dans ce script si besoin."
}

$hostsFile = Join-Path $ansibleRepo "inventories\home\hosts.yml"
if (-not (Select-String -Path $hostsFile -Pattern "^\s*${VmName}:" -Quiet)) {
    Write-Error "'$VmName' n'apparait pas dans $hostsFile. Ajoutez-le d'abord au groupe approprie (voir README du depot Ansible), committez, puis relancez ce script."
}

Push-Location $ansibleRepo
try {
    $pendingChanges = git status --porcelain
    if ($pendingChanges) {
        Write-Output "Changements en attente detectes dans le depot Ansible, commit + push..."
        git add -A
        git commit -m "Mettre a jour l'inventaire pour $VmName" | Out-Null
        git push origin main
    }
}
finally {
    Pop-Location
}

Write-Output "Declenchement de exploitation-account.yml sur $VmName via $ControlNodeHost..."

$remoteCommand = "cd ~/INFRA-ANSIBLE-PVE-HOME && git pull && ansible-playbook exploitation-account.yml --limit $VmName"
$output = ssh -i $ControlNodeKey -o BatchMode=yes "$ControlNodeUser@$ControlNodeHost" $remoteCommand 2>&1
$output | ForEach-Object { Write-Output $_ }

if ($LASTEXITCODE -ne 0) {
    Write-Error "L'execution du playbook a echoue (code $LASTEXITCODE). Voir la sortie ci-dessus."
}

$passwordLine = $output | Select-String -Pattern "EXPLOITATION_PASSWORD host=$VmName .*password=([A-Za-z0-9]+)"
if (-not $passwordLine) {
    Write-Output ""
    Write-Output "Aucun mot de passe genere signale : le compte 'exploitation' existait probablement deja sur $VmName (non regenere)."
}
else {
    $password = $passwordLine.Matches[0].Groups[1].Value
    Write-Output ""
    Write-Output "=========================================="
    Write-Output "Compte exploitation cree sur $VmName"
    Write-Output "Mot de passe (a noter, non stocke) : $password"
    Write-Output "Accessible uniquement en local/console (pas de mot de passe en SSH)."
    Write-Output "=========================================="
}
