# Parcoto — Contrat de schéma Appwrite des véhicules v1

**Statut :** spécification cible, prête pour revue technique  
**Référence :** `docs/vehicle-domain-model-v1.md`  
**Base auditée :** `Parking` / `6531ad112080ae3b14a7`  
**Périmètre :** véhicule, sites, affectations, télématique smartphone, parking, compteurs, documents, maintenance et coûts.

> Ce fichier est un contrat de schéma, pas un script d'exécution. Il ne faut pas appliquer ses tables en production avant la migration dry-run, la validation des ACL et la revue des clés/index. Les noms de tables proposés sont les IDs TablesDB.

---

## 1. Conventions Appwrite

### 1.1 Colonnes communes

Sauf indication contraire, chaque table opérationnelle tenant-scoped comporte :

| Clé | Type Appwrite | Requis | Taille / règle |
|---|---|---:|---|
| companyId | string | Oui | 36 ; ID UUID de companies |
| createdAt | datetime | Oui | UTC |
| updatedAt | datetime | Oui | UTC |
| createdBy | string | Oui | 36 ; Appwrite user ID ou actor service ID |
| updatedBy | string | Non | 36 |
| revision | integer | Oui | Départ à 1 ; incrément serveur à chaque mutation acceptée |

Les valeurs d'identité de lignes sont portées par `$id` Appwrite (36 caractères maximum) ; ne pas dupliquer un champ `id` sauf besoin d'interopérabilité documenté.

Les références (`vehicleId`, `driverId`, `siteId`, etc.) sont des string de 36 caractères, sans relation TablesDB obligatoire dans cette première version. Le service serveur valide leur existence et leur appartenance au même `companyId` avant chaque mutation. Cette validation tenant est obligatoire même si l'interface filtre déjà les données.

Types utilisés :
- `string(size)` pour identifiants, statuts, codes et petites valeurs.
- `datetime` pour instants UTC.
- `integer` pour valeurs entières et compteurs bornés.
- `bigint` pour montant en unités mineures et valeurs de compteur susceptibles de dépasser 32 bits.
- `double` pour coordonnées GNSS, précision, vitesse, dimensions décimales et relevés avec fraction.
- `boolean` pour drapeaux.
- `longtext` uniquement pour JSON documenté, notes ou contenu textuel qui ne sert pas de clé d'index.

Ne pas utiliser `longtext` comme substitut à une relation ou à un champ recherchable.

### 1.2 Règles d'identifiants et de normalisation

- `companyId` est l'identifiant de l'entreprise, jamais son slug.
- `siteId`, `vehicleId`, `driverId`, `trackingDeviceId` et `parkingSpaceId` sont des IDs de lignes, jamais des libellés.
- Immatriculation : conserver `registrationNumber` affichable et `registrationNormalized` calculé côté domaine (uppercase, espaces/tirets normalisés, pays pris en compte). Conserver la valeur saisie brute si l'audit métier l'exige.
- VIN : conserver `vin` et `vinNormalized` en uppercase sans espaces. Ne pas inventer un VIN lorsque la plaque ou l'OCR ne le fournit pas.
- Montants : stocker `amountMinor` (bigint) + `currency` ISO 4217. Ne pas stocker des montants financiers en float.
- Latitude/longitude : WGS84 en double. Conserver accuracy et timestamp de mesure.
- États et catégories : string contrôlé côté domaine/serveur. Les valeurs permises sont versionnées dans le contrat et testées ; éviter une enum Appwrite trop rigide pendant les premiers déploiements/migrations.

### 1.3 Autorisations

Pour chaque table tenant-scoped :
- `rowSecurity=true`.
- Aucune permission table-level `read`, `update` ou `delete` globale.
- Les lignes sont écrites par la Function tenant API avec validation du rôle et de la cohérence des relations.
- Permission de lecture de ligne : `read("team:<companyTeamId>")`.
- Permission d'update : admin/manager si l'entité est modifiable.
- Permission de delete : admin seulement ; les événements, positions et journaux sont append-only et ne sont pas supprimables depuis le client.
- Le compte Super Admin agit via le contexte de plateforme/supervision déjà prévu par la Function ; il ne reçoit pas de permission globale table.
- Une ligne ne doit jamais hériter d'une ACL appartenant à une autre entreprise.

Le serveur doit rejeter toute mutation pour laquelle le companyId du corps, le companyId du parent et le companyId du contexte autorisé ne concordent pas.

---

## 2. Tables existantes à conserver / faire évoluer

### 2.1 `vehicle` — table actuelle à conserver

