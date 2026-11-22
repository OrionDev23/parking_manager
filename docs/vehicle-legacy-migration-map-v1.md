# Parcoto — Matrice de migration des véhicules legacy v1

**Statut :** plan de migration et de réconciliation  
**Source de vérité auditée :**
- `lib/serializables/vehicle/vehicle.dart`
- `lib/domain/entities/vehicle.dart`
- `lib/data/mappers/vehicle_mapper.dart`
- `lib/data/remote/vehicles/appwrite_vehicle_source.dart`
- table Appwrite `vehicle` / `6531ad22153b2a49ca2c`
- table SQLite locale `vehicles` + colonne `payload`

> Cette matrice n'est pas un script de migration. Elle distingue la correspondance technique observable des décisions métier encore à confirmer. Aucune valeur ambiguë ne doit être convertie automatiquement en état, relation ou affectation.

---

## 1. Ordre de lecture des données existantes

La lecture Appwrite actuelle suit cet ordre :

1. Vérifier que la ligne a le `companyId` du contexte.
2. Si `payload` est une chaîne JSON valide, reconstruire le modèle depuis ce payload.
3. Si `payload` est un objet, reconstruire le modèle depuis cet objet.
4. Sinon, convertir les colonnes historiques Appwrite (`matricule`, `numero_serie`, `marque`, etc.) vers le modèle domaine.

L'écriture distante actuelle :
- écrit les attributs sous leurs noms legacy ;
- conserve `companyId` et `siteId` ;
- stocke le modèle complet en JSON dans `payload`.

La migration doit donc traiter **les colonnes directes et le payload**, avec une priorité définie :
- le payload est la source la plus complète pour le modèle local-first récent ;
- les colonnes directes sont les valeurs legacy exploitées par l'ancien code et certains index ;
- en cas de divergence entre payload et colonne, ne pas choisir silencieusement : rapporter le champ, la ligne et la valeur de chaque source dans le dry-run.

Les ID de lignes Appwrite et SQLite sont conservés. Le `companyId` d'une ligne véhicule est la clé de partition de cette migration.

---

## 2. Matrice des champs historiques

### 2.1 Identification, immatriculation et carte grise

| Champ legacy | Où il est observé | Cible proposée | Règle de migration |
|---|---|---|---|
| `id` / `$id` | Appwrite row ID, legacy entity ID | `vehicle.$id` | Conserver à l'identique. |
| `companyId` | colonne Appwrite / domaine | `vehicle.companyId` | Conserver ; obligatoire ; ne jamais recalculer depuis le créateur. |
| `siteId` | colonne Appwrite / domaine | `vehicle.siteId` | Conserver si la relation site est valide ; sinon mettre dans le rapport de reconciliation. |
| `matricule` | Appwrite + legacy | `registrationNumber` | Conserver la valeur brute ; créer registrationNormalized avec un normaliseur testé et pays connu. |
| `martricule_etrang` / `matriculeEtrang` | Appwrite + legacy | `registrationKind` | true → foreign ; false → national uniquement après vérification de la signification fonctionnelle. |
| `pays` | Appwrite + legacy | `registrationCountry` | Normaliser en ISO alpha-2 seulement si la valeur est reconnue. DZ par défaut uniquement sur nouvelle saisie algérienne, pas en réécriture silencieuse des données historiques. |
| `numero_serie` / `numeroSerie` | Appwrite + legacy | `vin` | Copier sans inventer ; normaliser dans vinNormalized ; collisions à examiner. |
| `date` / `registrationDate` | Appwrite integer + legacy DateTime | `vehicle_registration_records.issuedAt` ou `firstRegistrationDate` selon confirmation métier | Le mapper l'appelle registrationDate mais l'origine métier doit être confirmée : date du titre, date d'immatriculation ou première mise en circulation. Conserver rawLegacyDate pendant audit. |
| `wilaya` | Appwrite integer + legacy | `vehicle_registration_records.registrationWilayaCode` ou adresse de référence | Conserver le code sans conversion de libellé non vérifiée. |
| `commune` | Appwrite string + legacy | `vehicle_registration_records.registrationCommune` | Conserver comme texte legacy ; normalisation territoriale séparée. |
| `daira` | Appwrite string + legacy | `vehicle_registration_records.registrationDaira` | Conserver. |
| `adresse` / `address` | Appwrite + domaine | `vehicle_registration_records.registrationAddress` | Ne pas confondre adresse du titulaire, adresse administrative et site d'exploitation. |
| `numero` / `receiptNumber` | Appwrite + domaine | `vehicle_registration_records.receiptNumber` | Conserver comme référence de quittance/justificatif, confirmer le type de document. |
| `quittance` / `receiptAmount` | Appwrite double + domaine | `vehicle_registration_records.receiptAmountMinor` après contrôle de devise/unité | Ne pas convertir un double en montant mineur sans connaître si la valeur est DA, centimes ou autre. Garder la valeur legacy exacte dans le rapport. |
| `nom` / `ownerLastName` | Appwrite + domaine | `vehicle_registration_records.registeredOwnerLastName` | Donnée personnelle de titulaire de carte grise ; accès et rétention adaptés. |
| `prenom` / `ownerFirstName` | Appwrite + domaine | `vehicle_registration_records.registeredOwnerFirstName` | Même règle. |
| `profession` / `ownerProfession` | Appwrite + domaine | `vehicle_registration_records.registeredOwnerProfession` | Ne pas confondre profession du titulaire et profession du conducteur. |

