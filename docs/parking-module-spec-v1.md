# Parcoto — Spécification fonctionnelle et technique du module Parking v1

**Statut :** spécification de référence validée — décisions produit du 28/11/2026  
**Branche cible :** `master`  
**Dépendances :** identité/tenant, véhicules, Parcoto Connect  
**Périmètre :** conception des plans, exploitation des parkings, affectations historisées et intégration véhicule.

## 1. Décisions produit figées

| Sujet | Décision |
|---|---|
| Concepteur | Double mode : assistant guidé + éditeur vectoriel libre |
| Plan de fond | Import d'image/PDF rasterisé ou plan existant + édition vectorielle superposée |
| Entrées / sorties | Saisie manuelle + détection de plaque via Parcoto Connect |
| Source de vérité d'une place | Géométrie vectorielle + ligne `parking_spaces` |
| Source de vérité de l'occupation | Affectation active `vehicle_parking_assignments`, pas un booléen isolé |
| Historique | Append/historisation ; clôturer l'affectation précédente, ne jamais l'écraser |
| Multi-tenant | `companyId` obligatoire et validation serveur de chaque parent |
| Offline | SQLite natif local-first ; Web online-only dans l'architecture actuelle |
| GPS | La position smartphone reste distincte de l'emplacement physique dans le parking |

## 2. Objectifs et non-objectifs

### Objectifs
- Décrire fidèlement un site, ses parkings, zones, rangées et places.
- Concevoir un plan à l'échelle, lisible et manipulable à la souris ou au tactile.
- Générer des centaines de places de façon déterministe, puis ajuster individuellement chaque objet.
- Visualiser l'occupation et trouver rapidement une place compatible.
- Affecter, déplacer, réserver, bloquer, libérer et historiser les places.
- Rattacher l'emplacement physique à la fiche véhicule sans dupliquer la donnée.
- Autoriser les entrées/sorties manuelles et les événements issus du scan de plaque Connect.
- Rester compatible avec les cinq thèmes Parcoto (Obsidian, Arctic, Emerald, Amethyst, Sunset).

### Hors périmètre v1
- Suivi GPS permanent ou traceur matériel.
- Barrière connectée, contrôle d'accès IoT ou paiement.
- Optimisation automatique de circulation / simulation de trafic.
- Collaboration temps réel multi-utilisateur dans le même canvas.
- Import CAD natif DWG/DXF en v1. Prévoir un import d'image/PDF et une architecture d'adaptateur pour DXF ultérieur.
- Édition du plan sur Parcoto Connect : Connect est d'abord un client d'exploitation entrée/sortie.

## 3. Hiérarchie métier

`Entreprise → Site → Parking → Zone → Rangée (regroupement logique) → Place`

- **Site** : implantation géographique de l'entreprise.
- **Parking** : espace physique indépendant rattaché à un site. Un site peut avoir plusieurs parkings.
- **Zone** : secteur fonctionnel (standard, visiteurs, livraison, restreint, recharge, maintenance, PMR, deux-roues, poids lourds).
- **Rangée** : regroupement de places pour génération, numérotation et sélection ; ce n'est pas une frontière obligatoire de stockage.
- **Place** : unité opérationnelle affectable à un véhicule.
- **Objet de plan** : élément graphique sans occupation métier (voie, mur, portail, entrée, sortie, bâtiment, obstacle, zone piétonne, végétation, annotation, mesure).

Un parking peut être exploité sans plan graphique importé ; un plan peut être dessiné de zéro.

## 4. Concepteur — modes et comportements

### 4.0 Complexité progressive — principe UX obligatoire

Le concepteur propose deux niveaux d'usage sur le même modèle de données. Il ne s'agit pas de deux éditeurs ni de deux formats de plan : changer de niveau ne doit jamais dupliquer, convertir ou perdre les objets.

**Mode guidé (par défaut)**
- L'utilisateur décrit son parking par étapes courtes : site, dimensions approximatives, zones, type de stationnement et nombre de places.
- Parcoto propose des valeurs par défaut adaptées au type de parking, des modèles de disposition et une génération prévisualisée avant validation.
- Les champs techniques (coordonnées, angles, calques, transformations) restent masqués tant qu'ils ne sont pas nécessaires.
- Chaque étape explique ce qui est demandé, montre le résultat sur le plan et signale les erreurs avec une correction proposée.
- L'utilisateur peut revenir en arrière, modifier les paramètres et poursuivre sans recommencer le plan.

