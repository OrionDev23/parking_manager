# Parcoto — Audit véhicule et référence des formulaires guidés

**Branche auditée :** `refactor/foundation-v1`  
**Date :** 28 novembre 2026  
**Périmètre :** formulaire véhicule, fiche détaillée, navigation parc, modèle de domaine et conventions de formulaire  
**GPS / carte interactive :** spécifiés dans la feuille de route, volontairement non implémentés dans cette étape  
**Nature :** audit du code existant et contrat de conception ; aucune migration Appwrite

---

## 1. Synthèse

La partie Véhicules dispose déjà de fondations utiles : un modèle de domaine distinct de l'ancien sérialisable, un repository, une synchronisation locale/distance, un catalogue canonique de marques, un service de décodage VIN, une recherche d'images et une fiche de consultation découpée en rubriques.

Le principal problème UX est le formulaire de création/modification : `lib/screens/vehicle/manager/vehicle_form.dart` concentre environ 4 189 lignes dans un seul parcours défilant. Il n'existe pas encore de véritable assistant à étapes avec validation locale, état de progression, brouillon récupérable et résumé des éléments manquants. Le système visuel de champs partagé (`ParcotoFormField`) est une bonne base, mais il ne constitue pas un moteur de formulaire.

La fiche détaillée (`vehicle_details_page.dart`) est déjà plus structurée. Elle utilise neuf rubriques, une navigation persistante sur mobile et un retour explicite au parc. Elle a néanmoins quelques incohérences de sémantique et des domaines encore portés par des valeurs legacy.

**Décision :** ne pas réécrire la fiche ni le formulaire en bloc. Stabiliser les règles métier et les problèmes avérés, construire une référence de formulaire guidé réutilisable, puis migrer les écrans un par un.

## 2. Corrections réalisées dans cette étape

### 2.1 Valeurs initiales du nouveau véhicule

Les nouvelles fiches ne doivent pas recevoir une valeur métier que l'utilisateur n'a jamais confirmée.

- La quittance n'est plus préremplie à `800`.
- La date du document d'immatriculation reste vide tant qu'elle n'est pas choisie.
- L'année d'usage legacy ne démarre plus artificiellement à 2023.
- La wilaya ne démarre plus à `16` sans sélection ou déduction fiable depuis l'immatriculation.
- En modification, une date ou une année réellement absente reste absente.

Le pays par défaut `DZ` demeure, car il correspond au contexte de création algérien et peut être explicitement remplacé.

### 2.2 Séparation titulaire / conducteur

Le mapper du domaine confirme que `nom`, `prenom` et `profession` alimentent les propriétés du titulaire enregistré. Le conducteur est, lui, identifié par `matriculeConducteur`.

La sélection d'un conducteur ne recopie donc plus son nom, son prénom, sa profession, son adresse ou son indicateur de service dans les propriétés du titulaire et du véhicule. Elle renseigne le matricule du conducteur et son appartenance conducteur, qui sont les seules informations spécifiques à ce lien dans le formulaire legacy actuel.

Cette correction évite une corruption silencieuse des données administratives. La relation normalisée véhicule-conducteur reste un chantier distinct.

### 2.3 Cohérence d'année dans la fiche

L'en-tête de la fiche détaillée n'utilise plus `modelYear ?? anneeUtil`. L'année-modèle est affichée comme telle ; l'année d'usage legacy reste séparée dans la rubrique administrative tant que son sens exact n'est pas validé.

### 2.4 Cycle de vie des contrôleurs

Les contrôleurs `TextEditingController` possédés par le formulaire sont maintenant libérés dans `dispose()`.

## 3. Audit du formulaire actuel

### 3.1 Structure et ergonomie

État observé :

- formulaire monolithique, organisé en longues sections à l'intérieur d'un seul scroll ;
- aperçu latéral disponible uniquement sur les grandes largeurs ;
- pas de progression étape par étape ;
- pas de validation de l'étape avant passage à la suivante ;
- pas de récapitulatif des champs obligatoires manquants ;
- pas de sauvegarde de brouillon et de reprise explicitement gérées par le parcours ;
- plusieurs champs conditionnels pilotés par la configuration ou d'anciens drapeaux globaux ;
- pas de formulaire racine avec validation centralisée de type `FormState`.

Le découpage métier doit devenir explicite : identité, immatriculation et titulaire, caractéristiques, affectation, acquisition, puis documents et médias.

### 3.2 Contrôles et données à traiter