### 2.2 Marque, modèle et caractéristiques techniques

| Champ legacy | Cible | Règle |
|---|---|---|
| `marque` / `brand` | `makeId` | Convertir index historique, nom, alias ou slug vers l'ID stable `vehicle_makes.$id`. Préserver valeur brute. Valeur numérique inconnue → revue manuelle, ne pas slugifier le chiffre. |
| `type` | `vehicleClass` ou `modelName` selon usages | Ambigu : le champ est utilisé comme un texte et la signification dépend du formulaire. Examiner les valeurs distinctes et les écrans qui le lisent avant conversion. |
| `genre` | `legalGenreCode` | Garder la valeur légale telle qu'enregistrée ; créer une table de référence/label séparée au besoin. |
| `trim` | `modelVariant` | Correspondance directe. |
| `modelYear` | `modelYear` | Correspondance directe si valeur valide. |
| `annee_util` / `usageYear` | `manufactureYear` ou année d'usage | Ne pas fusionner avec modelYear sans établir ce que l'ancien formulaire enregistrait. Conserver raw. |
| `energie` / `energy` | `fuelType` | Mapper via table de correspondance validée (essence/petrol, diesel, GPL, hybride, électrique). Valeur inconnue conservée comme legacy. |
| `carrosserie` / `body` | `bodyStyle` | Mapper seulement les valeurs connues ; garder raw. |
| `color` | `color` | Correspondance directe. |
| `engineDisplacement` | `engineCapacityCc` | Correspondance directe si unité cm³ confirmée. |
| `enginePowerKw` | `enginePowerKw` | Correspondance directe. |
| `enginePowerHp` | `enginePowerHp` temporaire ou conversion explicitement définie | Ne pas confondre HP et puissance fiscale. Conserver séparément si la donnée est utilisée. |
| `puissance` / `fiscalPower` | `fiscalPowerCv` | Ne pas convertir en kW moteur ; c'est une donnée distincte. |
| `engineCode` | `engineCode` | Correspondance directe. |
| `transmission` / `gearbox` | `transmissionType` et/ou `gearbox` | Les deux propriétés existent dans le payload ; comparer les valeurs. Ne pas jeter l'une si elles diffèrent. |
| `driveType` | `driveType` | Correspondance directe si valeur normalisable. |
| `doors` | `doorCount` | Correspondance directe. |
| `placesAssises` / `seats` | `seatCount` | Correspondance directe. |
| `charge_utile` / `usefulLoad` | `payloadKg` | Confirmer unité et sémantique ; conserver raw. |
| `poids_total` / `totalWeight` | `grossWeightKg` | Confirmer qu'il s'agit du poids total autorisé/chargé ; conserver raw. |
| `lengthMm`, `widthMm`, `heightMm` | mêmes propriétés | Correspondance directe en millimètres. |
| `lourd` / `heavy` | candidat calculé depuis vehicleClass / type de poids lourd | Ne pas migrer comme vérité indépendante si ce booléen est dérivable ; rapporter les cas contradictoires. |