ID actuel : `6531ad22153b2a49ca2c`  
Row Security : activé ; permissions au niveau table : aucune.  
Index observés : `companyId_idx`, `company_matricule_unique`, `dateIndex`, `SearchIndex`. L'index unique historique sur `numero_serie` est en échec et ne doit pas être considéré comme une garantie.

Les colonnes legacy sont conservées pendant la transition. Ajouter progressivement les colonnes canoniques ci-dessous :

| Clé canonique | Type | Requis | Règle |
|---|---|---:|---|
| fleetNumber | string(40) | Non | Code interne unique par entreprise quand non nul |
| registrationNumber | string(40) | Non | Immatriculation affichable |
| registrationNormalized | string(40) | Non | Valeur normalisée ; null si non immatriculé |
| registrationCountry | string(2) | Oui à terme | ISO 3166-1 alpha-2 ; DZ par défaut lors d'une création algérienne |
| registrationKind | string(20) | Non | national, foreign, temporary, none |
| vin | string(40) | Non | Numéro de châssis/VIN affichable |
| vinNormalized | string(40) | Non | Valeur normalisée ; null si absent |
| makeId | string(36) | Non au brouillon | ID stable de `vehicle_makes` |
| modelId | string(36) | Non | ID de `vehicle_models` si disponible |
| modelName | string(100) | Non | Repli pour modèle non catalogué |
| modelVariant | string(100) | Non | Finition/version commerciale |
| modelYear | integer | Non | Année-modèle |
| manufactureYear | integer | Non | Année de fabrication si documentée |
| firstRegistrationDate | datetime | Non | Première mise en circulation, distincte de modelYear |
| vehicleClass | string(32) | Oui à terme | passenger, light_commercial, heavy_goods, bus, motorcycle, agricultural, construction, trailer, other |
| legalGenreCode | string(40) | Non | Genre légal tel que lu sur le document |
| bodyStyle | string(40) | Non | Berline, fourgon, plateau, autocar, etc. |
| fuelType | string(24) | Non | petrol, diesel, lpg, electric, hybrid, other, unknown |
| engineCapacityCc | integer | Non | Cylindrée cm³ |
| enginePowerKw | double | Non | Puissance moteur en kW |
| fiscalPowerCv | integer | Non | Puissance fiscale, ne pas confondre avec kW/CV moteur |
| engineCode | string(60) | Non | Référence moteur |
| transmissionType | string(24) | Non | manual, automatic, other, unknown |
| driveType | string(24) | Non | fwd, rwd, awd, 4wd, other, unknown |
| seatCount | integer | Non | Nombre de places |
| doorCount | integer | Non | Nombre de portes |
| grossWeightKg | integer | Non | Poids total autorisé/administratif |
| payloadKg | integer | Non | Charge utile |
| axleCount | integer | Non | Nombre d'essieux |
| lifecycleStatus | string(24) | Oui à terme | draft, active, in_maintenance, immobilized, retired, sold, archived |
| usageProfile | string(24) | Non | assigned, pool, service, rental, operational, other |
| acquisitionType | string(24) | Non | owned, leased, rented, financed, other |
| acquisitionDate | datetime | Non | Date d'acquisition |
| purchaseAmountMinor | bigint | Non | Prix d'achat en unité mineure |
| purchaseCurrency | string(3) | Non | ISO 4217 |
| supplierId | string(36) | Non | Référence tenant-scoped vers fournisseur |
| primaryMediaId | string(36) | Non | Média principal ; pointeur, pas copie du fichier |
| schemaVersion | integer | Oui à terme | Version du payload métier |
| createdBy | string(36) | Non pendant migration | Acteur de création |
| updatedBy | string(36) | Non | Dernier acteur |

**Compatibilité obligatoire :**
- Garder `matricule`, `martricule_etrang`, `numero_serie`, `marque`, `genre`, `type`, `energie`, `carrosserie`, `charge_utile`, `poids_total`, `place_assises`, `puissance`, `annee_util`, `emplacement`, `matriculeConducteur` et les autres colonnes legacy durant la migration.
- La colonne `marque` a été portée à 64 caractères. Elle est transitoire ; la valeur canonique sera `makeId`.
- La colonne `matricule` est encore requise et doit rester renseignée par les anciens clients. Elle ne pourra devenir facultative qu'après migration de toutes les écritures et lecteurs et après une validation sur les actifs sans immatriculation.
- `registrationNormalized` et `vinNormalized` sont nuls plutôt que chaînes vides quand absents.
- Le serveur applique l'unicité tenant de l'immatriculation et du VIN. Créer les index unique composés uniquement après dry-run de doublons et test de valeurs nulles sur un environnement de validation.

### 2.2 `chauffeur` — référentiel actuel à conserver

