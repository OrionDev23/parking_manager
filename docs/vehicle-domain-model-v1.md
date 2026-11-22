# Parcoto — Modèle de domaine Véhicules v1

**Statut :** proposition d'architecture — phase 1  
**Date d'audit :** 22 novembre 2026  
**Branche de référence :** refactor/foundation-v1  
**Projet Appwrite inspecté :** essais — base Parking

> Ce document définit le contrat cible. Il ne migre aucune donnée et ne crée/modifie aucune table Appwrite. Les changements physiques de schéma seront effectués dans une phase dédiée, après validation du modèle et préparation des migrations.

---

## 1. Décision produit

Le véhicule est un **actif de flotte**. Sa fiche unifiée agrège plusieurs domaines, mais ces domaines ne doivent pas tous être stockés dans la ligne véhicule.

Le modèle sépare :

1. **Identité et caractéristiques** — ce qu'est le véhicule.
2. **Exploitation** — comment l'entreprise l'utilise et qui en est responsable.
3. **Localisation et télématique** — où il se trouve, avec quelle source et à quel moment.
4. **Affectation physique** — où il est censé stationner.
5. **Cycle de vie** — documents, entretiens, compteurs, coûts et événements.

La fiche véhicule est une vue de lecture unifiée de ces domaines. Elle n'est pas le conteneur de toutes leurs données.

### Principes non négociables

- Le véhicule doit rester exploitable sans GPS, sans conducteur affecté et sans parking.
- Une donnée saisie ou détectée ne doit pas être dupliquée dans plusieurs champs faisant autorité.
- Une relation temporaire doit être historisée, pas écrasée.
- Une position GPS doit toujours porter sa source, son heure de mesure et sa précision.
- L'emplacement attribué et la position observée sont deux notions distinctes.
- Toutes les données opérationnelles sont isolées par companyId côté serveur et au niveau local.
- Les anciennes données restent lisibles pendant la migration ; aucune suppression massive ni conversion irréversible.

---

## 2. Audit de l'existant

### 2.1 Appwrite — état observé le 22/11/2026

Base : Parking — 33 tables.

| Ressource existante | État observé | Décision |
|---|---|---|
| vehicle | Table historique, companyId obligatoire, siteId facultatif, payload longtext, rowSecurity activé, aucune permission au niveau table | Conserver pendant la transition ; faire évoluer sans casser les colonnes historiques |
| chauffeur | companyId obligatoire, siteId facultatif, payload, rowSecurity activé | Réutiliser comme référentiel conducteur pendant la transition |
| vehicle_makes | Catalogue partagé global, 211 marques observées, lecture aux utilisateurs | Référentiel global canonique des marques |
| vehicle_image_catalog | Cache de recherche d'images partagé | Conserver séparé des données propres à une entreprise |
| companies / company_memberships / company_entitlements | Ressources de tenant gérées côté serveur | Ne pas exposer de mutation directe côté client |
| marque / genre_vehicule | Référentiels historiques | Compatibilité et migration ; ne pas les traiter comme source canonique sans décision explicite |
| etat / doc_vehic / reparation / activity | Modules historiques sans modèle relationnel complet et uniforme | Migrer séparément après audit des relations |
| site / parking / GPS / affectations normalisées | Aucune table dédiée observée parmi les 33 tables | Domaines à concevoir ; ne pas simuler leurs relations par du texte libre |

La table vehicle possède déjà une colonne marque de 64 caractères depuis la correction de synchronisation précédente. Le champ ne doit toutefois plus contenir un index de l'ancien tableau de marques : le contrat cible utilise un identifiant stable de catalogue.

### 2.2 Modèle Flutter actuel

L'entité Vehicle contient déjà un grand nombre de propriétés : immatriculation, titulaire de la carte grise, caractéristiques moteur, acquisition, compteur, marque, énergie, carrosserie, état, conducteur, service, emplacement et autres attributs historiques.

Les champs suivants sont sémantiquement ambigus ou se recoupent :

