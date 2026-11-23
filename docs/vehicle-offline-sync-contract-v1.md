# Parcoto — Contrat SQLite et synchronisation offline-first v1

**Statut :** spécification technique cible  
**Référence :** `docs/vehicle-domain-model-v1.md` et `docs/vehicle-appwrite-schema-v1.md`  
**Plateformes :** SQLite natif (Windows / Android / iOS) ; Web online-only dans l'architecture auditée le 22/11/2026.

> Ce contrat décrit le comportement attendu avant implémentation. Les migrations SQLite de cette spécification ne sont pas appliquées automatiquement par ce document.

---

## 1. Constats sur le code actuel

### 1.1 SQLite actuel

La base locale se trouve dans `parcoto.db` et son système de migration est actuellement à la version 11.

Tables actuelles :
- `vehicles` : ID, company_id, site_id, registration, brand, model, color, status, created_at, updated_at, payload.
- `drivers` : table de cache conducteur.
- `sync_operations` : outbox générique.
- `sync_engine_leases` : lease de moteur par entreprise.
- `legacy_module_cache` : cache des anciens modules.
- `sync_conflict_resolutions`, `sync_cursors`, `sync_reconciliation`, `sync_remote_snapshot`, `startup_migrations`.

Migrations versionnées 1 à 11 déjà présentes. Toute nouvelle migration doit commencer à **version 12**. Ne jamais modifier rétroactivement une migration déjà exécutée sur les postes utilisateurs.

### 1.2 Défaut d'atomicité et périmètre corrigé

L'audit initial a trouvé le même défaut dans trois chemins natifs :
- `VehicleRepositoryImpl` : le repository écrivait l'outbox puis le cache véhicule dans deux opérations SQLite distinctes.
- `DriverRepositoryImpl` : même séquence pour les chauffeurs.
- `LegacyStockSyncService` : même séquence entre `sync_operations` et `legacy_module_cache`.

**Correctif implémenté sur `refactor/foundation-v1` :**

- Contrat `AtomicSyncQueue.enqueueWithLocalMutation()`.
- Implémentation native : un seul `BEGIN IMMEDIATE`, écriture/coalescence de l'outbox, callback local synchrone sur la même connexion SQLite, puis `COMMIT`.
- En cas d'erreur, rollback de l'outbox et du cache ensemble.
- Repository véhicule : create/update/delete.
- Repository chauffeur : create/update/delete.
- Catalogue Stock legacy : save/delete, avec conservation de son payload et de sa partition `companyId`.
- Sources locales véhicule et chauffeur : méthodes de mutation transactionnelle, avec garde tenant sur la source chauffeur et véhicule.
- Runtime : véhicule, chauffeur et stock utilisent la même instance `LocalDatabase` et le même moteur/file d'outbox.
- Le handler de l'entité `storage`, déjà déclarée dans le registre Stock, est maintenant aussi enregistré dans le moteur de sync.

L'implémentation Web reste online-only : le chemin atomique SQLite n'est pas utilisé côté Web et l'appel de cette API native y échoue explicitement.

**Tests ajoutés et exécutés par CI :** migration v11→v12, schéma v12, commit/rollback, coalescence create/update/delete, backoff retry, isolation tenant des chauffeurs et atomicité du cache Stock. Le run final `45074377970` est vert sur le commit `aee741a7` : tests Flutter, analyse statique, build Web et syntaxe de la Function Appwrite.

### 1.3 Différence Web / natif

Le dépôt contient un repository natif local-first avec SQLite et outbox. Le repository Web écrit directement à distance via Appwrite et ne dispose pas de cette file offline-first.

Donc :
- Windows/Android/iOS : local-first et synchronisation différée.
- Web : online-only dans le périmètre présent ; l'interface doit afficher l'état hors ligne et désactiver les mutations distantes plutôt que prétendre les conserver localement.
- Un futur offline Web demandera une conception IndexedDB séparée ; ne pas assimiler SQLite natif à une capacité Web.

---

## 2. Modèle de stockage local

### 2.1 Règle de partition