ID actuel : `6537d87b492c80f255e8`.  
Conserver les colonnes legacy. Le champ `vehicules` et les immatriculations conducteur ne doivent plus représenter l'affectation courante source de vérité. La source canonique devient `vehicle_assignments`. Le payload historique reste lisible pendant la migration.

### 2.3 Catalogue de marques

`vehicle_makes` est partagé globalement, sans `companyId`, rowSecurity actuellement désactivé avec lecture `users`. Garder ce choix pour un référentiel plateforme public en lecture.

Un futur `vehicle_models` global est proposé :
- `$id` stable, `makeId` string(36), `name` string(100), `normalizedName` string(120), `aliasesJson` longtext optionnel, `generation` string(80), `startYear` integer, `endYear` integer, `isActive` boolean, `source` string(30), `createdAt`, `updatedAt`.
- Index non-unique `makeId_active` sur (makeId, isActive).
- Index unique `make_generation_year` sur (makeId, normalizedName, generation) uniquement si les variantes sont précisément définies et les doublons audités.
- Lecture utilisateur, mutations réservées à l'administration plateforme.

Ne pas lancer `vehicle_models` tant que la stratégie de génération/variant et la qualité des 211 marques ne sont pas validées.

---

## 3. Tables opérationnelles nouvelles

Toutes les tables ci-dessous sont tenant-scoped, sauf `vehicle_models`. Toutes utilisent les colonnes communes définies en §1.1. Pour les champs non mentionnés, ne pas les ajouter « au cas où ».

### 3.1 `sites`

Un site est une implantation d'entreprise ; il n'est ni un parking ni une place.

| Clé | Type | Requis | Description |
|---|---|---:|---|
| code | string(40) | Oui | Code court unique par entreprise |
| name | string(120) | Oui | Nom du site |
| address | string(255) | Non | Adresse |
| wilayaCode | string(8) | Non | Code wilaya ; garder le référentiel séparé |
| commune | string(100) | Non | Commune |
| latitude | double | Non | Centre ou point représentatif WGS84 |
| longitude | double | Non | Centre ou point représentatif WGS84 |
| timezone | string(64) | Oui | Valeur IANA, défaut Africa/Algiers |
| status | string(16) | Oui | active, inactive, archived |
| notes | string(2000) | Non | Notes administratives |

Indexes : unique (companyId, code), key (companyId, status), key (companyId, name).

### 3.2 `vehicle_assignments`

Une affectation est une période historisée. Un changement termine l'affectation active précédente puis crée un nouvel enregistrement.

| Clé | Type | Requis | Description |
|---|---|---:|---|
| vehicleId | string(36) | Oui | Véhicule du même tenant |
| driverId | string(36) | Non | Chauffeur ; null pour pool/non affecté |
| assignmentType | string(20) | Oui | primary, temporary, pool, mission |
| status | string(16) | Oui | active, ended, cancelled |
| startAt | datetime | Oui | Début UTC |
| endAt | datetime | Non | Fin UTC |
| assignedBy | string(36) | Oui | Acteur |
| endedBy | string(36) | Non | Acteur de clôture |
| reason | string(200) | Non | Motif |
| notes | string(2000) | Non | Commentaire |
| meterStartKm | double | Non | Relevé départ facultatif |
| meterEndKm | double | Non | Relevé fin facultatif |

Indexes : key (companyId, vehicleId, status), key (companyId, driverId, status), key (companyId, startAt), key (companyId, endAt).

Contrainte active : une seule affectation principale active par véhicule. TablesDB ne fournit pas ici un index partiel garanti ; effectuer le contrôle dans une mutation serveur transactionnelle et traiter les conflits concurrents. Les affectations temporaires/missions doivent utiliser une politique explicite, pas contourner le contrôle.

### 3.3 `tracking_devices`

Un téléphone est d'abord un appareil utilisateur/conducteur. Il n'est pas considéré comme physiquement attaché à un véhicule.

| Clé | Type | Requis | Description |
|---|---|---:|---|
| deviceType | string(24) | Oui | smartphone, dedicated_tracker, obd, other |
| provider | string(60) | Oui | android, ios, provider name |
| platform | string(16) | Oui | android, ios, other |
| appInstanceId | string(36) | Oui | UUID aléatoire créé par Parcoto Connect, pas IMEI ni numéro matériel |
| deviceLabel | string(100) | Non | Libellé choisi par l'utilisateur |
| userId | string(36) | Non | Compte Appwrite responsable |
| driverId | string(36) | Non | Conducteur responsable dans ce tenant |
| dedicatedVehicleId | string(36) | Non | Seulement appareil dédié à un véhicule |
| permissionStatus | string(24) | Oui | unknown, granted, denied, restricted |
| trackingStatus | string(24) | Oui | inactive, ready, running, stale, offline, revoked |
| lastSeenAt | datetime | Non | Dernière activité app |
| lastFixAt | datetime | Non | Dernière position reçue |
| batteryPercent | integer | Non | 0–100 si l'OS l'expose |
| appVersion | string(32) | Non | Version Parcoto Connect |
| disabledAt | datetime | Non | Révocation |

