# Inception-of-Things (IoT) - École 42

## Description
Inception-of-Things est un projet de l'École 42 qui introduit aux technologies DevOps modernes, particulièrement Kubernetes, Docker, et l'orchestration de conteneurs. Ce projet utilise K3s (Kubernetes léger) avec Vagrant pour créer et gérer des clusters Kubernetes.

## Objectifs pédagogiques
- Découvrir **Kubernetes** et l'orchestration de conteneurs
- Maîtriser **K3s** (version allégée de Kubernetes)
- Comprendre les **concepts DevOps** (IaC, CI/CD)
- Gérer l'**infrastructure as Code** avec Vagrant
- Apprendre le **déploiement d'applications** conteneurisées
- Mettre en place des **services réseau** et load balancing

## Architecture du projet

### Structure générale
```
Inception-of-Things/
├── p1/                  # Partie 1 - Cluster K3s simple
│   ├── Vagrantfile     # Configuration VMs
│   └── scripts/        # Scripts d'installation
├── p2/                  # Partie 2 - Applications et services
│   ├── Vagrantfile     # Configuration avancée
│   ├── confs/          # Configurations Kubernetes
│   └── scripts/        # Scripts de déploiement
└── README.md           # Documentation
```

## Partie 1 (P1) - Cluster K3s basique

### Objectifs
- Créer un cluster K3s avec **2 machines virtuelles**
- Configurer un **master node** et un **worker node**
- Établir la **communication inter-nodes**

### Infrastructure
- **VM Master (apommierS)** : `192.168.56.110`
  - Rôle : Control plane K3s
  - RAM : 2048 MB
  - CPU : 2 cores
  
- **VM Worker (apommierSW)** : `192.168.56.111`
  - Rôle : Worker node
  - RAM : 2048 MB  
  - CPU : 2 cores

### Technologies utilisées
- **Vagrant** : Orchestration des VMs
- **VirtualBox** : Hyperviseur
- **K3s** : Distribution Kubernetes légère
- **Ubuntu 18.04** : OS des VMs

## Partie 2 (P2) - Applications et services

### Objectifs
- Déployer des **applications web** sur le cluster
- Configurer des **services Kubernetes**
- Mettre en place du **load balancing**
- Gérer les **ressources** et **namespaces**

### Services déployés
- **Applications web** personnalisées
- **Ingress controller** pour le routage
- **Load balancer** pour la répartition de charge
- **Services** avec exposition externe

## Installation et déploiement

### Prérequis
- **Vagrant** 2.2+
- **VirtualBox** 6.0+
- **Git** pour cloner le projet
- **8GB RAM** minimum disponible

### Installation
```bash
git clone <repository-url>
cd Inception-of-Things
```

### Déploiement P1
```bash
cd p1
vagrant up
```

### Vérification P1
```bash
# Connexion au master
vagrant ssh apommierS

# Vérifier les nodes
kubectl get nodes

# Vérifier les pods système
kubectl get pods -A
```

### Déploiement P2
```bash
cd ../p2
vagrant up
```

### Vérification P2
```bash
# Vérifier les applications
kubectl get deployments

# Vérifier les services
kubectl get services

# Tester l'accès aux applications
curl http://192.168.56.110
```

## Scripts d'automatisation

### P1 - Scripts de base
- `k3s-master.sh` : Installation et configuration du master
- `k3s-worker.sh` : Installation et jointure du worker

### P2 - Scripts avancés
- `deploy-apps.sh` : Déploiement des applications
- `setup-ingress.sh` : Configuration du routage
- `configure-services.sh` : Setup des services

## Configuration Kubernetes

### Exemple de déploiement d'application
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web
        image: nginx:alpine
        ports:
        - containerPort: 80
```

### Service avec LoadBalancer
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: web-app
```

## Concepts Kubernetes abordés

### Ressources de base
- **Pods** : Unité de déploiement minimale
- **Deployments** : Gestion des réplicas d'applications
- **Services** : Exposition et découverte de services
- **ConfigMaps** : Configuration externalisée
- **Secrets** : Gestion des données sensibles

### Réseau et routage
- **Ingress** : Routage HTTP/HTTPS
- **Network Policies** : Sécurité réseau
- **LoadBalancer** : Répartition de charge
- **ClusterIP** : Communication interne

