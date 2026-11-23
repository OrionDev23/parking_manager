# Parcoto — Spécification UX/UI Phase 2 : fiche véhicule

**Statut :** spécification de réalisation — à appliquer sur `refactor/foundation-v1`  
**Référence technique :** modèle de domaine véhicule v1 et contrat Appwrite/SQLite v1  
**Périmètre :** consultation détaillée d'un véhicule, navigation entre rubriques, adaptation desktop/tablette/mobile  
**Hors périmètre immédiat :** refonte complète du formulaire de création/édition, création des nouvelles tables Appwrite, activation du GPS.

---

## 1. Constat sur l'interface existante

L'entrée principale actuelle est `VehicleManagement` dans `lib/screens/vehicle/manager/vehicle_management.dart`. Elle ouvre une `VehicleDetailsPage` lorsqu'on sélectionne une carte véhicule. La page de détail est donc déjà séparée de `VehicleForm`, ce qui constitue le bon point de départ.

La page actuelle `lib/screens/vehicle/manager/vehicle_details_page.dart` présente cependant plusieurs limites :

- toutes les rubriques sont empilées dans un seul long défilement ;
- plusieurs informations sont répétées entre « Vue générale » et les sections détaillées ;
- il n'existe pas de navigation directe vers une rubrique précise ;
- les blocs GPS et parking sont des placeholders, et non des données connectées ;
- les données documentaires visibles sont actuellement des métadonnées ; le modèle utilisé dans cette page ne référence pas encore de fichier joint ;
- la page charge l'historique, les documents et la maintenance sans séparer clairement leur état de chargement et leur état vide ;
- la synthèse affiche le nom/prénom du titulaire comme « Conducteur », alors que `VehicleMapper` mappe ces deux champs vers `ownerFirstName` et `ownerLastName`. Le conducteur est actuellement représenté séparément par `matriculeConducteur` / `driverRegistration` ;
- le champ `etat` et le code `etatactuel` coexistent. Ils ne doivent pas être présentés comme s'ils représentaient nécessairement la même donnée ;
- l'année `modelYear` et `anneeUtil` sont différentes dans le modèle et ne doivent pas être fusionnées par un fallback d'affichage ;
- les valeurs `emplacement` / `location` sont du texte legacy et ne prouvent pas une affectation à une place de parking.

La Phase 2 doit corriger ces défauts de structure et de sémantique avant d'ajouter des effets visuels.

## 2. Objectifs de conception

1. Donner une lecture immédiate de l'identité et de l'état connu du véhicule.
2. Permettre d'accéder à chaque rubrique sans parcourir toute la fiche.
3. Éviter les doublons et séparer les données administratives, techniques et opérationnelles.
4. Distinguer visuellement les données confirmées, les anciennes valeurs legacy et les informations non disponibles.
5. Conserver une présentation cohérente entre Windows, Web, tablette et mobile.
6. Ne pas prétendre qu'une fonctionnalité existe lorsque sa source de données n'est pas encore implémentée.
7. Préserver les règles d'accès et les frontières `companyId` déjà imposées par les repositories et Appwrite.

## 3. Architecture cible de la page

### 3.1 En-tête permanent

L'en-tête contient :

- action Retour au parc ;
- photo principale du véhicule, avec un placeholder neutre si aucune image n'est disponible ;
- immatriculation mise en évidence ;
- marque résolue depuis le catalogue partagé et modèle/type ;
- finition et année modèle lorsqu'elles existent ;
- badge d'état uniquement si son code peut être interprété par le mapping existant du contexte utilisateur ;
- bouton principal « Modifier » ;
- menu d'actions secondaires selon les permissions déjà appliquées par l'application.

La marque doit être affichée avec `VehicleMakeService.nameFor(VehicleMakeService.canonicalId(...))`, jamais avec un index de liste ou un ID brut si le nom peut être résolu.

L'image reste une illustration du véhicule, pas une preuve d'identification. Si une source/licence/attribution est fournie par le service d'images, elle doit rester accessible dans le détail de l'image. Les états chargement, erreur et absence d'image doivent avoir un rendu dédié.

### 3.2 Navigation par rubriques

La fiche est découpée en huit rubriques :