Indexes : unique (companyId, appInstanceId), key (companyId, driverId, trackingStatus), key (companyId, dedicatedVehicleId).

Ne pas collecter IMEI, IMSI, contacts, identifiants publicitaires ou autres identifiants matériels superflus.

### 3.4 `tracking_sessions`

La session représente une période de suivi autorisée et annoncée.

| Clé | Type | Requis | Description |
|---|---|---:|---|
| trackingDeviceId | string(36) | Oui | Appareil |
| driverId | string(36) | Non | Conducteur |
| vehicleId | string(36) | Oui | Véhicule suivi durant cette session |
| vehicleAssignmentId | string(36) | Non | Affectation/missions qui justifie le lien |
| startedAt | datetime | Oui | Démarrage |
| endedAt | datetime | Non | Arrêt |
| startReason | string(24) | Oui | shift, mission, security_check, other |
| endReason | string(24) | Non | shift_end, mission_end, user_stop, permission_revoked, device_shutdown, timeout |
| status | string(16) | Oui | active, stopped, interrupted |
| noticeVersion | string(32) | Oui | Version de l'information affichée |
| noticeAcknowledgedAt | datetime | Non | Horodatage d'information/prise de connaissance, sans supposer à lui seul le fondement juridique |
| trackingMode | string(20) | Oui | foreground, background_permitted, foreground_only |

Indexes : key (companyId, vehicleId, status), key (companyId, driverId, startedAt), key (companyId, trackingDeviceId, status).

La session ne peut démarrer que si l'utilisateur a été informé, que les permissions OS nécessaires sont actives et que le rôle/finalité le permettent. La fin de mission/service arrête le suivi. Pas de suivi caché ou permanent par défaut.

### 3.5 `vehicle_location_fixes`

Table potentiellement volumineuse. Append-only ; aucune modification de coordonnées par un client.

| Clé | Type | Requis | Description |
|---|---|---:|---|
| vehicleId | string(36) | Oui | Véhicule |
| driverId | string(36) | Non | Conducteur lié à la session |
| trackingDeviceId | string(36) | Oui | Appareil source |
| trackingSessionId | string(36) | Oui | Session |
| observedAt | datetime | Oui | Heure réelle de mesure sur appareil |
| receivedAt | datetime | Oui | Heure réception serveur |
| latitude | double | Oui | WGS84, -90..90 |
| longitude | double | Oui | WGS84, -180..180 |
| horizontalAccuracyM | double | Non | Précision horizontale déclarée |
| speedMps | double | Non | Vitesse ; null si absente |
| headingDegrees | double | Non | 0..360 |
| altitudeM | double | Non | Altitude si disponible |
| sourceType | string(24) | Oui | phone_gnss, dedicated_gps, obd, provider, manual |
| fixId | string(36) | Oui | UUID idempotent généré à la source |
| qualityFlagsJson | string(2000) | Non | Indicateurs qualité minimisés |

Indexes : unique (companyId, fixId), key (companyId, vehicleId, observedAt), key (companyId, trackingSessionId, observedAt), key (companyId, trackingDeviceId, observedAt).

Prévoir un partitionnement/archivage ou une stratégie de purge adaptée à la volumétrie. Ne pas créer d'index de recherche fulltext sur les coordonnées. Les lots mobiles utilisent un endpoint batch, valident chaque fix et dédupliquent par fixId.

### 3.6 `parking_lots`

| Clé | Type | Requis | Description |
|---|---|---:|---|
| siteId | string(36) | Oui | Site parent |
| code | string(40) | Oui | Code unique par entreprise |
| name | string(120) | Oui | Nom |
| address | string(255) | Non | Adresse |
| latitude | double | Non | Point représentatif |
| longitude | double | Non | Point représentatif |
| boundaryGeoJson | longtext | Non | GeoJSON validé, taille plafonnée côté API |
| status | string(16) | Oui | active, inactive, archived |
| notes | string(2000) | Non | Notes |

Indexes : unique (companyId, code), key (companyId, siteId, status).

### 3.7 `parking_zones`

| Clé | Type | Requis | Description |
|---|---|---:|---|
| parkingLotId | string(36) | Oui | Parking parent |
| code | string(40) | Oui | Code unique dans le parking |
| name | string(100) | Oui | Nom |
| zoneType | string(24) | Oui | standard, visitor, delivery, restricted, charging, maintenance, other |
| status | string(16) | Oui | active, inactive |
| notes | string(1000) | Non | Notes |

