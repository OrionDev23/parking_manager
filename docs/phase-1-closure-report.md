# Parcoto — Rapport de clôture Phase 1 : architecture Véhicules

**Date :** 22 novembre 2026  
**Branche :** `refactor/foundation-v1`  
**Projet Appwrite audité :** `essais` / base `Parking`

## Statut

**Phase 1 — conception et contrats techniques : terminée.**  
**Déploiement du nouveau schéma : non commencé volontairement.**

Les modèles, relations, contrats Appwrite/SQLite, règles de synchronisation et stratégie de migration sont écrits et versionnés. Aucune nouvelle table n'a été créée dans la base de production, aucune donnée métier n'a été modifiée et aucune migration locale n'a été appliquée.

## Livrables

| Livrable | Contenu |
|---|---|
| [Modèle de domaine v1](vehicle-domain-model-v1.md) | Décisions produit, entités, relations, états, GPS, confidentialité et roadmap |
| [Contrat Appwrite v1](vehicle-appwrite-schema-v1.md) | Tables, colonnes, types, indexes, ACL, transaction et API serveur |
| [Contrat SQLite / Sync v1](vehicle-offline-sync-contract-v1.md) | Cache, outbox, atomicité, idempotence, dépendances, conflit, pull et tests |
| [Matrice legacy v1](vehicle-legacy-migration-map-v1.md) | Correspondances de champs, conversions, données ambiguës et dry-run |

## Vérifications réelles effectuées

### Appwrite — base Parking

- 33 tables présentes au moment de l'audit.
- La table `vehicle` conserve son ID historique `6531ad22153b2a49ca2c`.
- `vehicle` et `chauffeur` ont `companyId` et Row Security activé, sans permission générale table.
- L'index unique composé `(companyId, matricule)` est actif.
- L'ancien index unique `numero_serie` est en échec et ne peut pas garantir l'unicité VIN.
- La colonne `marque` a été élargie à 64 caractères lors du correctif antérieur ; la cible canonique devient `makeId`.
- Le catalogue partagé `vehicle_makes` compte 211 marques au moment de l'audit.
- Aucune ressource dédiée `sites`, `parking_*`, `vehicle_assignments` ou `tracking_*` n'existe encore.

### Dry-run véhicules — lecture seule

La table Appwrite `vehicle` a retourné une ligne au moment du passage :
- payload JSON présent ;
- plaque et numéro de châssis présents ;
- valeur legacy de marque `"3"` résolue vers l'ID stable `renault` à l'aide du catalogue/version historique ;
- aucun doublon de plaque/VIN dans ce jeu de données ;
- `siteId` et `revision` absents.

Ce dry-run ne couvre pas les bases SQLite des postes utilisateurs. Leur export local reste nécessaire avant tout backfill global.

### SQLite / synchronisation — constat bloquant identifié

Le code actuel de `VehicleRepositoryImpl` enregistre la mutation dans l'outbox, puis écrit la fiche locale dans un second appel. Ces opérations ne partagent pas de transaction SQLite. Le contrat v1 impose un write atomique fiche + outbox avant de continuer les évolutions du modèle.

Autres règles formalisées :
- IDs stables et outbox partitionnée par companyId ;
- idempotence par operationId ;
- dépendances parent/enfant ;
- revisions serveur pour détecter les écrasements concurrentiels ;
- conflits résolus explicitement, pas de retry global aveugle ;
- positions GPS envoyées par lots avec déduplication fixId ;
- Web reste online-only dans le périmètre actuel, tandis que le natif utilise SQLite offline-first.

## Décisions d'architecture verrouillées

1. `vehicle` contient l'identité et les caractéristiques stables, pas toutes les relations historiques.
2. Marque et modèle utilisent des IDs stables, jamais des index de liste.
3. Le titulaire de la carte grise et les snapshots de documents sont historisés séparément des caractéristiques du véhicule.
4. Conducteurs et véhicules sont liés par `vehicle_assignments` historisées.
5. Smartphone, conducteur, véhicule et session GPS sont des ressources distinctes.
6. Position observée et place de parking attendue sont deux concepts différents.
7. Kilométrage et heures moteur sont des relevés historisés.
8. Documents, médias, maintenance, coûts et événements ont leurs propres ressources.
9. Chaque ressource opérationnelle possède un companyId et des ACL contrôlées côté serveur.
10. Les migrations sont additives, réversibles autant que possible et conservant les IDs historiques.

## Points qui restent des gates avant mise en production

### Gate A — données locales et dry-run complet
- Obtenir un export SQLite anonymisé de chaque version/plateforme concernée.
- Vérifier les payloads, conflits outbox, doublons et valeurs legacy.
- Produire un rapport par companyId et un plan de backfill idempotent.
- Ne jamais déduire un tenant depuis createdBy.

### Gate B — sémantique des champs ambigus
Les significations de `decision`, `service`, `etat`, `etatactuel`, `ownership`, `driverOwnership`, `filliale`, `emplacement` et `perimetre` doivent être confirmées à partir des usages et des données. La matrice migration précise les décisions interdites tant que la sémantique n'est pas établie.

### Gate C — GPS et données personnelles en Algérie
- Le décret 09-410 classe certaines catégories de radio-positionnement/radiolocalisation satellite et de positionnement via réseaux mobiles comme équipements sensibles. Le smartphone intégré n'est pas déclaré automatiquement exempt dans cette spécification.
- Obtenir une confirmation écrite des autorités compétentes sur le cas d'usage exact smartphone/GNSS/app flotte.
- La loi 25-11 ajoute la localisation et les déplacements à la définition du profilage et introduit un registre général des traitements ainsi qu'un carnet automatisé des opérations.
- L'article 44 de la loi 18-07 encadre le transfert international de données. Le endpoint Appwrite configuré en région `fra` impose une revue du transfert pour les données personnelles existantes, pas uniquement pour le GPS.
- Aucun tracking de conducteur n'est activé dans cette phase.

### Gate D — staging technique
- Créer les tables et indexes dans un environnement de validation isolé.
- Tester Row Security, ACL et accès direct hors UI entre deux entreprises.
- Tester quota, transactions, receipts, retry après ACK perdu et réconciliation.
- Tester migrations SQLite depuis le schéma v11.
- Exécuter Flutter analyze et tests d'intégration sur l'environnement de développement.

## Ce qui n'a pas été fait

- Aucune table ou colonne nouvelle n'a été ajoutée à Appwrite.
- Aucune permission ou rowSecurity de production n'a été modifiée.
- Aucun champ legacy n'a été supprimé.
- Aucun backfill ni modification de véhicule n'a été exécuté.
- Aucune migration SQLite n'a été codée/appliquée.
- Aucune collecte GPS n'a été activée.

## Recommandation pour la suite

Avant de refaire l'interface (phase 2), réaliser un sprint technique de mise en place :
1. implémenter la transaction SQLite atomique mutation + outbox ;
2. implémenter les migrations version 12+ et leurs tests ;
3. créer les tables de base `sites` et `vehicle_assignments` dans l'environnement de staging ;
4. ajouter la validation serveur tenant/relation/revision ;
5. exécuter le dry-run complet et valider la migration.

Une fois ce socle passé, la nouvelle interface pourra être construite sur un contrat stable, sans devoir réécrire le formulaire lorsque GPS et Parking seront ajoutés.