| Domaine | Champs actuels / existants | Règle cible |
|---|---|---|
| Identité | catégorie implicite, marque, modèle/type, finition, année-modèle, VIN | Distinguer catégorie, marque, modèle, finition et année-modèle |
| Immatriculation | nationale segmentée ou étrangère, pays, anciennes plaques | Validation selon le pays et le type d'immatriculation ; normalisation séparée de la valeur affichée |
| Carte grise | date legacy, référence, quittance, wilaya, daïra, commune, adresse | Distinguer date du document et première mise en circulation ; unité de quittance à confirmer |
| Titulaire | nom, prénom, profession | Ne pas les remplir depuis le conducteur sélectionné |
| Caractéristiques | genre, carrosserie, énergie, cylindrée, puissance fiscale, puissance moteur, transmission, boîte, motricité, portes, places, poids, charge utile, dimensions | Chaque quantité doit avoir une unité et une validation de plage |
| Affectation | matricule conducteur, appartenance conducteur, appartenance, filiale, direction, département, type d'usage | Relation conducteur séparée des champs du titulaire et de l'organisation |
| Acquisition | type, date, prix, fournisseur, garantie | Devise et unité du montant explicites ; dates validées |
| Exploitation | numéro de parc, kilométrage, prochaine révision | Distinguer relevés de compteur historisés et seuils legacy |
| Médias | image, source, attribution, VIN décodé, customFields | Conserver la provenance ; valider les suggestions avant application |

### 3.3 Validations insuffisantes

La validation à l'enregistrement vérifie principalement la forme minimale de l'immatriculation, le VIN lorsque `chassisKey` l'impose, ainsi que le format ISO de la date d'acquisition et de fin de garantie.

À renforcer :

- règles de format distinctes pour immatriculations algériennes et étrangères ;
- normalisation VIN avant validation, sans rendre le VIN obligatoire pour les catégories qui n'en disposent pas ;
- plage raisonnable pour l'année-modèle, les places, portes, poids, cylindrée, dimensions et puissances ;
- rejet visible des valeurs numériques invalides au lieu de leur conversion silencieuse en `null` ;
- vérification du couple date/prix et de la devise, sans supposer l'unité historique de la quittance ;
- détection des doublons d'immatriculation et de numéro de parc dans l'entreprise ;
- validation des dépendances entre catégories et champs requis ;
- validation de cohérence de l'année et des dates ;
- messages d'erreur rattachés au champ fautif et à l'étape correspondante.

Ne pas convertir automatiquement les montants legacy en centimes, ni déduire une première date de circulation depuis `anneeUtil`, sans preuve de leur sémantique.

### 3.4 Automatisations déjà présentes

- catalogue de marques avec identifiants canoniques ;
- recherche d'images selon marque, modèle, année et couleur, avec comparaison de propositions ;
- décodage VIN et proposition de caractéristiques ;
- sélection d'un conducteur depuis le référentiel existant ;
- déduction de certaines informations administratives depuis les segments de l'immatriculation nationale.

Ces fonctions doivent être regroupées dans une expérience cohérente, avec une provenance visible et une validation humaine. Les valeurs proposées par OCR, VIN, recherche ou référentiel ne doivent pas écraser silencieusement des données déjà saisies.

## 4. Audit de la fiche détaillée

### 4.1 Structure actuelle

La fiche contient actuellement neuf rubriques :

1. Aperçu
2. Identification
3. Caractéristiques
4. Affectation
5. Localisation
6. Documents
7. Maintenance
8. Historique
9. Acquisition

La navigation est déjà accessible sur mobile et desktop. La navigation mobile est épinglée dans le scroll et le retour à la vue du parc est câblé dans le parent `VehicleManagement`.

La vue desktop comporte un panneau de liste et une fiche, avec un espacement entre les deux. Les corrections de navigation et de structure doivent être vérifiées sur les tailles réelles, mais ne nécessitent pas une réécriture préventive.

### 4.2 Défauts et limites métier

- Les valeurs de titulaire doivent rester distinctes du conducteur affecté.
- `modelYear` doit rester distinct de `anneeUtil`.
- `etat`, `etatactuel`, `service` et `decision` ne doivent pas être fusionnés avant validation du dictionnaire métier.
- `emplacement` reste une chaîne legacy, pas une place de parking normalisée.
- Une position GPS observée et un emplacement de stationnement attribué sont deux données différentes.
- Le kilométrage legacy ne doit pas être présenté comme une mesure récente si sa date et sa source sont absentes.
- `nextServiceMileage` ne constitue pas un programme d'entretien calculé.
- Les documents ont déjà les propriétés de pièce jointe `fileId`, `fileName`, `mimeType` et `fileSize`, et un bouton de téléchargement. Le téléchargement actuel utilise le bucket `images` : ce choix doit être vérifié avant toute généralisation des pièces jointes.
- Le statut « valide » ne doit pas être déduit lorsque la date d'expiration est inconnue.