Indexes : unique (companyId, parkingLotId, code), key (companyId, parkingLotId, status).

### 3.8 `parking_spaces`

| Clé | Type | Requis | Description |
|---|---|---:|---|
| parkingZoneId | string(36) | Oui | Zone parent |
| code | string(40) | Oui | Code unique dans la zone |
| spaceType | string(24) | Oui | car, light_commercial, heavy_goods, bus, motorcycle, accessible, charging, other |
| maxLengthMm | integer | Non | Longueur limite |
| maxWidthMm | integer | Non | Largeur limite |
| maxHeightMm | integer | Non | Hauteur limite |
| maxWeightKg | integer | Non | Poids limite |
| status | string(16) | Oui | active, inactive, blocked, maintenance |
| notes | string(1000) | Non | Notes |

Indexes : unique (companyId, parkingZoneId, code), key (companyId, parkingZoneId, status).

### 3.9 `vehicle_parking_assignments`

| Clé | Type | Requis | Description |
|---|---|---:|---|
| vehicleId | string(36) | Oui | Véhicule |
| parkingSpaceId | string(36) | Oui | Place |
| assignmentType | string(20) | Oui | reserved, assigned, temporary |
| status | string(16) | Oui | active, ended, cancelled |
| startAt | datetime | Oui | Début |
| endAt | datetime | Non | Fin |
| assignedBy | string(36) | Oui | Acteur |
| notes | string(1000) | Non | Notes |

Indexes : key (companyId, vehicleId, status), key (companyId, parkingSpaceId, status), key (companyId, startAt).

Contrôles transactionnels : une place ne peut avoir deux affectations actives incompatibles ; un véhicule ne peut avoir deux places principales actives. Vérifier la capacité/compatibilité du type de véhicule. Le GPS ne détermine pas automatiquement une place exacte.

### 3.10 `vehicle_meter_readings`

| Clé | Type | Requis | Description |
|---|---|---:|---|
| vehicleId | string(36) | Oui | Véhicule |
| readingType | string(20) | Oui | odometer_km, engine_hours |
| value | double | Oui | Valeur non négative |
| unit | string(8) | Oui | km, h |
| measuredAt | datetime | Oui | Mesure |
| receivedAt | datetime | Oui | Réception |
| sourceType | string(24) | Oui | manual, phone_gps_estimate, dedicated_gps, obd, imported |
| sourceDeviceId | string(36) | Non | Appareil si applicable |
| capturedBy | string(36) | Non | Acteur |
| validationStatus | string(16) | Oui | pending, accepted, rejected |
| notes | string(1000) | Non | Notes |

Indexes : key (companyId, vehicleId, readingType, measuredAt), key (companyId, validationStatus).

Le dernier relevé accepté est une projection affichée. Un GPS estimé ne remplace pas automatiquement un compteur manuel/OBD vérifié. Rejeter ou signaler les valeurs qui régressent sans justification.

### 3.11 `vehicle_documents`

| Clé | Type | Requis | Description |
|---|---|---:|---|
| vehicleId | string(36) | Oui | Véhicule |
| documentType | string(32) | Oui | registration, insurance, technical_inspection, vignette, permit, contract, other |
| documentNumber | string(80) | Non | Référence |
| issuedAt | datetime | Non | Émission |
| expiresAt | datetime | Non | Expiration |
| storageBucketId | string(36) | Oui | Bucket privé |
| storageFileId | string(36) | Oui | Fichier |
| fileName | string(180) | Oui | Nom original nettoyé |
| mimeType | string(80) | Oui | MIME vérifié |
| sourceType | string(16) | Oui | manual, ocr, imported |
| extractionJson | longtext | Non | Données OCR minimisées + provenance/confiance |
| status | string(16) | Oui | valid, expiring, expired, archived, rejected |
| remindersJson | string(2000) | Non | Paramètres de rappel |

Indexes : key (companyId, vehicleId, documentType), key (companyId, expiresAt, status).

### 3.12 `vehicle_registration_records`

Snapshot historisé des informations portées sur le document d'immatriculation. Les données du titulaire ne doivent pas être mélangées aux caractéristiques stables du véhicule.