| Champs historiques | Problème | Cible |
|---|---|---|
| type / genre / body / heavy | Classification et carrosserie mélangées | vehicleClass, legalGenreCode et bodyStyle distincts |
| brand / marque / index historique | Plusieurs représentations de la marque | makeId canonique, nom résolu depuis le catalogue |
| modelYear / usageYear / année saisie | Année de modèle et première mise en circulation confondues | modelYear et firstRegistrationDate séparés |
| state / currentState / service / decision | Plusieurs notions d'état avec sens métier non documenté | lifecycleStatus et operationalStatus définis ; anciens champs migrés après correspondance vérifiée |
| driverRegistration / appartenanceconducteur | Relation conducteur stockée comme texte | vehicle_assignments |
| location / perimeter / siteId | Adresse, emplacement physique et site opérationnel mélangés | siteId pour le site de rattachement ; parking et GPS séparés |
| currentMileage / nextServiceMileage | Compteur courant et seuil de maintenance mélangés | vehicle_meter_readings et maintenance plans |
| imageUrl / imageFileId / imageSource | Image principale confondue avec une galerie | vehicle_media et primaryMediaId |

Le sens métier de certains champs historiques (notamment decision, service, ownership, subsidiary, direction et department) doit être confirmé avant migration. Aucun champ ne sera supprimé sur la seule base de son nom.

### 2.3 SQLite et synchronisation

Le cache local actuel conserve une ligne véhicule indexée par id/companyId/siteId/immatriculation/marque/modèle/couleur/statut et un payload JSON complet. Le moteur utilise une file générique d'opérations contenant companyId, entity, entityId, type, payload et statut.

C'est une bonne base local-first, mais le modèle cible impose :

- une écriture locale et son opération outbox atomiques dans une même transaction SQLite ;
- une clé de partition locale incluant companyId ;
- un identifiant d'opération stable et une stratégie idempotente côté serveur ;
- la gestion des dépendances entre opérations (ex. créer le véhicule avant son affectation) ;
- des migrations locales versionnées et non destructives ;
- une stratégie de rétention pour l'historique GPS, qui peut être volumineux.

---

## 3. Modèle cible — domaine Véhicules

### 3.1 vehicles — identité de l'actif

La ligne véhicule contient uniquement l'identité, les caractéristiques stables et les attributs administratifs qui décrivent l'actif.

| Champ logique | Obligatoire | Règle |
|---|---|---|
| id | Oui | ID stable, conservé entre SQLite et Appwrite |
| companyId | Oui | Tenant propriétaire ; immuable après création |
| siteId | Non | Site de rattachement principal ; référence vers sites lorsque le module Sites est disponible |
| fleetNumber | Non | Code interne de parc ; unique dans l'entreprise lorsqu'il est renseigné |
| registrationNumber | Selon catégorie | Immatriculation normalisée ; peut être absente pour un actif non immatriculé |
| registrationCountry | Oui par défaut DZ | Code pays ISO ; DZ par défaut pour les véhicules algériens |
| registrationKind | Non | National, étranger, temporaire, autre |
| vin | Non | Numéro de châssis/VIN normalisé ; jamais requis pour les actifs qui n'en possèdent pas |
| makeId | Non au brouillon | Identifiant stable du catalogue global vehicle_makes |
| modelId | Non | Identifiant d'un futur catalogue global vehicle_models |
| modelName | Non | Valeur de repli lorsque le modèle n'est pas dans le catalogue |
| modelVariant | Non | Finition/version commerciale |
| modelYear | Non | Année-modèle si connue |
| firstRegistrationDate | Non | Date de première mise en circulation, distincte de l'année-modèle |
| manufactureYear | Non | Année de fabrication si réellement connue |
| vehicleClass | Oui | Catégorie métier : passenger, light_commercial, heavy_goods, bus, motorcycle, agricultural, construction, trailer, other |
| legalGenreCode | Non | Genre réglementaire tel qu'il apparaît sur les documents |
| bodyStyle | Non | Berline, citadine, fourgon, plateau, autocar, etc. |
| fuelType | Non | Essence, diesel, GPL, électrique, hybride, autre |
| engineCapacityCc | Non | Cylindrée en cm³ |
| powerKw | Non | Puissance moteur en kW ; les CV peuvent être affichés/calculés si la définition est connue |
| fiscalPowerCv | Non | Puissance fiscale, distincte de la puissance moteur |
| transmissionType | Non | Manuelle, automatique, autre |
| driveType | Non | Traction, propulsion, intégrale, inconnu |
| seatCount / doorCount | Non | Selon classe de véhicule |
| grossWeightKg / payloadKg | Non | Principalement poids lourds et utilitaires |
| axleCount | Non | Si pertinent |
| color | Non | Couleur constatée ou issue d'un document |
| lifecycleStatus | Oui | draft, active, in_maintenance, immobilized, retired, sold, archived |
| usageProfile | Non | assigned, pool, service, rental, operational, other |
| acquisitionType / acquisitionDate | Non | Données d'acquisition, si disponibles |
| purchasePrice / currency | Non | Montant et devise explicitement liés |
| supplierId | Non | Référence vers un fournisseur de l'entreprise si applicable |
| createdAt / updatedAt | Oui | Dates UTC |
| createdBy / updatedBy | Oui | Identifiants d'acteur |
| schemaVersion | Oui | Version du payload métier lors de la migration progressive |