**Mode avancé (activable à la demande)**
- Donne accès au canvas vectoriel complet, aux coordonnées métriques, unités, grille, accrochage, rotations, dimensions, calques et propriétés de chaque objet.
- Autorise la modification individuelle ou multiple, les alignements, duplications, mesures et réglages géométriques précis.
- Expose les propriétés techniques du fond importé : calibration, opacité, transformation et verrouillage.
- Ne contourne jamais les validations métier : les outils avancés ne peuvent pas créer une géométrie invalide, une place hors zone ou une affectation incohérente.

**Règles communes**
- Le mode guidé est le point d'entrée pour tout nouvel utilisateur ; le mode avancé est toujours accessible aux rôles autorisés.
- Le passage guidé ↔ avancé conserve exactement les mêmes objets, identifiants, géométries et brouillon.
- Les préférences de niveau d'interface sont individuelles ; elles ne changent ni les permissions ni les données partagées du parking.
- Sur mobile, l'exploitation et le parcours guidé sont prioritaires. Le mode avancé reste disponible avec des panneaux et commandes tactiles adaptés, sans réduire les outils à des cibles minuscules.
- Les modèles prédéfinis accélèrent la création mais restent modifiables ; aucun modèle ne crée des places silencieusement sans aperçu et confirmation.

### 4.1 Assistant guidé
1. Créer le site et le parking (code, nom, adresse, fuseau horaire, statut).
2. Définir l'emprise du plan (largeur/hauteur en mètres) et l'échelle.
3. Créer les zones (code, nom, type, couleur de représentation).
4. Créer une rangée : zone, orientation, point de départ, nombre de places, dimensions, espacement, angle, sens de numérotation et préfixe.
5. Prévisualiser les codes avant génération (ex. A-001 à A-024).
6. Confirmer la génération ; chaque place obtient son propre ID et sa géométrie.
7. Ajuster une place, une rangée ou la sélection sans casser les autres objets.

Le générateur doit gérer les rangées horizontales/verticales, les orientations inversées, les places en bataille/épi/parallèle, l'espacement et les limites de zone. La largeur de place définit le pas entre les places ; l'orientation verticale tourne la rangée et les emprises de 90° dans le repère du plan. Le calcul géométrique se fait en mètres dans le repère local du plan, pas en pixels écran.

### 4.2 Éditeur vectoriel libre
Outils v1 : sélection/déplacement, pan, zoom, sélection multiple, rectangle, polygone, ligne, place, rangée, zone, voie, mur, entrée, sortie, portail, obstacle, texte/cote, mesure, annuler/rétablir, aligner, dupliquer, supprimer.
- Accrochage grille configurable et aimantation aux points/axes.
- Rotation et redimensionnement avec poignées.
- Sélection par clic et rectangle de sélection.
- Verrouillage du fond importé et des calques.
- Calques : fond, limites/zones, circulation, places, annotations.
- Contrôles zoom/pan adaptés souris, trackpad et tactile.
- Un objet sélectionné expose ses propriétés dans un inspecteur latéral ; la sélection ne doit pas être pilotée uniquement par des menus contextuels.

### 4.3 Import et calibration du fond
- Formats initiaux : PNG, JPEG, WebP et PDF (page choisie, rasterisée).
- Conserver le fichier source dans Storage ; conserver les métadonnées et la transformation dans `parking_layouts`.
- Calibration par deux points dont la distance réelle est connue ; permettre de saisir l'unité et la distance.
- Ajuster opacité, rotation, position, échelle et verrouillage du fond.
- Le fond est une référence visuelle : les places et objets restent des vecteurs indépendants.
- L'import ne doit jamais générer automatiquement des places sans confirmation humaine.
- Ne pas stocker les octets/base64 de l'image dans une colonne JSON.

## 5. Modèle de données cible

Les tables métier déjà proposées dans `vehicle-appwrite-schema-v1.md` restent la base : `sites`, `parking_lots`, `parking_zones`, `parking_spaces`, `vehicle_parking_assignments`. Ce contrat n'affirme pas que ces tables sont déjà créées dans Appwrite.

### 5.1 Extensions de `parking_lots`
- `siteId` (string 36, requis), `code` (string 40), `name` (string 120), `address`, `status`.
- `layoutId` facultatif (string 36) vers la version active du plan.
- Centre WGS84 facultatif ; ne pas confondre coordonnées géographiques et coordonnées locales du dessin.