| Clé | Type | Requis | Description |
|---|---|---:|---|
| vehicleId | string(36) | Oui | Véhicule |
| documentId | string(36) | Non | Fichier source dans vehicle_documents |
| registrationNumber | string(40) | Oui | Immatriculation inscrite sur le document |
| registrationCountry | string(2) | Oui | ISO 3166-1 alpha-2 |
| recordType | string(24) | Oui | initial, renewal, ownership_change, plate_change, correction |
| issuedAt | datetime | Non | Date d'émission du document |
| validFrom | datetime | Non | Début de validité s'il est documenté |
| validTo | datetime | Non | Fin de validité si applicable |
| ownerLastName | string(100) | Non | Titulaire — donnée personnelle |
| ownerFirstName | string(100) | Non | Titulaire — donnée personnelle |
| ownerProfession | string(120) | Non | Profession inscrite — donnée personnelle |
| receiptNumber | string(80) | Non | Référence de quittance |
| receiptAmountMinor | bigint | Non | Montant en unité mineure après validation de devise/unité |
| currency | string(3) | Non | ISO 4217 |
| sourceType | string(16) | Oui | manual, ocr, imported, legacy |
| isCurrent | boolean | Oui | Projection de l'enregistrement actuel |
| rawLegacyJson | longtext | Non | Conservation temporaire de champs historiques ambigus, accès limité |

Indexes : key (companyId, vehicleId, isCurrent), key (companyId, registrationNumber). L'unicité d'un seul record current par véhicule est vérifiée transactionnellement par le serveur ; ne pas supposer un index partiel.

Les fichiers restent dans un bucket privé ; la table ne contient pas de URL publique permanente. Vérifier l'ACL du fichier au même niveau que l'ACL de la ligne.

### 3.13 `vehicle_media`

| Clé | Type | Requis | Description |
|---|---|---:|---|
| vehicleId | string(36) | Oui | Véhicule |
| mediaType | string(24) | Oui | exterior, interior, damage, inspection, registration_scan, other |
| storageBucketId | string(36) | Oui | Bucket privé |
| storageFileId | string(36) | Oui | Fichier |
| fileName | string(180) | Oui | Nom nettoyé |
| mimeType | string(80) | Oui | MIME |
| capturedAt | datetime | Non | Capture |
| uploadedAt | datetime | Oui | Upload |
| sourceType | string(20) | Oui | camera, gallery, scanner, imported |
| caption | string(500) | Non | Légende |
| sortOrder | integer | Oui | Ordre d'affichage |

Indexes : key (companyId, vehicleId, mediaType, sortOrder).

La photo principale est référencée via vehicles.primaryMediaId. Vérifier côté serveur que le mediaId appartient au même véhicule/tenant. Éviter le booléen `isPrimary` dupliqué sans contrainte d'unicité.

### 3.14 `vehicle_maintenance_plans`

| Clé | Type | Requis | Description |
|---|---|---:|---|
| vehicleId | string(36) | Oui | Véhicule |
| planType | string(24) | Oui | oil_service, inspection, tires, brakes, battery, general, custom |
| title | string(120) | Oui | Intitulé |
| intervalKm | integer | Non | Intervalle km |
| intervalDays | integer | Non | Intervalle jours |
| intervalEngineHours | double | Non | Intervalle heures |
| nextDueKm | double | Non | Prochaine valeur compteur |
| nextDueAt | datetime | Non | Prochaine date |
| nextDueEngineHours | double | Non | Prochaines heures moteur |
| alertLeadKm | integer | Non | Seuil d'alerte km |
| alertLeadDays | integer | Non | Seuil d'alerte jours |
| status | string(16) | Oui | active, paused, completed, archived |
| notes | string(2000) | Non | Notes |

Indexes : key (companyId, vehicleId, status), key (companyId, nextDueAt, status).

### 3.15 `maintenance_work_orders`

| Clé | Type | Requis | Description |
|---|---|---:|---|
| vehicleId | string(36) | Oui | Véhicule |
| maintenancePlanId | string(36) | Non | Plan lié |
| reference | string(40) | Non | Référence unique par entreprise si renseignée |
| status | string(20) | Oui | planned, open, in_progress, waiting_parts, completed, cancelled |
| openedAt | datetime | Oui | Ouverture |
| scheduledAt | datetime | Non | Planification |
| startedAt | datetime | Non | Début |
| completedAt | datetime | Non | Fin |
| meterKm | double | Non | Compteur au moment de l'intervention |
| description | string(2000) | Oui | Symptôme / travaux |
| diagnosis | string(4000) | Non | Diagnostic |
| resolution | string(4000) | Non | Résolution |
| supplierId | string(36) | Non | Prestataire |
| estimatedAmountMinor | bigint | Non | Estimation |
| actualAmountMinor | bigint | Non | Réel |
| currency | string(3) | Non | ISO 4217 |

Indexes : key (companyId, vehicleId, status), key (companyId, scheduledAt, status), key (companyId, reference).

### 3.16 `vehicle_expenses`