### 4.3 GPS et carte

L'interface actuelle affiche honnêtement « aucune position reçue » et distingue l'emplacement texte legacy. Cette approche doit être conservée jusqu'à l'arrivée d'une vraie source de position.

La future carte devra afficher **la dernière position reçue**, jamais une position supposée actuelle :

- latitude / longitude WGS84 ;
- heure de mesure et heure de réception si différentes ;
- source (application mobile, appareil autorisé, saisie) ;
- précision en mètres lorsqu'elle est disponible ;
- ancienneté de la position et état de fraîcheur ;
- lien vers l'historique des points selon les droits.

Le choix visuel cible est Google Maps, avec une vue satellite de type Google Earth lorsque cela apporte une meilleure lecture. Le mode carte et le mode satellite doivent partager les mêmes coordonnées. L'interface devra distinguer la position observée du parking auquel le véhicule est affecté. Aucune collecte ni géolocalisation continue n'est activée par ce document ; la conformité et le consentement du suivi smartphone restent un préalable métier et réglementaire.

## 5. Maquette de référence — formulaire guidé véhicule

La première référence UX utilise un assistant en six étapes, avec une seule tâche principale visible à la fois.

### Étape 1 — Identification

- type/catégorie de véhicule ;
- immatriculation nationale segmentée ou étrangère ;
- pays ;
- VIN / numéro de châssis ;
- marque, modèle, finition ;
- année-modèle ;
- photo principale.

Automatisations : proposition de wilaya depuis la plaque algérienne, décodage VIN, catalogue de marques/modèles et recherche d'images. Chaque suggestion est prévisualisée puis acceptée par l'utilisateur.

### Étape 2 — Carte grise et titulaire

- référence du document ;
- date du document, sans l'assimiler à la première mise en circulation ;
- ancienne(s) immatriculation(s) ;
- titulaire : nom, prénom, profession ;
- adresse administrative ;
- wilaya, daïra et commune.

Automatisations : listes dépendantes wilaya → daïra → commune ; proposition OCR depuis une photo/scan de carte grise, avec écran de comparaison source / valeur extraite / valeur retenue. La détection OCR est une capacité future, pas une fonction annoncée comme disponible.

### Étape 3 — Caractéristiques

- genre réglementaire et carrosserie ;
- énergie, cylindrée, code moteur ;
- puissance fiscale en CV ;
- puissance moteur en ch et kW, séparément ;
- transmission, boîte et motricité ;
- portes, places, poids, charge utile et dimensions.

Automatisations : préremplissage à partir du VIN ou d'un modèle de référence, calculs dérivés uniquement lorsqu'ils sont mathématiquement sûrs, validation des unités et plages plausibles.

### Étape 4 — Affectation et usage

- conducteur affecté ;
- type d'affectation, lorsque la relation sera normalisée ;
- filiale, direction, département, appartenance ;
- profil d'usage ;
- statut opérationnel selon le dictionnaire de l'entreprise.

Automatisations : sélection du conducteur depuis le référentiel du tenant, affichage de ses informations de contact en lecture seule, suggestions d'organisation. Ne jamais copier le conducteur dans le titulaire.

### Étape 5 — Acquisition et exploitation

- type et date d'acquisition ;
- prix et devise ;
- fournisseur ;
- fin de garantie ;
- numéro interne de parc ;
- kilométrage initial avec date/source.

Automatisations : contrôles de cohérence de dates et prix, suggestion du prochain entretien seulement quand une règle de maintenance validée existe. L'ancien champ `nextServiceMileage` reste identifié comme donnée legacy.

### Étape 6 — Documents et vérification

- carte grise ;
- assurance ;
- contrôle technique ;
- justificatifs d'acquisition ;
- photo(s) ;
- notes complémentaires.

Automatisations : détection des documents manquants, lecture OCR à confirmer, extraction de dates d'échéance avec validation humaine, contrôle de doublons et résumé final.

### Composition de l'écran

**Desktop :**
- étape active dans un stepper latéral ou horizontal ;
- formulaire principal au centre, largeur maîtrisée ;
- panneau récapitulatif à droite avec aperçu du véhicule, taux de complétude et champs manquants ;
- bas de page fixe avec « Enregistrer en brouillon », « Précédent » et « Continuer ».