Règle de création : une fiche brouillon peut être préparée avec un minimum d'informations. Avant activation, le serveur valide qu'au moins un identifiant exploitable existe (immatriculation, VIN/numéro de série ou code interne), ainsi que la catégorie et les champs requis par cette catégorie. Le VIN reste facultatif lorsque le véhicule n'en possède pas ou lorsque le document n'est pas disponible.

### 3.2 Données qui ne doivent PAS devenir des colonnes faisant autorité dans vehicles

| Donnée | Ressource source de vérité |
|---|---|
| Conducteur actuel ou historique | vehicle_assignments |
| GPS actuel et historique | vehicle_location_fixes / tracking_sessions |
| Traceur ou smartphone associé | tracking_devices |
| Parking et emplacement actuel/ancien | vehicle_parking_assignments |
| Kilométrage et heures moteur | vehicle_meter_readings |
| Carte grise, assurance, contrôle technique | vehicle_documents |
| Galerie de photos, dégâts, inspections | vehicle_media / inspections |
| Programme et échéance d'entretien | vehicle_maintenance_plans |
| Intervention réalisée | maintenance_work_orders |
| Dépenses et carburant | vehicle_expenses / fuel_transactions |
| Historique de changements | vehicle_events et journaux des domaines |

L'interface peut afficher des valeurs courantes calculées (conducteur actuel, parking actuel, dernier kilométrage, dernière position). Ces valeurs sont des projections/cache de lecture ; elles ne remplacent jamais les enregistrements historiques sources.

---

## 4. Relations et domaines complémentaires

Les identifiants sont globaux et stables, mais chaque ressource appartenant à une entreprise porte son propre companyId. Une relation ne doit jamais permettre de relier une ligne d'une entreprise à une ligne d'une autre entreprise.

### 4.1 Sites

**sites**

- id, companyId, code, name, address, wilaya, commune ;
- latitude/longitude facultatives pour le centre du site ;
- timezone, status, createdAt, updatedAt.

Le site représente une implantation de l'entreprise. Il ne représente pas une place de parking. Le site peut exister sans parking.

### 4.2 Affectations conducteur-véhicule

**vehicle_assignments**

- id, companyId, vehicleId, driverId ;
- assignmentType (primary, temporary, pool, mission) ;
- startAt, endAt, status ;
- assignedBy, endedBy, reason, notes ;
- meterStart / meterEnd facultatifs.

Une affectation est une relation historisée. Changer de conducteur termine une affectation et en crée une nouvelle ; cela ne remplace pas un simple driverId dans la fiche véhicule.

Règle métier : éviter deux affectations incompatibles simultanées pour un même véhicule. Les usages pool et temporaire doivent être traités explicitement, sans imposer un conducteur permanent.

### 4.3 Smartphones et télématique

**tracking_devices**

- id, companyId, deviceType (smartphone, dedicated_tracker, obd, dashcam, other) ;
- provider, platform, appVersion, deviceLabel ;
- driverId ou userId responsable lorsque l'appareil est un téléphone ;
- vehicleId uniquement lorsqu'un téléphone est dédié à un véhicule ;
- lastSeenAt, lastFixAt, permissionStatus, trackingStatus ;
- createdAt, updatedAt.

**tracking_sessions**

