# INFRA-TERRAFORM-PVE-HOME

Provisioning des VM sur mon Proxmox personnel (`https://192.168.10.160:8006/`, noeud
`PVE-INFRA-MATT-01`, Proxmox VE 9.2.10) avec Terraform.

Ce depot est responsable **uniquement** du provisioning : creation des VM, CPU,
RAM, disque, reseau, hostname, Cloud-Init, cle SSH. La configuration logicielle
detaillee (paquets, services, durcissement) est geree separement par
[INFRA-ANSIBLE-PVE-HOME](https://github.com/Xenus775/INFRA-ANSIBLE-PVE-HOME).

## Architecture

```
Terraform
    |
    v
Telechargement image cloud Debian 13 (module template)
    |
    v
Template Cloud-Init (VMID 9000)
    |
    v
Clone complet (module vm) -> VM prete, Cloud-Init applique
    |
    v
Ansible (depot separe) -> configuration complete
```

Toutes les VM gerees par ce depot sont rattachees au pool Proxmox `IAC` et
utilisent des VMID dans la plage 200-299 (voir `DECISIONS.txt`), pour ne
jamais entrer en collision avec les VM/CT existants geres manuellement
(adguard, Debian-gui, Zorin, Openvpn, nginxproxymanager, wizarr).

## Prerequis

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.8
- Un token API Proxmox dedie au provisioning (voir section "Authentification")
- Une paire de cles SSH dediee, dont la cle publique sera injectee via
  Cloud-Init dans chaque VM
- Une seconde paire de cles SSH dediee, dont la cle publique doit etre ajoutee
  au `authorized_keys` de root sur l'hote Proxmox (voir section
  "Authentification" — necessaire uniquement pour l'import du disque du
  template, limitation du provider, voir `DECISIONS.txt`)

## Provider utilise

