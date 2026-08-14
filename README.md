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

## Provider utilise

[`bpg/proxmox`](https://registry.terraform.io/providers/bpg/proxmox/latest).
Raisons du choix detaillees dans `DECISIONS.txt`.

## Authentification Proxmox

Ce depot n'utilise **jamais** de compte root. Deux tokens dedies existent :

| Token | Role | Usage |
|---|---|---|
| `terraform_auditor@pve!auditor` | PVEAuditor (lecture seule) sur `/` | Audit uniquement, non utilise par ce code Terraform |
| `terraform_provisioner@pve!provisioner` | PVEAdmin sur `/pool/IAC`, PVEDatastoreAdmin sur `/storage/local` et `/storage/local-lvm` | Utilise par Terraform |

Pour recreer ce token si besoin, dans l'UI Proxmox :

1. *Datacenter -> Permissions -> Pools -> Add* -> ID `IAC`
2. *Datacenter -> Permissions -> Users -> Add* -> `terraform_provisioner@pve`
3. *Datacenter -> Permissions -> Add* -> Path `/pool/IAC`, role `PVEVMAdmin` (ou `PVEAdmin`), Propagate
4. *Datacenter -> Permissions -> Add* -> Path `/storage/local`, role `PVEDatastoreAdmin`, Propagate
5. *Datacenter -> Permissions -> Add* -> Path `/storage/local-lvm`, role `PVEDatastoreAdmin`, Propagate
6. *Datacenter -> Permissions -> API Tokens -> Add* -> user ci-dessus, Token ID `provisioner`, decocher "Privilege Separation"

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