### 2.3 Exploitation, affectation et état

| Champ legacy | Cible proposée | Règle de migration |
|---|---|---|
| `matriculeConducteur` / `driverRegistration` | `vehicle_assignments.driverId` | Résoudre la plaque conducteur uniquement dans le même companyId. Créer une affectation historique seulement si une ligne chauffeur unique est trouvée et si la date de début peut être déterminée. Sinon garder la donnée en legacyReview. |
| `appartenanceconducteur` / `driverOwnership` | Champ de note/qualité d'affectation après interprétation | Ne pas supposer qu'il s'agit d'un ID de conducteur. Les valeurs peuvent être labels ou catégories. |
| `vehicules` côté chauffeur | relation inverse de vehicle_assignments | Ne plus utiliser comme source canonique ; réconcilier en comparant les deux côtés et conserver les anomalies. |
| `emplacement` / `location` | `vehicle_parking_assignments` seulement si une vraie place résolue ; sinon `legacyLocationText` temporaire | Un texte libre n'est pas un parkingSpaceId. Ne pas créer un parking/une place automatiquement depuis le texte. |
| `perimetre` / `perimeter` | information legacy à classifier | Ce champ ne prouve ni une géofence ni une zone de parking ; conserver dans legacyReview jusqu'à définition métier. |
| `siteId` | `sites.$id` | Garder si l'ID existe et appartient au tenant. Ne pas déduire du nom de filiale/direction. |
| `filliale` / `subsidiary` | unité organisationnelle / site proposé | Orthographe historique ; ne pas mapper automatiquement à siteId. Créer un alias organisationnel si l'entreprise confirme la hiérarchie. |
| `direction` | unité organisationnelle | Garder séparé de site. |
| `departement` / `department` | unité organisationnelle | Garder séparé de site. |
| `appartenance` / `ownership` | propriété juridique/gestion à définir | Peut signifier propriété, service ou affectation. Ne pas mapper automatiquement à acquisitionType. |
| `etat` / `state` | candidat `lifecycleStatus` ou libellé d'état | Le code ne documente pas suffisamment le dictionnaire métier. Conserver raw et classifier par valeur observée. |
| `etatactuel` / `currentState` | `operationalStatus` candidat | Code entier dont le dictionnaire doit être extrait de l'écran de gestion des états et de ses tables. Ne pas inventer le mapping. |
| `service` | `usageProfile=service` possible | Confirmer s'il s'agit d'un véhicule de service, d'un drapeau d'activité ou d'un état. |
| `decision` | legacyReview | Sens métier non démontré. Ne pas mapper en statut ni supprimer. |
| `createdBy` / `user_creation` | `createdBy` | Garder comme audit uniquement ; ne jamais utiliser pour déduire companyId. |
| `createdAt`, `updatedAt` | mêmes timestamps | Utiliser les métadonnées Appwrite lorsque présentes ; préserver le payload en cas de date manquante. |

### 2.4 Acquisition, documents, photos et maintenance

| Champ legacy | Cible | Règle |
|---|---|---|
| `acquisitionType` | `acquisitionType` | Correspondance directe après normalisation des valeurs. |
| `acquisitionDate` | `acquisitionDate` | Parser date ISO ; valeur invalide reste en legacyReview. |
| `purchasePrice` | `purchaseAmountMinor` | Convertir uniquement après confirmation de la devise et de l'échelle décimale. |
| `supplier` | `supplierId` | Résoudre fournisseur par ID dans le tenant si possible ; sinon garder supplierLegacyName. |
| `warrantyEndDate` | échéance / document de garantie | Conserver date ; créer document ou garantie seulement après validation du type de donnée. |
| `fleetNumber` | `fleetNumber` | Correspondance directe ; détecter doublons à l'intérieur de companyId. |
| `currentMileage` | `vehicle_meter_readings` | Créer un relevé initial de source legacy avec date d'observation inconnue explicitement signalée ; ne pas lui donner une fausse date de mesure. |
| `nextServiceMileage` | `vehicle_maintenance_plans.nextDueKm` | Créer un plan d'entretien seulement si la règle d'intervalle/type est connue ; sinon conserver une échéance legacy à classifier. |
| `imageFileId`, `imageUrl`, `imageSource` | `vehicle_media` + `primaryMediaId` | Vérifier existence du fichier, bucket, propriétaire et tenant. Ne pas recopier une URL publique expirante comme asset source. |
| `customFields` | dictionnaire de champs personnalisés | Garder le JSON, inventorier les clés et types par tenant avant de créer des définitions. |
| `matriculePrec` / `previousRegistrations` | historique des immatriculations | Créer des entrées d'historique ordonnées seulement si la séquence est fiable ; ne pas inventer les dates. |
| `search` | champ de recherche dérivé | Recalculer depuis les champs canoniques ; ne pas traiter comme source de vérité. |

