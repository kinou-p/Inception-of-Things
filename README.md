# Inception-of-Things (IoT) - École 42

## Description
Inception-of-Things est un projet de l'École 42 qui introduit aux technologies DevOps modernes, particulièrement Kubernetes, Docker, et l'orchestration de conteneurs. Ce projet utilise K3s (Kubernetes léger) avec Vagrant pour créer et gérer des clusters Kubernetes, ainsi que K3d pour les environnements de développement locaux.

## Objectifs pédagogiques
- Découvrir **Kubernetes** et l'orchestration de conteneurs
- Maîtriser **K3s** (version allégée de Kubernetes) et **K3d** (K3s in Docker)
- Comprendre les **concepts DevOps** (IaC, CI/CD, GitOps)
- Gérer l'**infrastructure as Code** avec Vagrant
- Apprendre le **déploiement d'applications** conteneurisées
- Mettre en place des **services réseau** et load balancing
- Implémenter le **GitOps** avec Argo CD
- Configurer une chaîne **CI/CD complète** avec GitLab local

## Architecture du projet

### Structure générale
```
Inception-of-Things/
├── p1/                  # Partie 1 - Cluster K3s simple (Vagrant)
│   ├── Vagrantfile     # Configuration VMs
│   └── scripts/        # Scripts d'installation
├── p2/                  # Partie 2 - Applications et services (Vagrant)
│   ├── Vagrantfile     # Configuration avancée
│   ├── confs/          # Configurations Kubernetes
│   └── scripts/        # Scripts de déploiement
├── p3/                  # Partie 3 - K3d et Argo CD (Local VM)
│   ├── confs/          # Manifests Argo CD et Application
│   └── scripts/        # Scripts d'installation et setup
└── bonus/               # Bonus - Gitlab + Argo CD (Local VM)
    ├── confs/          # Config Gitlab et manifests
    └── scripts/        # Scripts d'installation complète et setup
```

---

## Partie 1 (P1) - Cluster K3s basique

### Objectifs
- Créer un cluster K3s avec **2 machines virtuelles**
- Configurer un **master node** et un **worker node**
- Établir la **communication inter-nodes**

### Infrastructure
- **VM Master (apommierS)** : `192.168.56.110` (Control plane)
- **VM Worker (apommierSW)** : `192.168.56.111` (Agent)
- **OS** : Ubuntu 18.04 (via Vagrant/VirtualBox)

### Déploiement
```bash
cd p1
vagrant up
```

---

## Partie 2 (P2) - Applications et services

### Objectifs
- Déployer **3 applications web** sur le cluster
- Configurer un **Ingress Controller** pour le routage
- Gérer les **réplicas** (3 réplicas pour app2)

### Services déployés
- **App 1** : `app1.com`
- **App 2** : `app2.com` (3 réplicas)
- **App 3** : Default backend (toutes les autres requêtes)
- **IP Cluster** : `192.168.56.110`

### Déploiement
```bash
cd p2
vagrant up
# Accès via curl -H "Host: app1.com" http://192.168.56.110
```

---

## Partie 3 (P3) - K3d et Argo CD

### Objectifs
- Utiliser **K3d** (Kubernetes léger dans Docker) au lieu de VMs lourdes
- Mettre en place une approche **GitOps** avec Argo CD
- Déployer une application avec **gestion de version** (v1/v2)

### Infrastructure
- **Cluster** : K3d (1 node local)
- **CD** : Argo CD
- **Namespaces** : `argocd`, `dev`

### Installation et Déploiement
```bash
# 1. Installer les outils (Docker, K3d, kubectl, ArgoCD CLI)
bash p3/scripts/install.sh

# 2. Configurer le cluster et déployer l'application
bash p3/scripts/setup.sh
```

### Vérification
- **Argo CD** : `https://localhost:8080` (admin / password affiché par le script)
- **Application** : `http://localhost:8888`
- **Mise à jour** : Modifier `deployment.yaml` (v1 -> v2), push git, Argo CD synchronise automatiquement.

---

## Bonus - Gitlab Local + Argo CD

### Objectifs
- Héberger **Gitlab en local** dans le cluster Kubernetes
- Configurer Argo CD pour utiliser ce Gitlab interne (CI/CD 100% offline)
- Simuler un environnement d'entreprise complet

### Infrastructure
- **Cluster** : K3d
- **Services** : Gitlab (Helm), Argo CD, App de démo
- **Namespaces** : `gitlab`, `argocd`, `dev`

### Installation et Déploiement
> ⚠️ Nécessite des ressources importantes (4GB+ RAM)

```bash
# 1. Installer les outils (+ Helm)
bash bonus/scripts/install.sh

# 2. Configurer tout l'environnement
bash bonus/scripts/setup.sh
```

### Vérification
- **Gitlab** : `http://localhost:8181` (root / `iot-bonus-42`)
- **Argo CD** : `https://localhost:8080`
- **Application** : `http://localhost:8888`
- **Workflow** : Push sur le Gitlab local -> Argo CD détecte -> Déploiement auto.

---

## Commandes utiles

### Gestion K3d
```bash
# Créer/Supprimer un cluster
k3d cluster create iot
k3d cluster delete iot

# Lister les clusters
k3d cluster list
```

### Debugging Argo CD
```bash
# Port-forward manuel si besoin
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Logs
```bash
# Logs d'un pod
kubectl logs -f <pod-name> -n <namespace>
```

## Auteur
Alexandre Pommier (apommier) - École 42

## Licence
Projet académique - École 42