Toutes les lignes métier tenant-scoped contiennent `company_id`. La clé primaire doit protéger contre les collisions entre tenants. Recommandation : clé composite `PRIMARY KEY(company_id, id)` ou identifiant global stable avec `company_id` obligatoire et contrôle systématique sur chaque requête.

Toutes les requêtes locales doivent inclure `company_id = activeCompanyId`. Aucun chargement global de cache opérationnel sans partition explicite.

### 2.2 Tables de cache locales proposées

Les données détaillées peuvent rester dans un `payload` JSON versionné, mais les champs qui pilotent les relations et les recherches doivent être indexés en colonnes typed.

| Table SQLite | Colonnes typed minimales | Payload |
|---|---|---|
| vehicles | id, company_id, site_id, registration_normalized, vin_normalized, make_id, model_id, lifecycle_status, updated_at, server_revision | JSON canonique |
| sites | id, company_id, code, status, updated_at, server_revision | JSON canonique |
| drivers | structure actuelle + revision | JSON canonique |
| vehicle_assignments | id, company_id, vehicle_id, driver_id, status, start_at, end_at, updated_at, server_revision | JSON |
| tracking_devices | id, company_id, driver_id, dedicated_vehicle_id, tracking_status, last_seen_at | JSON |
| tracking_sessions | id, company_id, vehicle_id, driver_id, device_id, status, started_at, ended_at | JSON |
| vehicle_location_fixes | id, company_id, vehicle_id, session_id, observed_at, received_at, latitude, longitude, source_type | JSON/minimal metadata |
| parking_lots | id, company_id, site_id, code, status | JSON |
| parking_zones | id, company_id, parking_lot_id, code, status | JSON |
| parking_spaces | id, company_id, parking_zone_id, code, status, space_type | JSON |
| vehicle_parking_assignments | id, company_id, vehicle_id, parking_space_id, status, start_at, end_at | JSON |
| vehicle_meter_readings | id, company_id, vehicle_id, reading_type, value, measured_at, validation_status | JSON |
| vehicle_documents | id, company_id, vehicle_id, document_type, expires_at, status, storage_file_id | JSON |
| vehicle_media | id, company_id, vehicle_id, media_type, storage_file_id, sort_order | JSON |
| vehicle_maintenance_plans | id, company_id, vehicle_id, status, next_due_at, next_due_km | JSON |
| maintenance_work_orders | id, company_id, vehicle_id, status, scheduled_at, completed_at | JSON |
| vehicle_expenses | id, company_id, vehicle_id, expense_type, occurred_at, amount_minor, currency | JSON |
| vehicle_events | id, company_id, vehicle_id, event_type, occurred_at, recorded_at | JSON |

Les tables enfants possèdent des indexes sur `(company_id, parent_id, timestamp/status)`. Les fixes GPS nécessitent une stratégie spécifique de volume et de rétention ; leur cache SQLite n'est pas un historique infini.

### 2.3 DDL cible de l'outbox

Conserver le nom existant `sync_operations` et faire évoluer sa structure par migration. Le DDL logique cible :

```sql
CREATE TABLE sync_operations (
  id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  entity TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  operation TEXT NOT NULL CHECK (operation IN ('create','update','delete')),
  payload TEXT NOT NULL,
  payload_version INTEGER NOT NULL DEFAULT 1,
  idempotency_key TEXT NOT NULL,
  depends_on_operation_id TEXT,
  sequence_no INTEGER NOT NULL,
  base_revision INTEGER,
  created_at TEXT NOT NULL,
  status TEXT NOT NULL CHECK (
    status IN ('pending','processing','failed','conflict','completed')
  ),
  attempts INTEGER NOT NULL DEFAULT 0,
  next_attempt_at TEXT,
  last_error_code TEXT,
  last_error_message TEXT,
  conflict_reason TEXT,
  conflicted_at TEXT,
  completed_at TEXT
);

CREATE UNIQUE INDEX ux_sync_operation_idempotency
  ON sync_operations(company_id, idempotency_key);

CREATE INDEX ix_sync_queue_due
  ON sync_operations(company_id, status, next_attempt_at, created_at);

CREATE INDEX ix_sync_entity_order
  ON sync_operations(company_id, entity, entity_id, sequence_no);

CREATE INDEX ix_sync_operation_dependency
  ON sync_operations(depends_on_operation_id);
```