| Ordre | Rubrique | Contenu principal |
|---:|---|---|
| 1 | **Aperçu** | Synthèse, état actuel connu, informations essentielles, alertes réellement calculables et activité récente |
| 2 | **Identification** | Immatriculation, VIN, carte grise, titulaire, anciennes immatriculations et adresse administrative |
| 3 | **Caractéristiques** | Marque/modèle/finition, année modèle, couleur, carrosserie, genre, motorisation, transmission, dimensions et capacités |
| 4 | **Affectation** | Conducteur, filiale, direction, département, appartenance, type d'usage et rattachement connu |
| 5 | **Localisation** | Dernière position observée si disponible, source, date, précision ; emplacement/parking attendu dans un bloc distinct |
| 6 | **Documents** | Liste des documents, échéances et état de validité |
| 7 | **Maintenance** | Ordres de réparation, fiches de réception, relevés de kilométrage et échéances disponibles |
| 8 | **Historique** | Changements d'état, événements disponibles, historique d'immatriculation et données d'acquisition |

La navigation est visible sous l'en-tête et reste facilement accessible pendant la consultation. Sur grand écran, les rubriques sont présentées sous forme d'onglets horizontaux. Sur petit écran, elles deviennent une barre d'onglets horizontalement défilante, sans réduire la largeur utile du contenu. L'onglet actif est évident et son libellé reste lisible.

Le passage d'une rubrique à une autre ne doit pas réinitialiser inutilement la fiche ou relancer toutes les requêtes. Les sections distantes chargent leurs propres données une fois, puis gèrent séparément actualisation, erreur et absence de résultat.

### 3.3 Aperçu

L'Aperçu n'est pas une copie miniature de toutes les autres rubriques. Il ne contient que les informations nécessaires à une décision rapide :

- identité courte : immatriculation, marque, modèle, année modèle, VIN ;
- état actuel selon le code réellement disponible ;
- conducteur affecté uniquement si une relation fiable peut être résolue ; sinon afficher le matricule conducteur sans inventer de nom ;
- rattachement connu : filiale/direction/site uniquement avec les libellés et valeurs réellement disponibles ;
- kilométrage enregistré avec mention de son caractère legacy lorsque date/source ne sont pas connues ;
- synthèse des documents expirés ou proches de l'expiration, calculée à partir des dates disponibles ;
- intervention ou événement récent réellement enregistré ;
- dernier point GPS uniquement lorsqu'une position réelle existe.

Chaque bloc renvoie vers sa rubrique détaillée. Les informations vides ne génèrent pas de cartes sans contenu.

### 3.4 Identification

Sous-groupes :

**Immatriculation**
- immatriculation actuelle ;
- pays et indicateur d'immatriculation étrangère ;
- anciennes immatriculations ;
- VIN / numéro de série.

**Carte grise**
- date du document ;
- numéro/référence ;
- montant de quittance, uniquement avec son unité historique exacte ;
- wilaya, daïra, commune et adresse administrative.

**Titulaire**
- nom, prénom et profession du titulaire ;
- ne pas afficher ces champs comme identité du conducteur.

L'ancienne propriété `date` est actuellement libellée « Date carte grise » dans l'interface, mais la matrice legacy signale que sa sémantique exacte doit être confirmée. Conserver ce libellé provisoire tant que l'interprétation n'est pas validée ; ne pas la convertir automatiquement en première mise en circulation.

### 3.5 Caractéristiques

Sous-groupes :

**Identité technique**
- marque, modèle/type, finition, genre/catégorie, carrosserie ;
- année modèle ;
- année `anneeUtil` présentée séparément sous un libellé legacy tant que sa signification métier n'est pas confirmée ;
- couleur.

**Motorisation**
- énergie ;
- cylindrée ;
- puissance fiscale (CV) ;
- puissance moteur en ch et kW, dans deux champs distincts ;
- code moteur.

**Transmission**
- transmission ;
- boîte ;
- roues motrices.

**Dimensions et capacité**
- portes, places assises ;
- poids total, charge utile ;
- longueur, largeur, hauteur avec unités.

Ne jamais présenter la puissance fiscale comme une puissance moteur. Ne pas fusionner les champs qui ont des unités ou des significations différentes.

### 3.6 Affectation

Sous-groupes :

**Conducteur**
- conducteur lié par une relation de même entreprise lorsqu'une résolution fiable est disponible ;
- à défaut, matricule conducteur legacy seul ;
- date de début/fin et type d'affectation lorsque la future ressource `vehicle_assignments` sera branchée.

**Organisation**
- appartenance, filiale, direction, département ;
- type d'usage (« service ») seulement comme indicateur distinct ;
- conserver les valeurs legacy telles quelles tant que leur dictionnaire n'est pas validé.