### Gestion des ressources
- **Namespaces** : Isolation logique
- **Resource Quotas** : Limitation des ressources
- **Limits et Requests** : Gestion mémoire/CPU

## Commandes utiles

### Gestion des VMs
```bash
# Démarrer les VMs
vagrant up

# Arrêter les VMs
vagrant halt

# Supprimer les VMs
vagrant destroy

# Recharger la configuration
vagrant reload
```

### Debugging Kubernetes
```bash
# Logs des pods
kubectl logs <pod-name>

# Description détaillée
kubectl describe pod <pod-name>

# Shell dans un pod
kubectl exec -it <pod-name> -- /bin/bash

# Événements du cluster
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Monitoring
```bash
# Utilisation des ressources
kubectl top nodes
kubectl top pods

# État du cluster
kubectl cluster-info

# Services exposés
kubectl get endpoints
```

## Résolution de problèmes

### Problèmes courants
- **Nodes NotReady** : Vérifier la connectivité réseau
- **Pods Pending** : Vérifier les ressources disponibles
- **Services inaccessibles** : Vérifier les labels et selectors
- **Images non trouvées** : Vérifier les registry et tags

### Logs système
```bash
# Logs K3s sur le master
sudo journalctl -u k3s

# Logs K3s sur le worker
sudo journalctl -u k3s-agent

# Logs Vagrant
vagrant up --debug
```

## Sécurité et bonnes pratiques

### Configurations recommandées
- **RBAC** activé par défaut
- **Network policies** pour l'isolation
- **Resource limits** pour éviter la famine
- **Secrets** pour les données sensibles
- **Image policies** pour la sécurité

### Optimisations
- **Resource requests** appropriées
- **Health checks** (readiness/liveness)
- **Rolling updates** pour les déploiements
- **Horizontal Pod Autoscaling** si nécessaire

## Extensions possibles

### Bonus et améliorations
- **Monitoring** avec Prometheus/Grafana
- **Logging** centralisé avec ELK Stack
- **CI/CD** avec GitLab/Jenkins
- **Service Mesh** avec Istio
- **Storage** persistant avec volumes

### Intégrations
- **Helm** pour la gestion de packages
- **ArgoCD** pour GitOps
- **Cert-Manager** pour les certificats TLS
- **External-DNS** pour la gestion DNS

## Compétences développées
- **Infrastructure as Code** avec Vagrant
- **Orchestration de conteneurs** avec Kubernetes
- **Administration système** Linux
- **Networking** et services distribués
- **Troubleshooting** d'infrastructures complexes
- **DevOps** et automatisation
- **Monitoring** et observabilité

## Architecture réseau

### Schéma de déploiement
```
    ┌─────────────────────────────────────┐
    │           Host Machine              │
    │  ┌─────────────┐  ┌─────────────┐   │
    │  │ Master Node │  │ Worker Node │   │
    │  │ 192.168.56. │  │ 192.168.56. │   │
    │  │    110      │  │    111      │   │
    │  │             │  │             │   │
    │  │   K3s API   │  │   K3s Agent │   │
    │  │   Server    │  │             │   │
    │  └─────────────┘  └─────────────┘   │
    └─────────────────────────────────────┘
```

## Tests et validation

### Tests de fonctionnement
```bash
# Test connectivité entre nodes
kubectl get nodes -o wide

# Test déploiement d'application
kubectl create deployment test-nginx --image=nginx
kubectl expose deployment test-nginx --port=80 --type=NodePort

# Test scaling
kubectl scale deployment test-nginx --replicas=3
```

### Métriques de succès
- ✅ Cluster K3s opérationnel
- ✅ Communication inter-nodes
- ✅ Applications déployées et accessibles
- ✅ Load balancing fonctionnel
- ✅ Pas d'erreurs dans les logs

## Documentation officielle
- [K3s Documentation](https://docs.k3s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Vagrant Documentation](https://www.vagrantup.com/docs)

## Auteur
Alexandre Pommier (apommier) - École 42

## Licence
Projet académique - École 42

---

*"Introduction pratique à l'orchestration moderne"* ☸️🚀