Précisions :
- La table actuelle possède déjà plusieurs de ces champs. La migration 12 doit ajouter uniquement les colonnes/index absents, sans recréer la table.
- Avant d'ajouter l'index unique d'idempotence, auditer les doublons. Initialiser idempotency_key depuis id pour les anciennes opérations.
- Les anciens IDs operationId doivent rester inchangés ; ils sont référencés dans `sync_conflict_resolutions`.
- `base_revision` est null pour create et porte la version serveur vue lors d'un update/delete.
- `depends_on_operation_id` empêche un enfant d'être envoyé avant l'ack du parent.
- `last_error_message` doit être nettoyé des données personnelles et limité en taille.
- Les opérations completed sont conservées pour une période de diagnostic définie puis purgées selon une règle documentée ; les conflits ne sont jamais purgés automatiquement.

### 2.4 Table de réception / idempotence distante

Prévoir une table Appwrite server-only `sync_operation_receipts` pour les mutations qui ne se dédupliquent pas par l'ID de la ressource :

| Clé | Type | Requis |
|---|---|---:|
| companyId | string(36) | Oui |
| operationId | string(36) | Oui |
| entity | string(40) | Oui |
| entityId | string(36) | Oui |
| operationType | string(12) | Oui |
| resultCode | string(24) | Oui |
| appliedAt | datetime | Oui |
| resultRevision | integer | Non |

Index unique `(companyId, operationId)`, index `(companyId, entity, entityId)`.

La création et l'ack receipt sont atomiques avec la mutation métier dans une transaction Appwrite lorsque l'opération produit plusieurs lignes ou événements. Les lignes véhicule/driver existantes utilisent déjà des IDs stables et une logique idempotente ; le receipt complète ce modèle pour les relations et mutations append-only.

---

## 3. Contrat d'écriture local

### 3.1 Transaction unique

Le repository ne doit plus appeler successivement `queue.enqueue()` puis `local.upsert()` avec deux transactions séparées.

Introduire une abstraction de mutation, par exemple `LocalMutationCoordinator`, qui utilise **la même instance SQLite** :

```text
BEGIN IMMEDIATE
  validate active company
  read previous local entity
  apply local upsert/delete
  coalesce/insert outbox operation
  assign sequence_no and dependency
COMMIT
```

Si une étape échoue : `ROLLBACK` et l'entité locale/outbox restent dans leur état précédent.

Pour un create, écrire la ligne locale et outbox dans le même commit.  
Pour un update, enregistrer la nouvelle version locale et son mutation.  
Pour un delete, enregistrer un tombstone dans l'outbox et supprimer/masquer la ligne locale dans le même commit.

La coalescence actuelle dans `SqliteSyncQueue.enqueue()` doit être extraite en méthode `enqueueInTransaction()` ou remplacée par un service de repository transactionnel. Elle ne doit pas démarrer une seconde transaction imbriquée.

### 3.2 Coalescence des opérations

Règles recommandées :

| Séquence locale non encore envoyée | Résultat |
|---|---|
| create → update | garder create, remplacer payload par le dernier état |
| create → delete | annuler l'opération et la ligne locale (si aucun enfant dépendant n'existe) |
| update → update | garder la première opération et le dernier payload/changeSet |
| update → delete | envoyer delete, pas les updates intermédiaires |
| delete → create même ID | conflit/restore explicite, pas de fusion implicite |
| opération processing | ne pas coalescer ; nouvelle opération séquencée |
| opération failed/conflict | ne pas écraser ; résolution contrôlée |

Attention : si create → delete possède des opérations enfants (assignment/media/document), celles-ci doivent être annulées ou traitées avant l'annulation du parent.

### 3.3 Dépendances parent-enfant