| Clé | Type | Requis | Description |
|---|---|---:|---|
| vehicleId | string(36) | Oui | Véhicule |
| expenseType | string(24) | Oui | fuel, maintenance, insurance, tax, tire, toll, parking, other |
| occurredAt | datetime | Oui | Date de dépense |
| amountMinor | bigint | Oui | Montant non négatif |
| currency | string(3) | Oui | ISO 4217 |
| supplierId | string(36) | Non | Fournisseur |
| reference | string(80) | Non | Facture/référence |
| meterKm | double | Non | Kilométrage associé |
| workOrderId | string(36) | Non | Intervention liée |
| notes | string(1000) | Non | Notes |

Indexes : key (companyId, vehicleId, occurredAt), key (companyId, expenseType, occurredAt), key (companyId, supplierId).

Les achats de pièces/consommables provenant du module Stock doivent créer une référence vers leur transaction source, pas dupliquer la quantité de stock dans vehicle_expenses.

### 3.17 `vehicle_events`

Journal append-only de l'historique métier.

| Clé | Type | Requis | Description |
|---|---|---:|---|
| vehicleId | string(36) | Oui | Véhicule |
| eventType | string(32) | Oui | created, status_changed, assignment_changed, parking_changed, meter_reading, document_added, maintenance, gps_alert, edited, other |
| occurredAt | datetime | Oui | Date de l'événement |
| recordedAt | datetime | Oui | Date d'enregistrement |
| actorUserId | string(36) | Non | Acteur |
| sourceResource | string(40) | Non | Table source |
| sourceRowId | string(36) | Non | Ligne source |
| summary | string(180) | Oui | Résumé |
| detailsJson | longtext | Non | Détails limités, sans recopier tout le payload source |

Indexes : key (companyId, vehicleId, occurredAt), key (companyId, eventType, occurredAt), key (companyId, actorUserId, occurredAt).

Pas d'update/delete client sur les événements. Une erreur est corrigée par un nouvel événement d'annulation/correction, pas par réécriture de l'historique.

---

## 4. Matrice des indexes

Les indexes sont créés après contrôle de doublons et de la capacité de l'index dans Appwrite TablesDB. Les index uniques portant sur des champs facultatifs doivent être testés avec plusieurs valeurs nulles dans un environnement de validation ; ne pas supposer le comportement des chaînes vides.

| Table | Index | Type | Colonnes |
|---|---|---|---|
| vehicle | company_matricule_unique (existant) | unique | companyId, matricule |
| vehicle | company_registration_norm | key ou unique après audit | companyId, registrationNormalized |
| vehicle | company_vin_norm | key ou unique après audit | companyId, vinNormalized |
| vehicle | company_status | key | companyId, lifecycleStatus |
| vehicle | company_site | key | companyId, siteId |
| vehicle | company_make_model | key | companyId, makeId, modelId |
| sites | company_code | unique | companyId, code |
| sites | company_status | key | companyId, status |
| vehicle_assignments | vehicle_active | key | companyId, vehicleId, status |
| vehicle_assignments | driver_active | key | companyId, driverId, status |
| tracking_devices | app_instance | unique | companyId, appInstanceId |
| tracking_sessions | vehicle_status | key | companyId, vehicleId, status |
| tracking_sessions | driver_started | key | companyId, driverId, startedAt |
| vehicle_location_fixes | fix_id | unique | companyId, fixId |
| vehicle_location_fixes | vehicle_time | key | companyId, vehicleId, observedAt |
| parking_lots | company_code | unique | companyId, code |
| parking_zones | lot_code | unique | companyId, parkingLotId, code |
| parking_spaces | zone_code | unique | companyId, parkingZoneId, code |
| vehicle_parking_assignments | vehicle_status | key | companyId, vehicleId, status |
| vehicle_parking_assignments | space_status | key | companyId, parkingSpaceId, status |
| vehicle_meter_readings | vehicle_time | key | companyId, vehicleId, readingType, measuredAt |
| vehicle_documents | vehicle_expiry | key | companyId, expiresAt, status |
| vehicle_registration_records | vehicle_registration | key | companyId, vehicleId, isCurrent |
| vehicle_media | vehicle_media_order | key | companyId, vehicleId, mediaType, sortOrder |
| vehicle_maintenance_plans | vehicle_due | key | companyId, status, nextDueAt |
| maintenance_work_orders | vehicle_status | key | companyId, vehicleId, status |
| vehicle_expenses | vehicle_time | key | companyId, vehicleId, occurredAt |
| vehicle_events | vehicle_timeline | key | companyId, vehicleId, occurredAt |

Éviter de créer des index couvrant toutes les colonnes. Les index sont dimensionnés à partir des requêtes réellement implémentées, mesurées et paginées.

---

## 5. API serveur et transaction