**État opérationnel**
- code `etatactuel` rendu par le dictionnaire existant du contexte utilisateur ;
- champ `etat` présenté séparément ou masqué tant que son sens n'est pas confirmé ;
- ne pas créer un nouveau mapping de statuts pendant une tâche purement UI.

Les valeurs historiques de cette rubrique ne doivent pas être renommées en « site », « propriétaire du véhicule » ou « affectation active » sans preuve correspondante.

### 3.7 Localisation

Deux blocs visuellement et sémantiquement distincts :

**Position observée**
- dernière latitude/longitude ;
- date de mesure et date de réception si connues ;
- précision ;
- source (smartphone, GPS dédié, OBD, saisie manuelle, etc.) ;
- fraîcheur calculée et état en ligne/hors ligne uniquement si ces données sont réellement fournies.

**Emplacement attendu**
- site, parking, zone et place lorsque les relations normalisées existent ;
- texte legacy `emplacement` affiché sous un libellé « Emplacement historique » tant qu'il ne référence pas une place connue.

À ce stade, aucune position réelle n'est reliée à la fiche. La page doit afficher un état vide honnête, pas une carte centrée sur une coordonnée fictive ni un faux indicateur « temps réel ». La présentation peut réserver l'espace à une future carte, mais ne doit pas lancer de collecte GPS. La qualification réglementaire du suivi smartphone en Algérie reste un gate indépendant de l'interface.

### 3.8 Documents

- liste triable par expiration ;
- nom/type du document ;
- date d'émission si présente ;
- date d'expiration ;
- état : expiré, expire bientôt, valide, échéance inconnue ;
- actions d'ouverture/téléchargement uniquement lorsqu'un vrai fichier/bucket et une permission sont disponibles.

Le modèle consulté expose actuellement surtout des métadonnées de document. Ne pas dessiner un bouton « Ouvrir » ou « Télécharger » inactif et ne pas présenter une métadonnée comme un fichier joint. Les dates d'expiration absentes doivent rester « Échéance inconnue », pas « Valide ».

### 3.9 Maintenance

- ordres de réparation ;
- fiches de réception ;
- prestataire, dates d'entrée/sortie, statut, observations et coût lorsqu'ils existent ;
- kilométrage enregistré sur l'intervention ;
- révision à venir uniquement lorsqu'une règle/échéance fiable existe.

Les données issues de `RepairProvider` et des fiches de réception peuvent être affichées dans cette phase. `nextServiceMileage` reste une valeur legacy et ne doit pas être présentée comme un plan d'entretien calculé.

### 3.10 Historique et acquisition

- événements d'état datés ;
- anciennes immatriculations ;
- date d'acquisition, type, prix, fournisseur et garantie ;
- date de création/modification de la fiche en métadonnées secondaires.

Ne pas créer artificiellement une chronologie si les dates manquent. Les événements sont ordonnés avec leur source et leur date réelle. Les montants restent associés à la devise/unité réellement stockée.

## 4. Règles d'affichage et de vérité des données

| Situation | Comportement attendu |
|---|---|
| Champ optionnel vide | Masquer le champ dans les groupes détaillés ; ne pas afficher une longue série de « Non renseigné » |
| Information clé vide | Afficher un état court « Non renseigné » dans l'Aperçu si elle est importante pour l'utilisateur |
| Valeur legacy dont le sens n'est pas confirmé | La garder séparée et, au besoin, l'indiquer comme valeur historique |
| Conducteur non résolu | Afficher le matricule source ; ne jamais déduire le nom à partir du titulaire |
| Marque résolue | Afficher le nom canonique du catalogue |
| Kilométrage sans date/source | Le qualifier comme valeur enregistrée legacy, pas comme mesure récente |
| Pas de position GPS | Afficher « Aucune position reçue » avec un état vide explicite |
| Document sans fichier | Afficher ses métadonnées ; aucune action de fichier |
| Erreur de chargement d'une rubrique | Afficher une erreur localisée avec action Réessayer, sans bloquer les autres rubriques |

Les unités doivent être explicites : km, cm³, ch, kW, CV, kg, mm et DA. La date de mesure ne doit jamais être confondue avec la date de réception ou la date de mise à jour de la fiche.

## 5. Principes responsive

### Desktop (≥ 1280 px)
- contenu centré avec largeur maximale cohérente avec le reste du design system ;
- en-tête horizontal avec image, identité et actions ;
- navigation horizontale clairement séparée ;
- groupes de champs en deux ou trois colonnes selon la largeur disponible ;
- pas de colonne latérale redondante qui répète l'Aperçu dans chaque rubrique.

