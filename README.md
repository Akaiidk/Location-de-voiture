# 🚗 Système de Gestion de Location de Voitures (PL/SQL)

Ce projet est une solution de gestion de base de données pour une agence de location de véhicules, développée entièrement en **PL/SQL** (Oracle). Il permet de gérer le cycle complet d'une location, de la gestion du parc automobile au suivi des réservations et des clients.

## 📌 Fonctionnalités

Le système intègre plusieurs modules clés gérés par des procédures, fonctions et triggers :

- **Gestion du Parc Automobile** : Ajout, modification et suivi de l'état des véhicules (disponible, loué, en maintenance).
- **Gestion des Clients** : Enregistrement des clients et suivi de leur historique de location (clients classiques et VIP).
- **Processus de Réservation** : Création de contrats, calcul automatique des tarifs et vérification de la disponibilité.
- **Automatisation via Triggers** : 
    - Mise à jour automatique du statut des voitures.
    - Calcul des pénalités en cas de retard.
    - Historisation des transactions.
- **Reporting & Statistiques** : Fonctions permettant de générer des rapports sur le chiffre d'affaires et l'utilisation des véhicules.

## 🛠️ Technologies utilisées

* **Langage :** PL/SQL (Oracle Database)
* **Outils :** SQL Developer / SQL*Plus
* **Modélisation :** Schéma Relationnel (Modèle Entité-Association)