---

## 3. Correspondance technique des doublons de modèle

Les champs suivants sont conservés temporairement dans le domaine existant mais leur duplication doit être éliminée progressivement :

| Ensemble actuel | Sémantique cible | Action |
|---|---|---|
| `type`, `genre`, `body`, `heavy` | vehicleClass, legalGenreCode, bodyStyle | Distinguer classification produit, genre carte grise et carrosserie. Le booléen heavy devient dérivé si sa définition est identique. |
| `state`, `currentState`, `service`, `decision` | lifecycleStatus + operationalStatus | Définir le dictionnaire avant de migrer. Une seule source par statut. |
| `driverRegistration`, `driverOwnership`, `matriculeConducteur` | vehicle_assignments + audit | Relation par driverId, pas par plaque texte. Garder snapshot historique si requis. |
| `location`, `emplacement`, `perimeter`, `siteId` | siteId, parking assignment et géofence | Site administratif, place prévue et position observée sont trois concepts distincts. |
| `currentMileage`, `nextServiceMileage` | meter readings + maintenance plan | Historiser les relevés et les règles d'échéance. |
| `imageUrl`, `imageFileId`, `imageSource` | vehicle_media | Une galerie, un fichier privé et une sélection de média principal. |

---

## 4. Algorithmes de normalisation

### 4.1 Marques

1. Charger la version du catalogue `vehicle_makes`.
2. Si valeur legacy est un ID existant, le conserver.
3. Si la valeur est numérique, l'interpréter uniquement selon le tableau historique `vehiculeBrands` exact de la version qui a créé la valeur.
4. Résoudre le nom historique vers `normalizedName`/alias du catalogue global.
5. Si une correspondance unique existe, écrire makeId stable.
6. Si aucun résultat ou plusieurs résultats, laisser makeId null et créer un élément de revue avec raw value, ancien index, version du tableau et entreprise.
7. Ne jamais transformer arbitrairement `"3"` en slug `"3"` ; ne jamais faire une conversion sans version du référentiel.

Le service actuel `VehicleMakeService.canonicalId()` fait une conversion en mémoire selon `vehiculeBrands`. Le script de migration doit utiliser exactement la même table versionnée ou une copie figée de sa correspondance ; une mise à jour future du tableau ne doit pas modifier l'interprétation historique.

### 4.2 Immatriculations

- Normaliser espaces, tirets, casse et séparateurs sans retirer les segments significatifs.
- Le pays/format est pris en compte.
- Préserver registrationNumber affichable.
- Générer un rapport de collisions avant de créer l'index unique.
- Ne jamais fusionner deux véhicules juste parce que la normalisation produit la même plaque.

### 4.3 VIN

- Trim + uppercase + suppression des espaces.
- Détecter longueur/formats plausibles mais ne pas rejeter les numéros de série non-VIN.
- L'ancien index `numero_serie` est en état failed : aucune unicité VIN n'est garantie actuellement.
- Audit de collision avant création d'un index unique tenant-scoped.

---

## 5. Stratégie de migration sans perte