[`bpg/proxmox`](https://registry.terraform.io/providers/bpg/proxmox/latest).
Raisons du choix detaillees dans `DECISIONS.txt`.

## Authentification Proxmox

L'authentification API n'utilise **jamais** de compte root. Deux tokens
dedies existent :

| Token | Role | Usage |
|---|---|---|
| `terraform_auditor@pve!auditor` | PVEAuditor (lecture seule) sur `/` | Audit uniquement, non utilise par ce code Terraform |
| `terraform_provisioner@pve!provisioner` | voir tableau de permissions ci-dessous | Utilise par Terraform |

Permissions du token `provisioner` (principe de moindre privilege, voir
`DECISIONS.txt` pour le detail de chaque decision) :

| Path | Role | Pourquoi |
|---|---|---|
| `/pool/IAC` | `PVEAdmin` | Creer/gerer les VM du pool dedie a l'IaC |
| `/storage/local` | `PVEDatastoreAdmin` | Importer l'image cloud |
| `/storage/local-lvm` | `PVEDatastoreAdmin` | Allouer les disques des VM |
| `/nodes/PVE-INFRA-MATT-01` | `PVEAdmin` | Operations de creation de VM sur ce noeud |
| `/` | `SysModifyOnly` (role custom : Sys.Audit + Sys.Modify uniquement) | Requis par l'API `download-url` (protection anti-SSRF cote Proxmox) |
| `/sdn/zones/localnetwork/vmbr0` | `PVESDNUser` | Requis depuis PVE 9 pour attacher une VM au bridge (SDN implicite) |

Pour recreer ce token si besoin, dans l'UI Proxmox :

1. *Datacenter -> Permissions -> Pools -> Add* -> ID `IAC`
2. *Datacenter -> Permissions -> Users -> Add* -> `terraform_provisioner@pve`
3. *Datacenter -> Permissions -> Add* -> Path `/pool/IAC`, role `PVEAdmin`, Propagate
4. *Datacenter -> Permissions -> Add* -> Path `/storage/local`, role `PVEDatastoreAdmin`, Propagate
5. *Datacenter -> Permissions -> Add* -> Path `/storage/local-lvm`, role `PVEDatastoreAdmin`, Propagate
6. *Datacenter -> Permissions -> Add* -> Path `/nodes/PVE-INFRA-MATT-01`, role `PVEAdmin`, Propagate
7. *Datacenter -> Permissions -> Roles -> Add* -> Role ID `SysModifyOnly`, cocher uniquement `Sys.Audit` et `Sys.Modify`
8. *Datacenter -> Permissions -> Add* -> Path `/`, role `SysModifyOnly`, Propagate
9. *Datacenter -> Permissions -> Add* -> Path `/sdn/zones/localnetwork/vmbr0`, role `PVESDNUser`, Propagate
10. *Datacenter -> Permissions -> API Tokens -> Add* -> user ci-dessus, Token ID `provisioner`, decocher "Privilege Separation"

### Acces SSH au noeud (Terraform uniquement)

Le provider `bpg/proxmox` a besoin d'un acces SSH au noeud Proxmox pour
finaliser la creation du disque du template a partir de l'image importee
(limitation du provider, pas contournable — voir `DECISIONS.txt`). Une paire
de cles dediee est utilisee, distincte de la cle Cloud-Init :

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_pve_host_terraform -C "terraform-pve-host-ssh"
```

Ajoutez la cle publique au `authorized_keys` de root sur l'hote, via le Shell
web Proxmox (*Datacenter -> Noeud -> Shell*) :

```bash
echo "<cle-publique>" >> /root/.ssh/authorized_keys
```

Renseignez ensuite `pve_ssh_username` et `pve_ssh_private_key_path` dans
`terraform.tfvars`.

## Gestion des secrets

**Aucun secret n'est commite dans ce depot.**

- `terraform.tfvars` (valeurs reelles : token, secret, cle SSH publique) est
  local uniquement, exclu par `.gitignore`.
- Seul `terraform.tfvars.example` (valeurs factices) est versionne.
- Le state Terraform (`terraform.tfstate*`, dossier `.terraform/`) est
  egalement exclu par `.gitignore` : il peut contenir des donnees sensibles
  (adresses IP, attributs de VM).
- `.terraform.lock.hcl` (fichier de verrouillage des versions de provider) est
  en revanche bien commite : ce n'est pas un secret, c'est ce qui garantit une
  installation reproductible du provider.

## Configuration

```bash
cp terraform.tfvars.example terraform.tfvars
# Editez terraform.tfvars avec vos vraies valeurs (jamais commite)
```

Variables principales (voir `variables.tf` pour la liste complete) :

| Variable | Description | Defaut |
|---|---|---|
| `proxmox_endpoint` | URL de l'API Proxmox | - (obligatoire) |
| `proxmox_api_token_id` | Token ID (`user@realm!tokenid`) | - (obligatoire) |
| `proxmox_api_token_secret` | Secret du token | - (obligatoire, sensible) |
| `ssh_public_key` | Cle publique SSH injectee via Cloud-Init | - (obligatoire) |
| `pve_ssh_private_key_path` | Chemin local vers la cle privee SSH dediee au noeud Proxmox | - (obligatoire) |
| `pve_ssh_username` | Utilisateur SSH sur l'hote Proxmox | `root` |
| `proxmox_node` | Noeud Proxmox cible | `PVE-INFRA-MATT-01` |
| `network_bridge` | Bridge reseau | `vmbr0` |
| `storage_vm` | Storage des disques VM | `local-lvm` |
| `storage_template` | Storage d'import de l'image cloud | `local` |

## Utilisation

```bash
terraform init
terraform validate
terraform fmt -check
terraform plan
terraform apply
```

La destruction n'est **jamais** automatique et doit toujours etre explicite :

```bash
terraform plan -destroy    # verifier ce qui serait detruit
terraform destroy          # a executer uniquement en connaissance de cause
```

## Modifier une VM

Editez les parametres du module correspondant dans `main.tf` (ex: `memory_mb`,
`cpu_cores`, `disk_size_gb`), puis :

```bash
terraform plan
terraform apply
```

## Ajouter une nouvelle VM

Ajoutez un nouveau bloc `module` dans `main.tf` en reutilisant `./modules/vm`,
avec un `vm_id` libre dans la plage 200-299. Exemple minimal (VM en DHCP) :

```hcl
module "mon_service" {
  source = "./modules/vm"

  proxmox_node   = var.proxmox_node
  vm_name        = "mon-service"
  vm_id          = 201
  template_vm_id = module.template.vm_id
  pool_id        = var.iac_pool_id
  storage        = var.storage_vm
  network_bridge = var.network_bridge
  ci_user        = var.ci_user
  ssh_public_key = var.ssh_public_key
  tags           = ["iac"]
}
```

## Outputs

`terraform output -json` expose notamment `lpransible01_vm_id`,
`lpransible01_ip_address` et `template_vm_id`. Le script
`scripts/generate-inventory.ps1` s'appuie sur ces outputs pour generer
l'inventaire consomme par Ansible.

## Compte d'exploitation automatique sur les nouvelles VM

A chaque nouvelle VM Linux provisionnee par ce depot, un compte local
`exploitation` (sudo, mot de passe genere aleatoirement) doit etre cree
via le role Ansible `exploitation_account`. Ce depot Terraform ne declenche
pas Ansible lui-meme (separation des responsabilites, voir DECISIONS.txt) :
un script explicite fait le lien, a executer manuellement apres chaque
`terraform apply` ayant cree une VM :

```powershell
# 1. Ajoutez la VM dans inventories/home/hosts.yml (depot Ansible), groupe approprie
# 2. Puis :
.\scripts\provision-vm.ps1 -VmName web01
```

Le script commit/push le depot Ansible si necessaire, declenche le
playbook `exploitation-account.yml` sur LPRANSIBLE01 (`--limit <VmName>`),
et affiche le mot de passe genere a la fin de son execution. Ce mot de
passe n'est utilisable qu'en local (console Proxmox / `su`), jamais en SSH
— voir le README du depot Ansible.

## Troubleshooting

- **`401`/`403` de l'API Proxmox** : verifiez que le token n'a pas expire et
  qu'il a bien les permissions listees ci-dessus sur `/pool/IAC` et les deux
  storages.
- **Erreur de certificat TLS** : normal avec un certificat auto-signe Proxmox,
  couvert par `proxmox_tls_insecure = true` (defaut).
- **Le clone echoue avec une erreur de VMID deja utilise** : verifiez que le
  VMID choisi est bien libre (`terraform plan` le signalera aussi si le state
  local sait deja qu'il est pris).

## Bonnes pratiques / workflow recommande

1. `git pull` avant toute modification.
2. `terraform fmt` puis `terraform validate` avant tout `plan`.
3. Toujours lire un `terraform plan` en entier avant d'`apply` — en particulier
   surveiller toute ligne `-/+` (destroy + create) sur une VM existante, signe
   d'une modification qui force un remplacement.
4. Ne jamais lancer `terraform destroy` sans avoir identifie precisement la ou
   les ressources concernees.