Ordre obligatoire :
- site → parking lot → zone → space ;
- vehicle → assignment / meter reading / document / media / maintenance plan ;
- driver → vehicle assignment ;
- tracking device → tracking session → location fixes ;
- parking space + vehicle → parking assignment.

Une opération enfant référence son parent par ID et son depends_on_operation_id. Le moteur ne traite l'enfant que lorsque la dépendance est completed. Si le parent est en conflit, l'enfant reste bloqué avec la raison `dependency_blocked`.

---

## 4. Contrat de synchronisation

### 4.1 Cycle d'une opération

**État implémenté pour le retry :**
- Les erreurs transitoires sont marquées `failed`, avec `last_error_code`, un message générique non sensible limité à 500 caractères et `next_attempt_at`.
- Le délai est exponentiel à partir de 5 secondes, avec jitter déterministe par opération, plafonné à 3600 secondes.
- La requête `pending()` n'inclut une opération `failed` que lorsque `next_attempt_at` est absent ou échu.
- Une erreur permanente devient `conflict` et efface son échéance de retry ; elle reste consultable mais n'est pas rejouée automatiquement.
- Un succès renseigne `completed_at` et efface les champs de retry/erreur.
- Web conserve uniquement un échéancier mémoire : cela ne crée pas une outbox Web persistante et ne change pas le mode online-only.


```text
Local mutation
  -> pending
  -> claim/processing (après lease)
  -> request serveur idempotente
  -> response vérifiée (status + code + body)
  -> completed + server revision
```

Erreurs :
- Réseau / timeout / 5xx / 429 : failed + exponential backoff avec jitter.
- 401/403 : failed temporaire si session/contexte peut être renouvelé ; sinon message utilisateur et arrêt sécurisé.
- 400 validation métier : conflict/permanent avec un code machine précis et indication du champ.
- 404 parent absent : conflict uniquement si la relation ne peut pas être résolue/recréée.
- 409 revision mismatch / doublon : conflict et procédure de résolution ; ne pas réessayer en boucle.
- Unknown action / deployment mismatch : erreur de protocole/configuration. Ne pas marquer la donnée métier comme définitivement invalide ; générer un code `api_contract_mismatch`, arrêter les retries automatiques globaux et alerter le diagnostic.

Ne jamais analyser uniquement une chaîne de message. Utiliser un champ serveur stable `code`, `retryable` et `details`.

### 4.2 Idempotence

- Chaque opération possède un operationId/idempotencyKey généré une seule fois sur l'appareil.
- Un retry réutilise exactement le même operationId et entityId.
- Create vehicle utilise l'ID métier comme rowId ; un rowId déjà présent dans le même tenant retourne alreadyExists sans incrémenter le quota.
- Create child/event vérifie le receipt ; ne pas générer un nouvel ID à chaque retry.
- Une opération déjà appliquée mais dont l'ACK a été perdu doit converger vers success au prochain retry.
- Un rowId présent dans une autre entreprise est un incident de sécurité, pas un doublon récupérable.

### 4.3 Révisions et mise à jour offline

Toutes les entités modifiables exposent une propriété `revision` entière, initialisée à 1 et incrémentée côté serveur.

À chaque pull, enregistrer la revision et `$updatedAt`. Chaque mutation update transmet `baseRevision` et un `changeSet` des champs modifiés.

Si baseRevision = currentRevision : appliquer et incrémenter.

Si elles diffèrent :
1. comparer les champs locaux modifiés avec les champs modifiés depuis la base ;
2. si les ensembles sont disjoints et que le merge de domaine est sûr, proposer/appliquer un merge contrôlé ;
3. si le même champ ou un invariant métier est touché, produire un conflit explicite ;
4. ne jamais écraser silencieusement un état serveur plus récent.

Pour la première version, privilégier un conflit explicite plutôt qu'un merge automatique générique.

### 4.4 Lease et multi-instance