- id, companyId, trackingDeviceId ;
- driverId, vehicleId, vehicleAssignmentId ;
- startedAt, endedAt, startReason, endReason ;
- trackingMode, sessionStatus ;
- policyVersion / noticeVersion lorsque la collecte est activée.

La session lie explicitement un appareil, un conducteur et un véhicule pendant une période. Par défaut, le smartphone est rattaché à un conducteur ; le véhicule est déterminé par l'affectation ou la mission active. Un smartphone fixe dédié à un véhicule reste possible.

**vehicle_location_fixes**

- id, companyId, vehicleId, driverId ;
- trackingDeviceId, trackingSessionId ;
- observedAt (heure de mesure sur l'appareil), receivedAt (heure de réception serveur) ;
- latitude, longitude, horizontalAccuracyMeters ;
- speedMetersPerSecond, headingDegrees, altitudeMeters facultatifs ;
- sourceType (phone_gnss, dedicated_gps, obd, external_provider, manual) ;
- qualityFlags et providerMetadata minimisés.

Une position doit toujours indiquer sa fraîcheur, sa précision et sa source. Une position ancienne n'est jamais affichée comme « temps réel ».

### 4.4 Différence entre smartphone et traceur GPS

Le contrat de données commun est un **location fix** : coordonnées, heure de mesure, précision et, lorsque la source le fournit, vitesse/cap/altitude.

Les données ne sont toutefois pas équivalentes :

| Smartphone | Traceur embarqué |
|---|---|
| GNSS du téléphone + fournisseur de localisation du système | Récepteur GPS dédié et antenne selon appareil |
| Position disponible si l'application, les permissions et l'OS le permettent | Fonctionnement généralement indépendant du téléphone du conducteur |
| Dépend de la batterie, du réseau, des restrictions d'arrière-plan et de l'utilisateur | Peut être alimenté par le véhicule et protégé contre l'arrêt de l'application |
| Pas d'information moteur garantie | Peut fournir alimentation, contact, OBD/CAN ou entrées capteurs si matériel compatible |
| Peut suivre la personne qui porte le téléphone plutôt que le véhicule | Généralement attaché physiquement au véhicule |

**Décision produit : smartphone-first, provider-agnostic.** Le stockage et l'API utilisent le même modèle normalisé ; les champs non fournis restent null et ne sont jamais inventés. Les capacités spécifiques du fournisseur restent dans une métadonnée brute contrôlée ou des tables spécialisées, sans polluer le cœur de Vehicle.

### 4.5 Parking

Le parking est un domaine distinct, préparé dans la phase 1 mais réalisé dans son propre module.

- **parking_lots** : companyId, siteId, code, name, status.
- **parking_zones** : companyId, parkingLotId, code, name, zoneType.
- **parking_spaces** : companyId, parkingZoneId, code, spaceType, dimensions/constraints, status.
- **vehicle_parking_assignments** : companyId, vehicleId, parkingSpaceId, startAt, endAt, assignmentType, assignedBy, status.

Une affectation de parking représente la place attendue/réservée. Une position GPS représente la position observée. Elles ne sont jamais fusionnées.

Le GPS du téléphone peut confirmer qu'un véhicule se trouve à proximité d'un parking ou dans une zone, mais il ne garantit pas la détection de la place exacte. Une confirmation QR/NFC, manuelle, caméra ou capteur pourra être ajoutée plus tard.

### 4.6 Compteurs, documents, médias et maintenance

**vehicle_meter_readings**

- companyId, vehicleId, readingType (odometer_km, engine_hours), value, unit ;
- measuredAt, sourceType, capturedBy, validationStatus, notes.

Le dernier relevé validé donne le compteur courant affiché. Un kilométrage estimé par GPS ne doit pas écraser un relevé manuel ou OBD vérifié sans règle de validation.

**vehicle_documents**

- companyId, vehicleId, documentType, documentNumber ;
- issuedAt, expiresAt, storageBucketId, storageFileId ;
- status, sourceType (manual, OCR, imported), reminders, createdBy.

**vehicle_media**

- companyId, vehicleId, mediaType, storageBucketId, storageFileId ;
- capturedAt, uploadedAt, source, caption, sortOrder, createdBy.

La photo principale est une sélection parmi les médias, pas une deuxième copie de fichier.

**vehicle_maintenance_plans / maintenance_work_orders**

Les plans portent les règles d'échéance (date, kilométrage, heures moteur). Les ordres de travail portent les interventions réelles, pièces, prestataires, coûts et résultats.

**vehicle_events**

Journal append-only des événements significatifs : changement de statut, affectation, transfert de parking, intervention, document ajouté/expiré, anomalie GPS. Il référence la ressource source et l'acteur ; il ne doit pas réécrire une seconde vérité métier.

**vehicle_expenses**

Dépenses et transactions (carburant, réparation, assurance, taxe, autre) avec montant, devise, date, fournisseur et référence facultative.

---

## 5. Catalogue marques et modèles

- vehicle_makes reste un catalogue global partagé, administré côté plateforme.
- makeId est un ID stable, jamais un index de tableau, jamais le nom libre comme clé.
- Un futur vehicle_models global référence makeId et contient normalizedName, displayName, aliases et, si nécessaire, génération/variant.
- modelName reste possible pour un modèle non catalogué ; un utilisateur peut proposer une normalisation au catalogue.
- Les observations OCR/VIN/API ne remplacent pas une valeur confirmée silencieusement : elles créent une suggestion avec source et niveau de confiance.
- Conserver la valeur brute reçue lors d'une migration pour pouvoir auditer et corriger les conversions historiques.

---

## 6. Tenant, autorisations et Appwrite

Pour toutes les ressources opérationnelles tenant-scoped :

1. companyId obligatoire et indexé.
2. siteId facultatif lorsqu'un site existe.
3. rowSecurity activé.
4. Aucune permission générale de table donnant accès à toutes les entreprises.
5. L'écriture passe par une fonction serveur authentifiée qui valide l'utilisateur, le contexte entreprise, le rôle, le quota lorsque pertinent et la cohérence des relations.
6. Les permissions de ligne sont créées selon le modèle d'accès du tenant.
7. Les lectures Flutter restent filtrées par companyId, mais le filtre UI n'est jamais la frontière de sécurité.
8. Toute relation (vehicleId, driverId, siteId, parkingSpaceId, trackingDeviceId) est résolue et validée dans le même companyId.

Les catalogues réellement partagés (marques, éventuellement modèles) sont des ressources plateforme distinctes. Les caches d'images ne doivent jamais devenir une source de données opérationnelles du tenant.

---

## 7. Offline-first et synchronisation

Le registre local et Appwrite doivent partager les mêmes identifiants métier.

### Règles d'écriture

- La mutation du cache local et l'insertion de l'opération outbox sont atomiques.
- Une opération possède operationId stable, companyId, entity, entityId, operationType, payloadVersion, createdAt, retryCount, status et diagnostic.
- Les opérations dépendantes respectent l'ordre parent-enfant : véhicule avant affectation, site avant parking, session avant position.
- Chaque handler serveur est idempotent ; rejouer une opération déjà appliquée doit converger vers le même résultat sans double quota, doublon ou événement.
- Une opération en conflit ne doit jamais être supprimée silencieusement. La résolution indique retry, merge, discard ou correction manuelle et conserve une trace.
- Un changement d'entreprise coupe le moteur précédent, récupère uniquement la partition du nouveau companyId et ne transfère jamais une opération d'un tenant vers un autre.
- Les positions GPS peuvent être mises en tampon localement hors ligne ; elles sont envoyées par lots et dédupliquées par ID. La date de mesure et la date de réception restent distinctes.

### Partition locale

Les clés et indexes locaux sont company-scoped. Le modèle cible recommande les clés composites (companyId, id) pour les entités tenant-scoped et les indexes companyId + champs de recherche. Le cache d'un tenant ne doit jamais être réutilisé pour un autre.

---

## 8. Recherche, index et performance

Indexes logiques à prévoir selon les capacités TablesDB :

- vehicles : (companyId, registrationNormalized), (companyId, fleetNumber), (companyId, vinNormalized), (companyId, siteId), (companyId, lifecycleStatus), (companyId, makeId, modelId).
- assignments : (companyId, vehicleId, startAt), (companyId, driverId, startAt).
- parking assignments : (companyId, parkingSpaceId, status), (companyId, vehicleId, status).
- location fixes : (companyId, vehicleId, observedAt), (companyId, trackingDeviceId, observedAt).
- documents : (companyId, vehicleId, expiresAt, status).
- meter readings : (companyId, vehicleId, readingType, measuredAt).
- maintenance : (companyId, vehicleId, dueAt, status).

Les contrôles d'unicité sont tenant-scoped et validés côté serveur. La stratégie doit tenir compte des champs optionnels et des limites des indexes TablesDB ; ne pas supposer qu'un index partiel est disponible.

---

## 9. Confidentialité et contraintes algériennes du GPS

### 9.1 Situation réglementaire à vérifier

Les textes officiels consultés ne permettent pas de conclure que « tous les GPS sont simplement interdits ». Ils montrent en revanche un régime réglementaire sérieux :

- Le décret exécutif 09-410 du 10 décembre 2009 classe dans les équipements sensibles les équipements de radio-positionnement/radiolocalisation par satellite, les systèmes de géolocalisation par radio et les dispositifs de positionnement par satellite via les réseaux mobiles (annexe I, section A, sous-section 2, paragraphe 2).
- L'ARPCE publie une procédure de géolocalisation par radio demandant notamment une architecture technique, les marques/types d'équipements, les fiches techniques des balises et, selon le service, des agréments/autorisations.
- Les textes de 2011 et leurs modifications encadrent l'acquisition, la détention, l'exploitation, l'utilisation et la cession des équipements sensibles.
- Il faut distinguer l'achat d'un appareil, son importation, sa détention, son usage interne par une entreprise et la fourniture d'un service de géolocalisation à des tiers. Les obligations peuvent différer.

Sources officielles :
- Décret 09-410, Journal officiel n°73 du 13/12/2009 : https://www.joradp.dz/FTP/jo-francais/2009/F2009073.pdf
- ARPCE — Géolocalisation par radio : https://www.arpce.dz/fr/service/gps
- ARPCE — Homologation : https://www.arpce.dz/fr/service/agr
- Loi 18-07 : https://www.aece.dz/static/docs/Loi_n_18-07.pdf

**Décision provisoire :** ne pas acheter, importer, distribuer ou installer un tracker dédié dans Parcoto tant que la situation de l'appareil et de l'usage projeté n'a pas été confirmée par écrit auprès des autorités compétentes (ARPCE et services concernés de la wilaya).

Le smartphone constitue la première source technique à étudier, mais il ne faut pas le considérer automatiquement comme une exemption juridique. Il utilise un terminal mobile ordinaire, son GNSS intégré et une application ; la qualification de la collecte et de l'exploitation des positions doit également être confirmée.

### 9.2 Protection des données personnelles

Une position liée à un conducteur peut permettre de localiser une personne. La loi 25-11 du 24 juillet 2025, qui modifie la loi 18-07, ajoute explicitement la localisation et les déplacements dans la définition du profilage. Elle introduit aussi, dans le régime général, des obligations de registre des activités de traitement et de journalisation des opérations. La même loi prévoit une étude d'impact pour les traitements à risque élevé dans son nouveau Titre V bis, consacré aux traitements réalisés par les autorités compétentes à des fins de prévention/détection des infractions et de procédures pénales : il ne faut pas extrapoler automatiquement cette disposition spéciale à tout traitement privé de flotte. Pour Parcoto, une analyse de risques reste nécessaire et l'obligation exacte d'une étude d'impact doit être confirmée auprès du conseil compétent et de l'autorité nationale.

La loi 18-07 prévoit des principes de finalité déterminée, minimisation, exactitude et durée de conservation nécessaire. Son article 44 encadre les transferts de données personnelles vers l'étranger et son article 45 prévoit des dérogations sous conditions. Le projet Parcoto utilise actuellement un endpoint Appwrite en région FRA ; le transfert des positions liées aux conducteurs doit donc être validé avant activation en production.

Sources :
- Loi 25-11 du 24/07/2025, Journal officiel n°48 : https://www.douane.gov.dz/IMG/pdf/loi_18-07_du_24_07_2025_fr_dz.pdf
- Loi 18-07, articles 9, 44 et 45 : https://www.aece.dz/static/docs/Loi_n_18-07.pdf
- Portail du ministère de la Justice — loi 18-07 modifiée par loi 25-11 : https://droit.mjustice.gov.dz/fr/content/protection-des-personnes-physiques-dans-le-traitement-des-donn%C3%A9es-%C3%A0-caract%C3%A8re-personnel

Principes de conception :
- finalité claire (sécurité/gestion de flotte) et information transparente du conducteur ;
- tracking activé sur une session professionnelle explicite, pas en continu sur le temps privé ;
- permission système et état de suivi visibles dans Parcoto Connect ;
- arrêt de la session à la fin de mission/service et mécanisme de révocation ;
- accès aux positions limité par rôle ;
- chiffrement, journal d'accès, durée de conservation configurable et purge contrôlée ;
- séparation des données du conducteur et de celles du véhicule ;
- étude d'impact et validation du transfert international avant lancement réel.

Ce document est une analyse technique, pas un avis juridique. La conformité du traitement doit être confirmée par un conseil compétent et l'autorité nationale de protection des données lorsque nécessaire.

---

## 10. Migration progressive sans perte

### Étape A — Inventaire et correspondance

- Exporter les schémas et les nombres de lignes.
- Identifier tous les lecteurs/écrivains de chaque champ historique.
- Cartographier les colonnes legacy et le payload Flutter.
- Vérifier l'appartenance tenant des lignes et la cohérence des relations.
- Marquer les données impossibles à interpréter automatiquement comme « à revoir ».

### Étape B — Extension compatible

- Ajouter les nouvelles colonnes et tables sans retirer les anciennes.
- Conserver les IDs existants.
- Garder une lecture compatible avec les lignes legacy.
- Écrire le modèle canonique et les projections legacy pendant la période de transition.
- Ajouter schemaVersion et les journaux de migration.

### Étape C — Backfill contrôlé

- Convertir les index de marques uniquement via la correspondance historique vérifiée.
- Normaliser immatriculations, VIN, catégories et statuts.
- Déduire les affectations historiques seulement si une preuve de relation existe.
- Ne jamais déduire l'entreprise uniquement depuis createdBy.
- Produire un rapport des lignes converties, ignorées et ambiguës.

### Étape D — Bascule

- Tester deux entreprises isolées et un Super Admin en exploration.
- Tester create/update/delete offline, conflits, reprise après crash et changement de tenant.
- Comparer les enregistrements legacy et canoniques.
- Basculer l'interface après validation.
- Retirer les anciennes colonnes uniquement après preuve qu'aucun lecteur/écrivain ne les utilise.

Aucune donnée actuelle ne doit être purgée pendant les phases A à C.

---

## 11. Découpage de réalisation

| Sous-phase | Livrable | Critère d'acceptation |
|---|---|---|
| 1.1 Audit confirmé | Inventaire des modèles et tables existants | Chaque champ legacy important a une source et un sens documentés |
| 1.2 Domaine cible | Entités, relations, cardinalités, statuts | Pas de conducteur/GPS/parking stocké comme champ maître dans vehicles |
| 1.3 Contrat Appwrite | Tables, champs, indexes, ACL, quotas | companyId validé côté serveur et row-level security testée |
| 1.4 Contrat SQLite/sync | Migrations locales, outbox, dépendances, idempotence | Écriture locale + outbox atomiques et reprise testée |
| 1.5 Migration | Mapping historique et scripts dry-run | Rapport sans perte, conversions ambiguës isolées |
| 1.6 Gate GPS légal | Confirmation de la qualification smartphone/service et du transfert | Avis écrit et traitement privacy validé avant collecte production |

### Hors périmètre de la phase 1

- Aucun écran formulaire ou fiche n'est refait maintenant.
- Aucune table Parking/GPS n'est créée en production maintenant.
- Aucun tracker n'est acheté/importé.
- Aucun suivi de conducteur n'est activé.
- Aucune colonne historique n'est supprimée.
- Aucune donnée de véhicule existante n'est convertie en masse.

**Sortie attendue de la phase 1 :** un modèle métier stable, un contrat Appwrite/SQLite vérifiable, une stratégie de migration et des décisions explicites sur le GPS smartphone et la confidentialité. La phase 2 pourra alors refaire l'interface sans devoir réinventer les données en cours de route.
