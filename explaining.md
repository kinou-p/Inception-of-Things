# Inception-of-Things — Le DevOps expliqué simplement

Ce document a pour but de vulgariser les concepts du projet pour un développeur qui ne connaît pas encore l'infrastructure ou Kubernetes.

---

## 🏗️ L'idée générale
Avant, pour mettre une application en ligne, on installait tout à la main sur un serveur : la base de données, le code, les dépendances. Si le serveur plantait, c'était la panique.

Aujourd'hui, on utilise des **Conteneurs** (via Docker) pour emballer les applications, et **Kubernetes** pour les gérer (les "orchestrer"). Kubernetes s'assure que les applications tournent toujours, redémarrent si elles plantent, et peuvent gérer beaucoup de trafic.

Ce projet apprend à construire cette infrastructure de A à Z.

---

## 1️⃣ Partie 1 : Les fondations (Vagrant & K3s)

### Le Problème
On veut créer un cluster Kubernetes sécurisé avec plusieurs serveurs qui discutent entre eux, mais on n'a qu'un seul ordinateur.

### La Solution
On utilise **Vagrant**. C'est un outil qui permet de créer des **Machines Virtuelles (VM)** par code.
- On écrit un fichier (`Vagrantfile`) qui dit : "Je veux 2 serveurs Ubuntu avec telle IP et telle mémoire".
- On tape `vagrant up` et hop, les serveurs apparaissent.

Ensuite, on installe **K3s**. C'est une version ultra-légère de Kubernetes (pour l'IoT ou le dev).
- **Master Node (Chef d'orchestre)** : Il donne les ordres.
- **Worker Node (Ouvrier)** : Il exécute les applications.
Dans la P1, on connecte manuellement le Worker au Master.

👉 **En résumé** : On a construit notre propre mini-datacenter virtuel avec 2 serveurs.

---

## 2️⃣ Partie 2 : Le Routage & la Disponibilité

### Le Problème
On a plusieurs applications (Site A, Site B, API). Mais on n'a qu'une seule adresse IP d'entrée. Comment diriger les visiteurs au bon endroit ? Et si le Site B est très populaire, comment gérer la charge ?

### La Solution
1. **Application Replication** : On demande à Kubernetes de lancer **3 copies** de la même application (App 2). Si une copie plante, les 2 autres prennent le relais. Kubernetes répartit automatiquement le trafic entre les 3 (Load Balancing).

2. **Ingress (Le Réceptionniste)** : C'est un composant qui se place à l'entrée du cluster. Il lit l'adresse demandée par le visiteur (`app1.com`) et l'envoie vers la bonne application.
   - `app1.com` ➡️ App 1
   - `app2.com` ➡️ App 2 (l'une des 3 copies)
   - Tout le reste ➡️ App 3

👉 **En résumé** : On a rendu nos applications accessibles proprement et robustes (haute disponibilité).

---

## 3️⃣ Partie 3 : L'Automatisation Moderne (GitOps & Argo CD)

### Le Problème
Gérer des machines virtuelles (Vagrant) c'est lourd et lent. Et mettre à jour les applications manuellement (se connecter au serveur, taper des commandes) c'est risqué et source d'erreurs.

### La Solution
1. **K3d (Kubernetes dans Docker)** : Au lieu de simuler des ordinateurs entiers (VMs), on simule les nœuds Kubernetes *dans* des conteneurs Docker. C'est ultra-rapide (se lance en 30 secondes) et ne consomme rien.

2. **GitOps avec Argo CD** : C'est la révolution moderne.
   - On ne touche plus jamais au cluster directement.
   - On décrit l'état voulu dans un dépôt **Git** (fichiers YAML).
   - **Argo CD** est un "robot" installé dans le cluster. Il surveille le Git en permanence.
   - Si tu changes une ligne dans Git (ex: version v1 ➡️ v2), Argo CD le voit et met à jour l'application automatiquement dans le cluster.

👉 **En résumé** : On a un environnement de développement ultra-rapide et un déploiement 100% automatisé. On pousse du code, et ça part en prod tout seul.

---

## 🎁 Bonus : L'Indépendance Totale (Gitlab Local)

### Le Problème
Dépendre de GitHub (cloud) c'est bien, mais certaines entreprises veulent tout garder chez elles (on-premise) pour la sécurité.

### La Solution
On installe notre propre **Gitlab** (équivalent de GitHub) directement *dans* notre cluster Kubernetes.
- Le code est stocké localement.
- Argo CD discute avec ce Gitlab local.
- Tout tourne sur ta machine, sans internet.

👉 **En résumé** : On simule une infrastructure d'entreprise complète et souveraine.