### 5.1 Mutation explicitement autorisée

Ne jamais exposer un endpoint générique où le client peut choisir librement `tableId`, `column` ou `permissions`.

La Function `company-tenant-api` doit avoir une registry serveur explicite de ressources et d'actions. Chaque handler déclare :
- table ID autorisé ;
- champs inscriptibles ;
- champs calculés/interdits au client ;
- rôle minimum ;
- validation tenant des parents ;
- idempotency key ;
- stratégie de quota ;
- ACL de ligne ;
- politique d'update/delete.

Actions candidates :
- create/update vehicle (quota véhicule appliqué une seule fois à la création) ;
- assignment start/end ;
- tracking device register/revoke ;
- tracking session start/stop ;
- location fixes batch ingestion ;
- parking lot/zone/space mutations ;
- parking assignment start/end ;
- meter reading append/validate ;
- document/media metadata creation (avec contrôle du Storage bucket) ;
- maintenance plan/work order mutations ;
- expense creation ;
- event append.

### 5.2 Règle transactionnelle

Toute action atomique sur plusieurs lignes TablesDB utilise un transaction ID Appwrite. Exemples :
- création véhicule + compteur de quota + éventuel événement de création ;
- affectation d'une place : clôture affectation précédente + création de la nouvelle ;
- clôture de session GPS + finalisation d'événement ;
- création d'intervention + dépense source si les deux doivent être atomiques.

Les validations de parent/tenant et les droits sont exécutés avant staging. Le serveur ne fait pas confiance au companyId fourni sans le comparer au contexte utilisateur autorisé (adhésion ou exploration Super Admin).

### 5.3 Conflits concurrents

- Le serveur vérifie les invariants dans la transaction ; une lecture UI préalable ne suffit pas.
- Réserver les codes internes, immatriculations et places avec des indexes si possible et une validation transactionnelle dans tous les cas.
- Rendre toutes les créations idempotentes : rejouer un même `operationId`/rowId doit retourner l'état déjà créé sans consommer à nouveau un quota ni dupliquer un événement.
- Les créations enfants vérifient que le parent existe dans le même tenant.
- Les mutations append-only ne sont pas modifiées après leur acceptation ; corriger par un nouvel événement.


### 5.4 Table système `sync_operation_receipts`

Cette table est **server-only** : aucune lecture ou écriture directe par Flutter.

| Clé | Type | Requis | Description |
|---|---|---:|---|
| companyId | string(36) | Oui | Tenant |
| operationId | string(36) | Oui | Identifiant stable de mutation client |
| entity | string(40) | Oui | Ressource |
| entityId | string(36) | Oui | ID de ligne visé |
| operationType | string(12) | Oui | create, update, delete, append |
| resultCode | string(24) | Oui | applied, already_applied, rejected |
| resultRevision | integer | Non | Revision après application |
| appliedAt | datetime | Oui | Horodatage serveur |

Index unique `(companyId, operationId)`, index `(companyId, entity, entityId)`. Row Security activé, permissions table et ligne vides pour les clients. L'API serveur utilise sa clé de fonction pour lire/écrire. Si la mutation et le receipt sont inséparables, ils doivent être staged dans la même transaction TablesDB.

---

## 6. Ordre de mise en place — aucun changement de production dans cette phase

1. Créer les tables/sites dans un environnement de validation, pas dans la base live.
2. Vérifier colonnes, tailles, indexes, IDs, ACL et rowSecurity.
3. Tester les mutations sous admin, manager, employee, viewer et Super Admin en contexte d'exploration.
4. Tester l'accès direct entre deux companyId différents, hors interface.
5. Tester les transactions, doublons, perte de réponse, retry et quota.
6. Mesurer les requêtes de list/pagination et l'indexation.
7. Exécuter la migration dry-run sur une copie des données.
8. Seulement après validation, appliquer les extensions de table et créer les ressources tenant.
9. Ajouter les tables GPS uniquement après le gate légal et privacy du §9 du document de domaine.
10. N'activer aucun tracking conducteur en production avant validation réglementaire, information des salariés, finalités, autorisations et transferts de données.

## 7. Critères de sortie

- Chaque table tenant-scoped possède companyId required et rowSecurity activé.
- Aucun parent référencé ne peut provenir d'un autre tenant.
- Les index critiques sont disponibles (aucun index en état failed).
- Les codes uniques sont contrôlés sur le tenant.
- Les opérations transactionnelles sont idempotentes et testées sous panne réseau.
- Les permissions sont testées par rôle et par entreprise.
- Les colonnes legacy ne sont pas supprimées avant réussite de la migration et élimination de tous les lecteurs/écrivains legacy.
- La conformité GPS reste un gate de lancement séparé.