### 5.2 Nouvelle table `parking_layouts`
Colonnes communes tenant-scoped + :
- `parkingLotId` string(36), `name` string(120), `version` integer, `status` string(16: draft/published/archived).
- `widthM`, `heightM` double strictement positifs ; `unit` string(8), `gridStepM` double.
- `backgroundFileId` string(36) nullable ; `backgroundTransformJson` longtext nullable (position, scale, rotation, opacity, calibration).
- `layersJson` longtext versionné pour les objets graphiques non métier (voie, murs, portails, obstacles, annotations), avec schéma et limites strictes.
- `publishedAt` datetime nullable, `publishedBy` string(36) nullable.
- Index : (companyId, parkingLotId, status), unique (companyId, parkingLotId, version).

### 5.3 Extensions de `parking_zones`
- `zoneType` contrôlé : standard, visitor, delivery, restricted, charging, maintenance, accessible, motorcycle, heavy_goods, other.
- `geometryJson` versionné (polygone en coordonnées locales mètres) ; `sortOrder` integer ; `colorToken` string(32) optionnel.
- Une zone peut exister sans polygone pendant la configuration initiale.

### 5.4 Extensions de `parking_spaces`
- Métier : `parkingZoneId`, `code`, `spaceType`, capacités max (longueur/largeur/hauteur/poids), `status` (active/inactive/blocked/maintenance).
- Géométrie locale : `xM`, `yM`, `widthM`, `lengthM`, `rotationDeg` en double ; `shapeType` string (rectangle/polygon) ; `geometryJson` nullable pour formes non rectangulaires ; `rowCode` string(40) nullable ; `sortOrder` integer.
- Géométrie rectangulaire normalisée dans le repère du parking ; `xM`/`yM` représentent le centre de la place, et non son coin supérieur gauche. Ne pas enregistrer des pixels dépendants de la résolution.
- Les dimensions de capacité véhicule et les dimensions graphiques de la place sont deux données distinctes.

### 5.5 `vehicle_parking_assignments`
- `vehicleId`, `parkingSpaceId`, `assignmentType` (reserved/assigned/temporary), `status` (active/ended/cancelled), `startAt`, `endAt`, `assignedBy`, `notes`.
- Ajouter `sourceType` (manual/connect_scan/import/system), `entryEventId` facultatif, `exitEventId` facultatif, `endedBy` facultatif.
- Les affectations physiques (`assigned` / `temporary`) ne peuvent pas se chevaucher pour une même place ni pour un même véhicule.
- Une réservation (`reserved`) est une fenêtre temporelle, jamais une occupation physique immédiate ; elle exige une date de fin.
- Les intervalles sont semi-ouverts `[startAt, endAt)` : une affectation qui se termine à 12:00 ne chevauche pas une nouvelle affectation qui commence à 12:00.
- Les réservations peuvent coexister avec l'affectation physique en cours uniquement si leurs fenêtres ne se chevauchent pas. Cette règle est vérifiée dans une transaction par la politique métier locale et côté serveur ; les index uniques SQLite protègent les seules affectations physiques instantanées.
- Validation de compatibilité dimensions/catégorie/capacité côté serveur.
- Transaction atomique : clôture de l'affectation active + création de la suivante + événement métier/receipt.

### 5.6 Événements d'entrée/sortie
Créer `parking_access_events` append-only :
- `parkingLotId`, `vehicleId` nullable si plaque non résolue, `assignmentId` nullable, `eventType` (entry/exit/unknown_plate/manual_correction), `sourceType` (manual/connect_scan), `occurredAt`, `recordedAt`, `registrationCaptured`, `registrationNormalized`, `confidence` double nullable, `deviceId` nullable, `actorUserId` nullable, `notes`.
- Une plaque détectée n'est pas une preuve d'identité : afficher la correspondance proposée et demander confirmation si plusieurs véhicules correspondent ou si le score OCR est faible.
- Un scan ne doit jamais créer silencieusement un véhicule ou une affectation.

### 5.7 Contraintes communes
- Toutes les tables tenant-scoped : `companyId` obligatoire, rowSecurity activé, permissions de ligne tenant, aucune permission globale.
- Le serveur dérive le tenant depuis le contexte autorisé et valide tous les parents dans le même tenant.
- Tables de journal append-only ; correction par événement compensatoire.
- IDs stables ; dates UTC ; `revision` incrémentée côté serveur.
- Les index et tailles doivent être validés sur un staging isolé avant toute création dans le projet Appwrite actif.
- Aucune migration ou création de table Appwrite live pendant la phase de conception/développement local.

## 6. Exploitation quotidienne