### Tablette (640–1279 px)
- en-tête compact ;
- onglets défilants si nécessaire ;
- groupes de champs sur deux colonnes, puis une seule si l'espace est insuffisant ;
- actions principales visibles, secondaires regroupées.

### Mobile (< 640 px)
- en-tête empilé sans débordement ;
- immatriculation et bouton Modifier immédiatement visibles ;
- navigation par onglets horizontaux ;
- contenu sur une seule colonne ;
- lignes de données lisibles, avec libellé au-dessus de la valeur ;
- aucune grille forcée à deux colonnes ;
- aucune action essentielle uniquement accessible au survol ;
- boutons adaptés au tactile et pas de bandeau fixe qui masque le clavier ou la fin du contenu.

Utiliser les breakpoints de `ParcotoTokens` au lieu de réintroduire des seuils locaux contradictoires.

## 6. Navigation et comportement

- La fiche conserve le contexte du parc et l'action Retour.
- Modifier ouvre le formulaire existant, sans mélanger consultation et édition inline.
- Après sauvegarde, revenir sur la fiche rafraîchie du véhicule, sans renvoyer systématiquement à la liste.
- Une actualisation d'une rubrique ne doit pas relancer toutes les autres requêtes.
- Un état vide, un chargement, une erreur et un état de données partielles ont chacun un rendu dédié.
- Les actions destructives restent soumises aux permissions et à une confirmation explicite.
- Aucun identifiant interne `companyId`, ID de ligne ou index de catalogue n'est exposé à l'utilisateur.

## 7. Périmètre technique de la Phase 2

### Inclus
- refonte de `VehicleDetailsPage` ;
- navigation par rubriques ;
- nouveaux composants de présentation réutilisables pour les champs, groupes, badges d'état et états vides ;
- correction de la confusion titulaire/conducteur ;
- résolution correcte du nom de marque ;
- affichage honnête des champs legacy et des fonctionnalités non connectées ;
- comportement responsive vérifié sur Web mobile, Android et desktop ;
- tests de rendu, navigation et états de chargement/absence de données.

### Exclu pour l'instant
- refonte complète de `VehicleForm` et du parcours de création ;
- modification des statuts métiers et des dictionnaires legacy ;
- création des tables `sites`, `vehicle_assignments`, GPS, parking, documents normalisés ou événements dans Appwrite ;
- activation du suivi GPS ;
- migration/backfill de données ;
- modification des ACL ou des permissions Appwrite.

## 8. Découpage d'implémentation

| Sous-phase | Travail | Critère de sortie |
|---|---|---|
| 2.1 | Structure de page, en-tête, navigation et Aperçu | La fiche est navigable sans long scroll ; l'Aperçu ne duplique pas les autres rubriques |
| 2.2 | Identification et Caractéristiques | Tous les champs actuels sont rangés dans des groupes cohérents avec leurs unités et sémantiques |
| 2.3 | Affectation et état opérationnel | Titulaire et conducteur séparés ; aucune relation ou organisation inventée |
| 2.4 | Documents, Maintenance et Historique | Sources actuelles réutilisées ; erreurs, états vides et échéances correctement affichés |
| 2.5 | Localisation et préparation GPS | Position réelle et emplacement prévu séparés ; aucune fausse donnée GPS |
| 2.6 | Responsive, accessibilité et tests | Vérification mobile/tablette/desktop ; aucun overflow, aucune action inaccessible au tactile |

Après chaque sous-phase : exécuter les tests ciblés, `flutter analyze`, puis le CI complet avant de poursuivre.

## 9. Critères d'acceptation globaux

- Aucune répétition de la même information dans plusieurs sections sans raison fonctionnelle.
- Aucun titulaire de carte grise présenté comme conducteur.
- Aucune confusion entre `modelYear` et `anneeUtil`, `etat` et `etatactuel`, puissance fiscale et puissance moteur.
- Aucune position ou place de parking inventée.
- Aucune action de document sans fichier réel et autorisé.
- Les champs optionnels absents n'encombrent pas l'interface.
- Les huit rubriques sont accessibles sur toutes les tailles d'écran.
- Les opérations et lectures restent bornées au véhicule et à l'entreprise active.
- Le formulaire de modification continue de fonctionner et n'est pas réécrit implicitement dans le chantier de consultation.

---

**Décision de réalisation :** commencer par la sous-phase 2.1 sur la branche `refactor/foundation-v1`, en réutilisant `VehicleManagement` et en remplaçant progressivement la présentation de `VehicleDetailsPage`. Ne pas modifier Appwrite ni le modèle métier dans cette première sous-phase.