- Un seul moteur actif par companyId et base locale, via `sync_engine_leases`.
- Une lease est renouvelée pendant une requête longue.
- Si la lease est perdue, ne pas ack l'opération ; le prochain propriétaire la récupère.
- `recoverInterrupted` ne réinitialise que les processing de l'entreprise après acquisition de sa lease.
- Une session d'entreprise ne doit jamais drainer l'outbox d'une autre entreprise.
- Au changement de companyId : arrêter l'ancien moteur, attendre/abandonner proprement la lease, reconstruire les services, puis démarrer le nouveau contexte.

### 4.5 Pull et curseurs

Pour chaque entité :
- utiliser `$updatedAt`/cursor serveur et un tie-breaker stable `$id` ;
- conserver une petite fenêtre de recouvrement pour éviter de manquer les écritures ayant le même timestamp ;
- upsert local uniquement si aucune mutation locale non résolue ne protège la ressource ;
- ne pas supprimer une ligne locale simplement parce qu'elle manque dans une page partielle ;
- réconciliation complète seulement pour les tables de taille maîtrisée, avec deux scans stables comme sécurité ;
- ne pas faire de scan intégral répété sur vehicle_location_fixes.

Les positions sont reçues en batch, dédupliquées par fixId et triées par observedAt. Le curseur des fixes est séparé de celui des véhicules.

### 4.6 Conflits

Chaque conflit conserve :
- operationId, companyId, entity, entityId ;
- reasonCode stable ;
- message résumé non sensible ;
- date, tentatives, payloadVersion et baseRevision ;
- résolution choisie, acteur et date.

Actions autorisées :
- retry_after_fix ;
- merge_remote ;
- keep_local (avec vérification de revision et confirmation) ;
- discard_local (confirmation et audit) ;
- create_new_record (uniquement si le métier autorise un nouvel ID).

Un retry automatique ne concerne que les erreurs identifiées comme transitoires. Une opération en conflit reste visible, ne bloque pas toute l'entreprise, mais bloque les mutations dépendantes du même agrégat.

---

## 5. Spécificités GPS offline-first

### 5.1 Collecte et tampon local

- Le smartphone génère un fixId UUID stable à chaque échantillon.
- `observedAt` vient de l'appareil ; `receivedAt` est défini côté serveur.
- Conserver latitude/longitude, accuracy et source ; ne pas transformer une position approximative en position exacte.
- Le suivi est limité à une tracking_session explicitement démarrée et autorisée.
- Quand le réseau manque, tampon local borné par durée et volume configurés.
- À la reconnexion, envoyer des lots avec idempotency keys.
- Le buffer local n'efface des positions que quand le serveur confirme le lot.
- Si stockage plein, appliquer une politique explicite (réduire fréquence, conserver les points critiques, signaler la perte) ; ne pas supprimer silencieusement.

### 5.2 Volumétrie

Une position chaque seconde produit environ 86 400 fixes/jour/véhicule. Ce n'est pas acceptable comme défaut pour un SaaS de flotte.

La fréquence doit être configurable selon :
- statut du véhicule / session ;
- mouvement vs arrêt ;
- niveau de batterie ;
- précision GNSS ;
- mode foreground/background ;
- disponibilité réseau ;
- finalité et durée de conservation autorisées.

Ne pas fixer une fréquence réglementaire ou commerciale sans tests terrain. Prévoir le batch et l'archivage/purge avant tout pilote GPS.

### 5.3 Retention

La durée des positions n'est pas fixée dans ce contrat. Elle doit être déterminée avant la mise en production en fonction de la finalité, des obligations du client et du cadre algérien de protection des données. L'architecture doit supporter :
- retention configurable par tenant sous limites plateforme ;
- purge automatisée et journalisée ;
- agrégats de trajet conservés séparément des fixes bruts lorsque cela est justifié ;
- suspension légale de purge avec autorisation et audit.

---

## 6. Stratégie de migration SQLite

Le schéma local était à la version 11 au début de l'implémentation de phase 1 ; la migration 12 est maintenant ajoutée sur la branche de travail. Proposition de séquencement ; les numéros définitifs seront ajustés en fonction des modifications intervenues sur la branche avant codage.