### Vue d'ensemble
- KPI : capacité totale, occupées, libres, réservées, bloquées, taux d'occupation.
- Plan interactif avec légende, filtres zone/type/état, recherche par immatriculation ou code place.
- Liste/plan synchronisés : sélectionner une ligne met en évidence la place et inversement.
- Panneau de détail de la place : statut, dimensions, zone/rangée, véhicule, date d'entrée, durée d'occupation, actions autorisées.

### Actions
- Affecter un véhicule à une place libre.
- Déplacer un véhicule (transaction de fin + nouvelle affectation).
- Réserver une place avec début/fin ; réservation expirée traitée explicitement.
- Bloquer/débloquer une place avec motif et période facultative.
- Enregistrer entrée/sortie sans place connue ; résoudre ensuite.
- Libérer une place ; l'historique conserve véhicule, place, dates, source et acteur.
- Recherche de places compatibles : type, gabarit, hauteur, poids, zone autorisée, état.

### États à ne pas confondre
- État physique : active / inactive / blocked / maintenance.
- Occupation : free / occupied / reserved.
- Une place en maintenance ou bloquée n'est jamais considérée libre pour une affectation.
- Une réservation est une affectation planifiée ou un état dérivé ; elle ne doit pas être confondue avec l'occupation physique constatée.
- Le statut « réservée » est calculé à partir d'une réservation dont la fenêtre inclut l'instant considéré ; en dehors de cette fenêtre, la place n'est ni occupée ni réservée par cette ligne.

## 7. Intégration véhicule

La fiche véhicule affichera une carte « Stationnement actuel » :
- site, parking, zone, rangée, code de place ;
- statut et date de début d'affectation ;
- action « Voir sur le plan » ;
- action « Déplacer » / « Affecter une place ».

La source de vérité est `vehicle_parking_assignments`. Le champ legacy `location/emplacement` reste lisible pour compatibilité mais n'est pas utilisé pour déterminer le stationnement courant.

La fiche véhicule peut exister sans parking ni affectation. Le parking n'est jamais un prérequis à la création d'un véhicule.

## 8. Parcoto Connect — entrée/sortie par plaque

Flux proposé :
1. L'agent choisit le parking et lance le mode entrée ou sortie.
2. Connect capture une image et propose la plaque détectée.
3. Normalisation (espaces, tirets, casse) et recherche tenant.
4. Présentation du véhicule candidat, de sa dernière affectation et des doublons éventuels.
5. Confirmation humaine.
6. Entrée : choisir/attribuer une place ou enregistrer une entrée sans place.
7. Sortie : clôturer l'affectation active correspondante et créer l'événement de sortie.
8. Synchronisation idempotente ; si le réseau est absent, conserver une opération locale avec ID stable sur Connect, sans prétendre qu'elle est confirmée par le serveur.

Le mode manuel reste entièrement fonctionnel sans Connect, caméra ou OCR.

## 9. Permissions et rôles

| Rôle | Conception | Exploitation |
|---|---|---|
| Admin | CRUD et publication | Toutes actions |
| Manager | Créer/modifier selon politique entreprise | Affecter, déplacer, réserver, bloquer, entrée/sortie |
| Employee | Lecture du plan | Actions limitées au flux autorisé (ex. entrée/sortie) |
| Viewer | Lecture | Lecture seule |
| Super Admin plateforme | Accès via contexte explicite de supervision | Aucun contournement ACL direct |

Les autorisations doivent être appliquées dans l'API serveur, pas seulement en masquant les boutons.

## 10. UX et responsive

- Desktop : canvas central, barre d'outils, inspecteur latéral, arbre parking/zones, bandeau KPI.
- Tablette : canvas prioritaire, inspecteur en panneau repliable.
- Mobile : exploitation et consultation d'abord ; gestes tactiles, cibles tactiles ≥44 px, panneau inférieur pour les détails. L'édition avancée reste possible mais les outils doivent être adaptés, jamais miniaturisés.
- Respect du thème actif via les tokens Parcoto ; aucun cyan/bleu codé en dur.
- Pas de scroll imbriqué qui bloque les gestes du plan ; le canvas capture pan/zoom uniquement dans sa surface.
- Navigation permanente vers la vue d'ensemble du parc et le site courant.

## 11. Architecture technique