### Phase A — Snapshot et inventaire (lecture seule)
- Exporter le nombre exact de lignes et les colonnes des tables `vehicle`, `chauffeur`, `marque`, `genre_vehicule`, `etat`, `doc_vehic`, `activity`, `fichereception`.
- Capturer les payloads JSON bruts et leurs hashes.
- Recenser les IDs, companyId, siteId, références conducteur et documents.
- Identifier les lignes sans payload, payload invalide ou divergence colonne/payload.
- Protéger les exports car ils peuvent contenir des données personnelles.

### Phase B — Rapport de dry-run
Pour chaque ligne :
- mapping réussi ;
- conversion normalisée ;
- valeur préservée en legacy ;
- ambiguïté à valider ;
- doublon possible ;
- relation parent introuvable ;
- tenant ownership non prouvée.

Aucun write lors du dry-run. Le rapport contient les IDs et le code d'anomalie, pas les noms/adresses personnels dans les logs généraux.

### Phase C — Extension additive
- Ajouter les colonnes canoniques.
- Déployer un lecteur dual qui comprend les anciennes colonnes et les champs canoniques.
- Écrire les nouvelles valeurs canoniques + anciennes projections nécessaires à la compatibilité.
- Ajouter les nouvelles relations sans supprimer les champs legacy.
- Sauvegarder une version de payload et schemaVersion.

### Phase D — Backfill contrôlé
- Migrer par petits lots avec checkpoint et reprise.
- Mettre à jour chaque ligne par son $id et vérifier companyId immuable.
- Créer les entités enfants uniquement lorsque la relation et la date/source sont fiables.
- Utiliser des row IDs déterministes ou une table de mapping pour rendre le script idempotent.
- En cas d'erreur, loguer le rowId et un reasonCode, pas tout le payload.

### Phase E — Vérification
- Comparer le nombre de véhicules avant/après par companyId.
- Comparer hashes/valeurs des champs préservés.
- Vérifier aucun véhicule déplacé de tenant.
- Vérifier immatriculations/VIN et relations conducteur.
- Vérifier quota utilisé = nombre de véhicules comptabilisés selon les règles de licence, sans le réincrémenter lors du backfill.
- Vérifier permissions et rowSecurity.
- Tests de lecture et écriture avec les clients anciens/nouveaux.

### Phase F — Bascule et retrait différé
- Basculer l'écriture vers le modèle canonique après tests.
- Garder la double lecture pendant une période de stabilité.
- Instrumenter les lectures des champs legacy.
- Retirer les colonnes/compatibilités uniquement lorsqu'aucun lecteur/écrivain n'y accède plus et qu'une restauration est testée.

---

## 6. Cas à ne pas automatiser

- `matriculeConducteur` sans chauffeur unique dans le même tenant.
- `emplacement` libre sans site/parking/zone/place identifiée.
- `decision` sans définition métier confirmée.
- `service` si la valeur peut signifier statut, usage ou mission.
- `etat` et `etatactuel` sans dictionnaire versionné.
- `filliale`, `direction`, `departement` sans hiérarchie organisationnelle validée.
- `date` si on ignore s'il s'agit de la date du document ou de première mise en circulation.
- `quittance` sans échelle/unité monétaire.
- `purchasePrice` sans devise et règle d'arrondi.
- `currentMileage` sans date d'observation ; ne pas en faire un relevé récent.
- URL/fichier média dont le bucket ou le tenant n'est pas vérifié.
- marque numérique ne correspondant pas à l'index versionné ou alias ambigu.
- ligne historique sans companyId vérifiable.

Chaque cas doit rester lisible, être associé à un code `needs_review` et être corrigé par un opérateur autorisé.

---

## 7. Critères d'acceptation

- 100 % des véhicules legacy restent lisibles pendant et après les phases A à D.
- Aucun ID de véhicule ni companyId n'est modifié.
- Aucun enregistrement sans tenant connu n'est affecté arbitrairement à une entreprise.
- Les champs ambigus sont comptés et reportés, non convertis au hasard.
- Toute conversion makeId possède une traçabilité de la source et de la version du catalogue.
- Les immatriculations/VIN potentiellement dupliqués sont isolés avant index unique.
- Le quota véhicule n'est pas consommé par un backfill.
- Les anciens champs ne sont supprimés qu'après audit d'usage et période de coexistence.