| Version cible | Migration |
|---|---|
| 12 | **Implémentée** — ajouter payload_version, idempotency_key, next_attempt_at, last_error_code/message, completed_at ; backfill idempotencyKey depuis id |
| 13 | À implémenter — ajouter base_revision, depends_on_operation_id, sequence_no ; initialiser sequence stable depuis created_at + rowid |
| 14 | Ajouter server_revision aux tables véhicules/chauffeurs et créer tables typed sites/assignments |
| 15 | Ajouter tables locales parking et documents/médias |
| 16 | Ajouter meter readings et maintenance |
| 17 | Ajouter tracking_devices/sessions/location buffer seulement après gate privacy/légal |
| 18 | Ajouter vehicle_events et mécanisme de receipts/cursors par domaine si requis |

Chaque migration :
- est idempotente et testée depuis schema version 11 ;
- ne détruit aucune donnée ;
- ajoute un index seulement après contrôle de doublons ;
- peut être reprise après interruption ;
- écrit son résultat dans schema_migrations ;
- possède un test de rollback/backup lorsque le moteur SQLite permet cette stratégie ;
- garde la lecture des anciens payloads pendant la fenêtre de coexistence.

Les versions ne sont pas à sauter ni à appliquer à la main. Une migration ne doit être marquée terminée qu'après validation de ses DDL et backfills.

---

## 7. Plan de tests obligatoire

### 7.1 Tests de transaction locale
- create : row + outbox présents après commit.
- crash/exception entre chaque instruction : rollback des deux.
- update : dernière valeur locale et outbox cohérentes.
- delete : tombstone et suppression locale atomiques.
- create → update → delete coalescé correctement.
- parent avec enfants : delete parent bloqué tant que les dépendances n'ont pas été résolues.

### 7.2 Tests de synchronisation
- online success ;
- offline enqueue puis reconnect ;
- timeout après commit serveur avant ACK ;
- double retry sur même operationId ;
- 401/403, 400 validation, 409 revision, 429, 5xx ;
- serveur déployé avec mauvais contrat / action inconnue ;
- perte de lease pendant requête ;
- application fermée en processing puis récupération ;
- changement de companyId ;
- deux companies dans la même base locale ;
- conflits indépendants dans deux véhicules : un conflit ne bloque pas toute la file.

### 7.3 Tests multitenant
- Admin A ne lit/écrit pas les lignes B.
- Manager A ne référence pas un driver B, site B, parking B ou device B.
- Employee A ne modifie que les ressources permises.
- Super Admin n'agit sur un tenant qu'avec contexte d'exploration explicite et audité.
- Le client ne peut pas choisir teamId ni permissions de row.
- Les requêtes directes Appwrite ne contournent pas les ACL.

### 7.4 Test de non-régression du véhicule
- Créer le véhicule hors ligne.
- Le fermer/réouvrir l'application.
- Reconnecter.
- Confirmer rowId stable dans Appwrite.
- Confirmer companyId correct.
- Confirmer quota incrémenté une seule fois.
- Rejouer la même opération.
- Confirmer une seule ligne et une seule unité de quota.

---

## 8. Décisions Web

Le Web n'utilise pas aujourd'hui le cache SQLite et l'outbox décrits ci-dessus. Le contrat v1 garde ce comportement :
- online-only ;
- détection de perte de réseau ;
- message clair « enregistrement indisponible hors ligne » ;
- aucune fausse confirmation locale ;
- même API métier et mêmes validations tenant serveur que le natif.

Une future version offline Web devra utiliser IndexedDB, une outbox persistante équivalente et les mêmes contrats de synchronisation. Ne pas simuler cela par localStorage.

---

## 9. Gate de sortie

Le contrat SQLite/sync sera considéré implémentable après :
- validation de l'atomicité local + outbox ;
- ajout du contrat de dépendances ;
- codes erreur stables serveur ;
- idempotence démontrée par tests de perte d'ACK ;
- révision et gestion de conflits définies ;
- company scope obligatoire sur chaque méthode de cache ;
- tests Web online-only et natif offline-first séparés ;
- stratégie de rétention GPS et conformité approuvées.

**Aucune migration SQLite n'est appliquée par ce document.**