- Domaine indépendant : `parking`.
- Modèles métier purs sans dépendance Flutter/Appwrite.
- Générateur de rangées déterministe et testé.
- Canvas vectoriel utilisant coordonnées monde en mètres et transformation caméra séparée.
- Repositories séparés local/remote, API tenant dédiée, mapping explicite.
- SQLite natif : migrations locales additives v13 à v17, stockage tenant-scoped et transactions atomiques pour la configuration et les affectations Parking.
- Web : aucun faux cache Parking ; l'accès est fermé tant que les tables Appwrite et handlers distants ne sont pas provisionnés. Le reste de Parcoto Web conserve son mode online-only.
- Les médias de fond sont dans Storage ; les métadonnées seules sont dans TablesDB.
- Les opérations multi-lignes utilisent transaction Appwrite, idempotency key et validation des invariants côté serveur.

## 12. État de l'implémentation sur master

La première tranche locale du module est enregistrée sur `master` :

- Modèles métier typés et sérialisation pour sites, parkings, plans, zones, places, affectations, événements d'accès et médias.
- Stockage SQLite natif tenant-scoped, avec vérification des références parentales et transactions atomiques.
- Assistant initial de création : site + parking + plan métrique + zone + rangées/places générées.
- Validation de l'emprise du plan et des zones pour les géométries de places, y compris rectangles tournés.
- Déplacements et clôtures d'affectation transactionnels ; les événements d'entrée/sortie peuvent être enregistrés dans la même transaction.
- Vue d'exploitation alimentée par SQLite, sans jeu de données de démonstration.
- Import local des fonds raster PNG/JPEG/WebP (20 Mo maximum), avec calibration à deux points, alignement horizontal/vertical et affichage sous les géométries vectorielles.

**Limite volontaire :** le module Parking n'est pas synchronisé avec Appwrite à ce stade. Le projet Appwrite actif n'a pas été modifié ; aucune table distante ni fonction Parking n'a été déployée. Le stockage Web échoue explicitement tant que le backend distant n'est pas disponible. Les données locales natives restent sur l'appareil et ne sont pas partagées entre appareils.

L'interface actuelle livre l'assistant guidé, l'inspection des places, le rendu métrique et l'import calibré des fonds raster sur les installations natives. Les fichiers importés restent dans le dossier applicatif local du tenant. PDF n'est pas pris en charge dans ce lot ; l'import Web reste désactivé tant que le stockage distant n'est pas provisionné.

L'éditeur vectoriel libre (création/déplacement de formes, calques, propriétés avancées, undo/redo), l'import PDF avec moteur de rendu, la gestion des entrées/sorties depuis Parcoto Connect, les permissions serveur et la synchronisation distante restent des lots suivants.

## 12. Plan de réalisation et critères de sortie

### Phase P0 — spécification et contrats
- Spécification validée, décisions figées, schéma cible et règles métier.
- Aucun changement de production Appwrite.

### Phase P1 — fondations métier et stockage
- Entités, value objects, validation géométrique, générateur de rangées.
- Repositories et contrat de synchronisation.
- Migration SQLite non destructive et tests d'isolation tenant.
- API tenant Appwrite avec actions explicitement autorisées.
- Critère : tests domaine, SQLite rollback/atomicité, retry/idempotence, isolation tenant.

### Phase P2 — concepteur visuel
- Import/calibration fond, canvas, calques, outils vectoriels.
- Génération guidée, sélection/propriétés, undo/redo.
- Critère : sauvegarde/rechargement sans perte géométrique, précision d'échelle, responsive.

### Phase P3 — exploitation
- Occupation, réservation, blocage, recherche, affectation, déplacement, historique.
- Entrées/sorties manuelles.
- Critère : aucun double booking sous concurrence, transactions idempotentes.

### Phase P4 — intégration Connect et véhicules
- OCR assisté, confirmation, entrée/sortie et lien vers fiche véhicule.
- Stationnement courant dans la fiche véhicule.
- Critère : erreurs OCR, plaques inconnues/doublons, retry hors ligne et historique testés.

### Phase P5 — validation
- Tests unitaires, widget, intégration, build Web et desktop, multi-tenant, permissions et responsive.
- Migration dry-run staging, ACL, index et audit avant tout déploiement Appwrite.

## 13. Règles de livraison

- Développement sur `master`, comme demandé.
- Petits commits cohérents, diff audité avant chaque écriture.
- Pas de création de tables, ACL ou migration dans l'Appwrite actif sans validation staging distincte.
- Ne pas marquer une phase terminée sur la seule base d'une maquette ou d'un écran statique.
- La fonctionnalité n'est considérée « terminée » qu'après tests automatisés, validation du flux réel et vérification CI.
