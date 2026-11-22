# Parcoto — Rapport de clôture Phase 1 : architecture Véhicules

**Date :** 22 novembre 2026  
**Branche :** `refactor/foundation-v1`  
**Projet Appwrite audité :** `essais` / base `Parking`

## Statut

**Phase 1 — conception et contrats techniques : terminée.**  
**Premier sprint d'implémentation locale : partiellement réalisé sur la branche de travail.**  
**Déploiement du nouveau schéma Appwrite : non commencé volontairement.**

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

### SQLite / synchronisation — socle atomique implémenté, CI validée

Le correctif couvre les trois chemins natifs local-first identifiés :

- **Véhicules** : create/update/delete utilisent la transaction commune fiche + outbox.
- **Chauffeurs** : create/update/delete utilisent la même abstraction et la source locale refuse les écritures d'un autre companyId.
- **Stock legacy** : save/delete synchronisent dans une transaction unique le cache `legacy_module_cache` et l'outbox. La configuration de runtime fournit à ce service la même instance `LocalDatabase`/queue que le moteur de synchronisation.
- **Dispatch** : l'entité `storage`, déjà présente dans le registre du service Stock, est maintenant aussi reliée à son handler dans le moteur.

La migration SQLite v12 ajoute `payload_version`, `idempotency_key`, `next_attempt_at`, `last_error_code`, `last_error_message` et `completed_at`. Les opérations historiques gardent leur ID, payload, statut et compteur de tentatives ; l'ID est repris comme clé d'idempotence. La migration v12 est codée, additive et testée sur une structure v11 isolée, mais elle n'a pas été appliquée sur les bases des postes utilisateurs.

Le moteur de synchronisation utilise désormais `next_attempt_at` avec backoff exponentiel, jitter déterministe et plafond d'une heure. Les rejets permanents deviennent des conflits ; les messages enregistrés pour les erreurs transitoires sont génériques et bornés.

**Validation GitHub Actions :**
- Le premier lot véhicule/v12 a passé `flutter test`, `flutter analyze --no-pub`, `flutter build web --release` et `node --check appwrite/functions/company-tenant-api/src/index.js`.
- Le lot qui inclut chauffeurs, Stock legacy, le handler `storage` et les documents actualisés a également passé les quatre étapes sur le commit `149a4434`.
- Un run antérieur du test Stock avait échoué à cause d'un import manquant de `SyncOperation` et `SyncOperationType`. L'import a été ajouté dans `984b360e`, puis le lot complet a été validé.

Aucune table Appwrite de production n'a été créée/modifiée et aucune donnée métier n'a été réécrite dans ce sprint.
  
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

### Gate D — environnement Appwrite de validation

- Le projet actuellement connecté est `essais`, nommé **Parcoto**, statut actif, région `fra`.
- Le projet ne déclare aucun environnement Appwrite isolé (`environments: []`) ; la base `Parking` inspectée est la base active, pas un staging démontré.
- Créer ou désigner un projet Appwrite de staging séparé, avec sa propre base TablesDB, son propre endpoint/configuration et ses équipes de test.
- Ne pas créer `sites`, `vehicle_assignments` ou les autres nouvelles tables dans le projet actif pour simuler un staging.
- Tester Row Security, ACL et accès direct hors UI entre deux entreprises dans le projet de staging.
- Tester quota, transactions, receipts, retry après ACK perdu et réconciliation.
- Tester migrations SQLite depuis le schéma v11.
- Exécuter Flutter analyze, tests d'intégration et build Web sur l'environnement de validation.

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
- La migration SQLite v12 est codée, mais elle n'a pas encore été appliquée sur les bases des postes utilisateurs.
- Aucune collecte GPS n'a été activée.

## Recommandation pour la suite

Le premier sprint local-first est engagé. L'ordre restant est :
1. obtenir une exécution CI verte incluant `flutter test`, `flutter analyze` et le build Web ;
2. traiter toute erreur détectée avant de continuer ;
3. vérifier la migration v12 sur une copie d'une base réelle, avec sauvegarde et rapport de conservation des opérations ;
4. étendre le pattern atomique uniquement aux futurs repositories local-first qui seront ajoutés ;
5. créer `sites` et `vehicle_assignments` dans un environnement Appwrite de staging, puis valider les ACL et les contrôles inter-tenant ;
6. seulement après validation, préparer la migration des données réelles.

La refonte du formulaire reste en attente de ce socle. Elle pourra alors utiliser les contrats de données définis sans reconstituer les relations au milieu du travail UI.