**Mobile :**
- barre de progression compacte ;
- une seule colonne ;
- pas de panneau latéral ;
- actions adaptées au tactile, sans masquer les champs ni le clavier ;
- conservation de l'étape et du scroll lors des erreurs.

**Comportements :**
- étape franchissable si ses champs obligatoires sont valides ;
- champs facultatifs clairement marqués ;
- brouillon récupérable ;
- résumé de validation avant enregistrement définitif ;
- indicateur de provenance pour les données importées ou suggérées ;
- modifications manuelles prioritaires sur les suggestions non confirmées.

## 6. Référence commune à tous les formulaires Parcoto

Ne pas créer un formulaire générique qui impose les mêmes champs à tous les modules. Construire un **socle de parcours** réutilisable et configurable.

### Contrat d'un formulaire

Chaque formulaire devrait définir :

- un titre et une description métier ;
- des étapes ordonnées ;
- des champs typés et des règles de validation ;
- les champs obligatoires/facultatifs ;
- les conditions d'affichage ;
- les dépendances entre champs ;
- les automatisations disponibles ;
- la stratégie de brouillon ;
- le résumé final et les actions autorisées selon les permissions.

### Composants communs envisagés

- `GuidedFormShell` : layout, progression, scroll, responsive, actions ;
- `GuidedFormStepHeader` : titre, description, état de l'étape ;
- `GuidedFormProgress` : progression et navigation ;
- `ParcotoFormField` : labels, aide, erreurs, état requis ;
- `FormSuggestionPanel` : données proposées, provenance, appliquer/refuser ;
- `FormSummaryPanel` : aperçu et champs manquants ;
- `FormDraftController` : sauvegarde et reprise ;
- `FormValidationSummary` : erreurs regroupées par étape.

Le formulaire véhicule sera le premier pilote. Après validation avec les utilisateurs, le même socle sera appliqué aux chauffeurs, clients, prestataires, fournisseurs, interventions et autres formulaires.

## 7. Feuille de route restante

| Ordre | Chantier | Livrable / critère de sortie |
|---:|---|---|
| 1 | Vérification responsive des corrections récentes | Parc mobile utilisable, rubriques mobiles accessibles, espacement desktop confirmé, retour à la vue parc testé |
| 2 | Localiser et corriger le zoom au double-tap dans la recherche | Identifier le vrai champ global concerné ; test sur navigateur mobile réel |
| 3 | Socle de formulaire guidé | Étapes, progression, validation, erreurs, brouillon, résumé, responsive |
| 4 | Migrer le formulaire véhicule | Six étapes, validations métier, automatisations avec confirmation, conservation de toutes les données existantes |
| 5 | Nettoyer la fiche détaillée | Alignement des libellés, unités, sources et états ; contrôler le bucket et les permissions des pièces jointes |
| 6 | Relations métier normalisées | Conducteurs/affectations, sites, parkings, relevés kilométriques, documents et maintenance après revue du schéma |
| 7 | GPS smartphone et carte véhicule | Dernier point fiable sur Google Maps / satellite Google Earth, fraîcheur et provenance explicites |
| 8 | Parc interactif | Carte multi-véhicules, sélection synchronisée avec la liste, filtres, regroupement par site et limites tenant |
| 9 | Validation générale | Tests desktop, web mobile, Android, droits, synchronisation et données legacy |

## 8. Critères d'acceptation non négociables

- Aucun champ n'est prérempli avec une donnée métier fictive.
- Un conducteur ne remplace jamais le titulaire de la carte grise.
- Année-modèle et année d'usage restent distinctes.
- Les unités CV, ch, kW, cm³, kg, mm et DA sont explicites.
- Une suggestion automatisée est attribuée à sa source et confirmée avant remplacement d'une donnée saisie.
- Un utilisateur peut enregistrer un brouillon incomplet et le reprendre.
- Une erreur est affichée sur le champ et l'étape concernés.
- Le formulaire reste opérable sur mobile avec le clavier ouvert.
- Les permissions et le `companyId` sont contrôlés côté serveur ; l'UI ne constitue jamais la seule barrière tenant.
- La carte GPS n'affiche aucun point fictif et n'est pas activée sans source autorisée.

---

**Limite de validation de cet audit :** les fichiers et commits ont été inspectés via GitHub. L'environnement de cette session ne dispose pas d'un checkout Flutter exécutable ; `flutter analyze`, les tests widget et les essais visuels Windows/Web/Android restent à exécuter avant de déclarer les corrections validées en exécution.
