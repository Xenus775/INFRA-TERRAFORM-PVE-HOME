# Module `template`

Construit le template Cloud-Init de base utilise pour cloner toutes les VM de l'infrastructure.

## Ce que fait ce module

1. Telecharge l'image cloud Debian 13 (qcow2) directement dans le storage Proxmox indique (`storage_import`), via l'API (content-type `import`, disponible depuis Proxmox VE 8.1+). Aucun acces SSH a l'hote Proxmox n'est necessaire.
2. Cree une VM a partir de cette image, avec l'agent QEMU active et une interface Cloud-Init.
3. Marque cette VM comme template (`template = true`), la rendant clonable par le module `vm`.

## Pourquoi Debian 13

Coherent avec le reste de l'environnement Proxmox (les conteneurs LXC existants utilisent deja Debian 13, et l'ISO d'installation Debian 13 est presente sur le noeud).

## Variables principales

Voir `variables.tf`. Le storage d'import (`storage_import`) et le storage final du disque (`storage_vm`) peuvent etre distincts : sur cet environnement, `local` (dir) sert a l'import, `local-lvm` (thin) accueille le disque final pour beneficier des clones rapides et des snapshots.
