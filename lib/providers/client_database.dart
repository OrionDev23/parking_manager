import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/serializables/activity.dart';
import 'package:encrypt/encrypt.dart' as en;

import '../admin_parameters.dart';
import '../core/tenancy/tenant_resource_api.dart';
import '../screens/entreprise/entreprise.dart';
import '../serializables/entreprise.dart';
import '../serializables/parc_user.dart';
import 'activities.dart';

const databaseId = "6531ad112080ae3b14a7";
const userid = "users";
const trialID = "trialdate";
const limitsID = "limits";
const chauffeurid = "6537d87b492c80f255e8";
const genreid = "6537960246d5b0e1ab77";
const vehiculeid = "6531ad22153b2a49ca2c";
const etatId = "etat";
const chaufDispID = "chauf_disponibilite";
const chaufDoc = "doc_chauffeur";
const vehicDoc = "doc_vehic";
const entrepriseid = "entreprise";
const planningID = "planning";
const buckedId = "images";
const adminID = "admin_keys";
const reparationId = "reparation";
const activityId = "activity";
const prestataireId = "prestataire";
const fichesreceptionId = "fichereception";
const clientsID = "clients";
const fournsID = "fournisseurs";
const optionsID = "options";
const categoriesID = "categories";
const brandsID = "partsbrands";
const marqueID = "marque";
const partsID = "parts";
const backupId = "backup";
const storageId = "storage";

const Set<String> tenantScopedTableIds = {
  chauffeurid,
  vehiculeid,
  etatId,
  vehicDoc,
  reparationId,
  activityId,
  chaufDispID,
  chaufDoc,
  entrepriseid,
  planningID,
  prestataireId,
  fichesreceptionId,
  clientsID,
  partsID,
  storageId,
  backupId,
  'access_teams',
  'access_users',
  fournsID,
  optionsID,
  categoriesID,
  brandsID,
  marqueID,
};
const endpoint = "https://fra.cloud.appwrite.io/v1";
const appwriteProjectId = 'essais';
String? project = appwriteProjectId;

String? secretKey;

class DatabaseGetter {
  static bool secretKeySet = false;
  static Client? client;
  static Account? account;
  static User? user;

  static List<Team> myTeams = List.empty(growable: true);
  static Storage? storage;
  static final DateTime ref = DateTime(2023, 11, 01, 12, 13, 15);

  static TablesDB? database;

  static ValueNotifier<ParcUser?> me = ValueNotifier(null);
  static String? _configuredProjectId;
  static String? _activeCompanyId;
  static String? _activeCompanyTeamId;
  static String? _activeCompanyProfileRowId;
  static int _projectGeneration = 0;
  static int _companyGeneration = 0;
  static final ValueNotifier<int> companyRevisionListenable = ValueNotifier(0);
  static Map<String, int> _defaultLimits = {};
  static DateTime? companyLicenseStartsAt;
  static DateTime? companyLicenseExpiresAt;

  /// Called when the authenticated tenant expires while the legacy auth
  /// adapter is loading its profile. Keeps session teardown centralized.
  static Future<void> Function()? onSessionExpired;

  static bool _isCurrentProject(int generation, String projectId) =>
      generation == _projectGeneration && _configuredProjectId == projectId;

  static String? get activeProjectId => _configuredProjectId;
  static String? get activeCompanyId => _activeCompanyId;
  static String? get activeCompanyTeamId => _activeCompanyTeamId;
  static String? get activeCompanyProfileRowId => _activeCompanyProfileRowId;
  static int get companyRevision => _companyGeneration;

  static bool _isCurrentCompany(String companyId, int generation) =>
      _activeCompanyId == companyId && _companyGeneration == generation;

  static bool _isTenantScoped(String tableId) =>
      tenantScopedTableIds.contains(tableId);

  static List<String> _tenantRowPermissions() {
    final teamId = _activeCompanyTeamId;
    if (teamId == null || teamId.isEmpty) {
      throw StateError('The active company has no Appwrite team context.');
    }
    return [
      Permission.read(Role.team(teamId)),
      Permission.update(Role.team(teamId, 'admin')),
      Permission.update(Role.team(teamId, 'manager')),
      Permission.delete(Role.team(teamId, 'admin')),
    ];
  }

  static void _assertTenantRow(String tableId, Map<String, dynamic> data) {
    if (_isTenantScoped(tableId) &&
        (_activeCompanyId == null || data['companyId'] != _activeCompanyId)) {
      throw StateError('The requested row does not belong to the active company.');
    }
  }

  static Future<void> setActiveCompanyId(
    String? companyId, {
    String? teamId,
    String? profileRowId,
    Map<String, dynamic>? entitlement,
  }) async {
    if (_activeCompanyId == companyId &&
        _activeCompanyTeamId == teamId &&
        _activeCompanyProfileRowId == profileRowId &&
        entitlement == null &&
        (companyId == null || MyEntrepriseState.p != null)) {
      return;
    }
    _activeCompanyId = companyId;
    _activeCompanyTeamId = teamId;
    _activeCompanyProfileRowId = profileRowId;
    _companyGeneration++;
    companyRevisionListenable.value = _companyGeneration;
    MyEntrepriseState.p = null;
    MyEntrepriseState.logo = null;
    MyEntrepriseState.imageFile = null;
    MyEntrepriseState.logoExists = false;
    MyEntrepriseState.downloading = false;
    final getter = DatabaseGetter._existing();
    await getter.getLimits();
    limits = Map<String, int>.from(_defaultLimits);
    companyLicenseStartsAt = null;
    companyLicenseExpiresAt = null;
    if (companyId != null) {
      await getter.getEntreprise();
      if (entitlement != null) {
        final maxUsers = entitlement['maxUsers'];
        final maxVehicles = entitlement['maxVehicles'];
        if (maxUsers is num) limits['users'] = maxUsers.toInt();
        if (maxVehicles is num) limits['vehicles'] = maxVehicles.toInt();
        companyLicenseStartsAt =
            DateTime.tryParse(entitlement['startsAt']?.toString() ?? '');
        companyLicenseExpiresAt =
            DateTime.tryParse(entitlement['expiresAt']?.toString() ?? '');
      }
    }
  }
  static int get tenantRevision => _projectGeneration;

  static bool isCurrentTenant(String projectId) =>
      _isCurrentProject(_projectGeneration, projectId);

  static bool isCurrentTenantRevision(String projectId, int revision) =>
      _isCurrentProject(revision, projectId);

  /// Invalidates asynchronous work even when the next session uses the same
  /// Appwrite project. This is required for logout/login in one tenant.
  static void invalidatePendingRequests() {
    _projectGeneration++;
    _companyGeneration++;
    companyRevisionListenable.value = _companyGeneration;
    gettingUser = false;
    settingSecretKey = false;
    MyEntrepriseState.downloading = false;
  }

  DatabaseGetter._existing();

  DatabaseGetter() {
    const requestedProject = appwriteProjectId;
    if (requestedProject.isEmpty) return;

    // Rebuild the legacy Appwrite clients only when the project actually
    // changes. Never carry profile, licensing, team or encryption state
    // from one project into another.
    if (_configuredProjectId != requestedProject) {
      _projectGeneration++;
      _companyGeneration++;
      _configuredProjectId = requestedProject;
      project = requestedProject;
      user = null;
      me.value = null;
      myTeams = List.empty(growable: true);
      trialDate = null;
      limits = {};
      _defaultLimits = {};
      companyLicenseStartsAt = null;
      companyLicenseExpiresAt = null;
      gotLimit = false;
      gettingUser = false;
      secretKey = null;
      secretKeySet = false;
      settingSecretKey = false;
      encrypter = null;
      iv = null;
      MyEntrepriseState.p = null;
      MyEntrepriseState.logo = null;
      MyEntrepriseState.imageFile = null;
      MyEntrepriseState.logoExists = false;
      MyEntrepriseState.downloading = false;

      client = Client()
        ..setEndpoint(endpoint)
        ..setProject(requestedProject);
      account = Account(client!);
      database = TablesDB(client!);
      storage = Storage(client!);
      companyRevisionListenable.value = _companyGeneration;
    }

    getLimits();
    getEntreprise();
  }

  bool isManager({List<Team>? teams}) {
    if (isAdminUI) {
      return false;
    }
    if (isManagerUI) {
      return true;
    }
    for (var element in teams ?? myTeams) {
      if (element.name.toLowerCase() == 'managers') {
        return true;
      }
    }
    return false;
  }

  bool isAdmin({List<Team>? teams}) {
    if (isAdminUI) {
      return true;
    }
    if (isManagerUI) {
      return false;
    }
    for (var element in teams ?? myTeams) {
      if (element.name.toLowerCase() == 'admins') {
        if (teams == null && !secretKeySet) {
          setSecretKey();
        }
        return true;
      }
    }
    return false;
  }

  static bool settingSecretKey = false;

  static en.Encrypter? encrypter;
  static en.IV? iv;
  Future<void> setSecretKey() async {
    final projectId = _configuredProjectId;
    final activeDatabase = database;
    if (projectId == null ||
        activeDatabase == null ||
        settingSecretKey ||
        secretKeySet) {
      return;
    }

    final generation = _projectGeneration;
    settingSecretKey = true;
    try {
      final adminRow = await activeDatabase.getRow(
        databaseId: databaseId,
        tableId: adminID,
        rowId: 'admin',
      );
      if (!_isCurrentProject(generation, projectId)) return;
      final loadedSecret = adminRow.data['key'] as String?;
      if (loadedSecret == null) return;

      final cryptoRow = await activeDatabase.getRow(
        databaseId: databaseId,
        tableId: adminID,
        rowId: 'cryptkey',
      );
      if (!_isCurrentProject(generation, projectId)) return;

      String value = cryptoRow.data['key'] as String;
      if (value.length < 32) {
        value = value.padRight(32, 'p');
      } else {
        value = value.substring(0, 32);
      }
      secretKey = loadedSecret;
      secretKeySet = true;
      final key = en.Key.fromUtf8(value);
      iv = en.IV.fromUtf8(value.substring(0, 16));
      encrypter = en.Encrypter(en.AES(key));
    } catch (error) {
      if (_isCurrentProject(generation, projectId) && kDebugMode) {
        debugPrint('Unable to load Appwrite encryption keys: $error');
      }
    } finally {
      if (_isCurrentProject(generation, projectId)) {
        settingSecretKey = false;
      }
    }
  }

  static bool gettingUser = false;

  Future<void> getUser() async {
    final projectId = _configuredProjectId;
    if (projectId == null) return;
    final generation = _projectGeneration;

    if (user == null && !gettingUser) {
      gettingUser = true;
      try {
        final activeAccount = account;
        final activeDatabase = database;
        if (activeAccount == null || activeDatabase == null) return;

        final loadedUser = await activeAccount.get();
        if (!_isCurrentProject(generation, projectId)) return;
        user = loadedUser;

        await getTrialDate(loadedUser.$id, generation, projectId);
        if (!_isCurrentProject(generation, projectId)) return;

        // License validity is evaluated after the authenticated account's
        // company membership and company entitlement have been resolved.
        // A newly provisioned company administrator may not have a legacy
        // per-user trialdate row, but can still have a valid company licence.

        try {
          final result = await activeDatabase.getRow(
            databaseId: databaseId,
            tableId: userid,
            rowId: loadedUser.$id,
          );
          if (!_isCurrentProject(generation, projectId)) return;
          me.value = ParcUser.fromJson(result.data);
        } catch (_) {
          if (!_isCurrentProject(generation, projectId)) return;
          final fallbackProfile = ParcUser(
            email: loadedUser.email,
            id: loadedUser.$id,
            name: loadedUser.name,
            tel: loadedUser.phone,
          );
          me.value = fallbackProfile;
          uploadUser(fallbackProfile);
        }
      } on AppwriteException catch (error, stackTrace) {
        if (_isCurrentProject(generation, projectId)) {
          if (kDebugMode) {
            print(error.message);
            print(error.response);
            print(stackTrace);
          }
          user = null;
        }
      } finally {
        if (_isCurrentProject(generation, projectId)) {
          gettingUser = false;
        }
      }
    }

    if (_isCurrentProject(generation, projectId) && user != null) {
      final activeClient = client;
      if (activeClient == null) return;
      try {
        final teams = await Teams(activeClient).list();
        if (_isCurrentProject(generation, projectId)) {
          myTeams = teams.teams;
        }
      } catch (error) {
        if (kDebugMode) debugPrint('Unable to load Appwrite teams: $error');
      }
    }
  }

  static DateTime? trialDate;

  static Map<String, int> limits = {};

  static bool gotLimit = false;

  Future<void> getLimits() async {
    final projectId = _configuredProjectId;
    final activeDatabase = database;
    if (projectId == null || activeDatabase == null || gotLimit) return;
    final generation = _projectGeneration;

    try {
      final value = await activeDatabase.getRow(
        databaseId: databaseId,
        tableId: limitsID,
        rowId: '1',
      );
      if (!_isCurrentProject(generation, projectId)) return;
      if (value.data.containsKey('vehicles')) {
        limits['vehicles'] = value.data['vehicles'];
      }
      if (value.data.containsKey('users')) {
        limits['users'] = value.data['users'];
      }
      _defaultLimits = Map<String, int>.from(limits);
      gotLimit = true;
    } on AppwriteException {
      if (_isCurrentProject(generation, projectId)) gotLimit = false;
    }
  }

  Future<void> getTrialDate(
    String userId,
    int generation,
    String projectId,
  ) async {
    if (userId == '999') {
      if (_isCurrentProject(generation, projectId)) {
        trialDate = DateTime(2100);
      }
      return;
    }

    final activeDatabase = database;
    if (activeDatabase == null) return;
    try {
      final value = await activeDatabase.getRow(
        databaseId: databaseId,
        tableId: trialID,
        rowId: userId,
      );
      if (_isCurrentProject(generation, projectId)) {
        trialDate = DateTime.tryParse(value.data['date']);
      }
    } on AppwriteException {
      // A missing trial record remains an invalid/expired trial.
    }
  }

  Future<void> getEntreprise() async {
    final projectId = _configuredProjectId;
    final companyId = _activeCompanyId;
    final profileRowId = _activeCompanyProfileRowId;
    final activeDatabase = database;
    if (projectId == null ||
        companyId == null ||
        profileRowId == null ||
        activeDatabase == null) {
      return;
    }
    final projectGeneration = _projectGeneration;
    final companyGeneration = _companyGeneration;

    if (MyEntrepriseState.p == null && !MyEntrepriseState.downloading) {
      MyEntrepriseState.downloading = true;
      try {
        final row = await activeDatabase.getRow(
          databaseId: databaseId,
          tableId: entrepriseid,
          rowId: profileRowId,
        );
        if (_isCurrentProject(projectGeneration, projectId) &&
            _isCurrentCompany(companyId, companyGeneration)) {
          MyEntrepriseState.p = row.convertTo(
            (data) => Entreprise.fromJson(data),
          );
        }
      } catch (error) {
        if (kDebugMode) {
          debugPrint('[ParcOto Company] profile load failed for $companyId: $error');
        }
      } finally {
        if (_isCurrentProject(projectGeneration, projectId) &&
            _isCurrentCompany(companyId, companyGeneration)) {
          MyEntrepriseState.downloading = false;
        }
      }
    }
    if (kIsWeb &&
        _isCurrentProject(projectGeneration, projectId) &&
        _isCurrentCompany(companyId, companyGeneration)) {
      await downloadLogo(
        companyId: companyId,
        companyGeneration: companyGeneration,
        fileId: MyEntrepriseState.p?.logo,
      );
    }
  }

  static Future<void> downloadLogo({
    String? companyId,
    int? companyGeneration,
    String? fileId,
  }) async {
    final projectId = _configuredProjectId;
    final activeStorage = storage;
    final selectedCompanyId = companyId ?? _activeCompanyId;
    final selectedCompanyGeneration = companyGeneration ?? _companyGeneration;
    if (projectId == null ||
        activeStorage == null ||
        selectedCompanyId == null) {
      return;
    }
    final projectGeneration = _projectGeneration;
    final selectedFileId = fileId?.isNotEmpty == true
        ? fileId!
        : selectedCompanyId;
    try {
      final value = await activeStorage.getFileDownload(
        bucketId: buckedId,
        fileId: selectedFileId,
      );
      if (_isCurrentProject(projectGeneration, projectId) &&
          _isCurrentCompany(selectedCompanyId, selectedCompanyGeneration)) {
        MyEntrepriseState.logo = value;
      }
    } catch (_) {
      // A missing logo must not block the application.
    }
  }

  void uploadUser(ParcUser u) {
    database!.createRow(
      databaseId: databaseId,
      tableId: userid,
      rowId: u.id,
      data: me.value!.toJson(),
      permissions: [
        Permission.read(Role.user(u.id)),
        Permission.update(Role.user(u.id)),
        Permission.delete(Role.user(u.id)),
      ],
    );
  }

  Future<ParcUser?> getUserFromID(String docID) async {
    return await database!
        .getRow(databaseId: databaseId, tableId: userid, rowId: docID)
        .then((value) {
          return value.convertTo((p0) => ParcUser.fromJson(p0));
        })
        .onError((error, stackTrace) {
          return Future.value(ParcUser(id: docID, email: ''));
        });
  }

  Future<void> ajoutActivity(int type, String docID, {String? docName}) async {
    Activity activity = Activity(
      id: DateTime.now().difference(ref).inMilliseconds.toString(),
      type: type,
      docID: docID,
      personName: me.value?.name,
      docName: docName,
      createdBy: me.value?.id,
    );

    await database!.createRow(
      databaseId: databaseId,
      tableId: activityId,
      rowId: activity.id,
      data: {
        ...activity.toJson(),
        'companyId': _activeCompanyId,
      },
      permissions: _tenantRowPermissions(),
    );
  }

  String getActivityType(int type) {
    if (activityList.length > type) {
      return activityList[type];
    }
    return '';
  }

  Future<void> addDocument({
    required String collectionId,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    // Vehicle and driver writes consume licensed quota. Route all legacy
    // imports, restore jobs and direct addDocument callers through the same
    // server transaction as the modern repository sources.
    if (collectionId == vehiculeid || collectionId == chauffeurid) {
      final companyId = _activeCompanyId;
      final activeClient = client;
      if (companyId == null) {
        throw StateError('No active company context is selected.');
      }
      if (activeClient == null) {
        throw StateError('Appwrite client is not initialized.');
      }
      await TenantResourceApi(activeClient).createResource(
        resource: collectionId == vehiculeid ? 'vehicle' : 'driver',
        companyId: companyId,
        rowId: documentId,
        data: data,
      );
      return;
    }

    final tenantScoped = _isTenantScoped(collectionId);
    final rowData = tenantScoped
        ? {...data, 'companyId': _activeCompanyId}
        : data;
    final activeDatabase = database;
    if (activeDatabase == null) {
      throw StateError('Appwrite database is not initialized.');
    }
    if (tenantScoped && _activeCompanyId == null) {
      throw StateError('No active company context is selected.');
    }
    await activeDatabase.createRow(
      databaseId: databaseId,
      tableId: collectionId,
      rowId: documentId,
      data: rowData,
      permissions: tenantScoped ? _tenantRowPermissions() : null,
    );
  }

  Future<void> updateDocument({
    required String collectionId,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    final tenantScoped = _isTenantScoped(collectionId);
    if (tenantScoped) {
      final existing = await database!.getRow(
        databaseId: databaseId,
        tableId: collectionId,
        rowId: documentId,
      );
      _assertTenantRow(collectionId, Map<String, dynamic>.from(existing.data));
    }
    await database?.updateRow(
      databaseId: databaseId,
      tableId: collectionId,
      rowId: documentId,
      data: tenantScoped ? {...data, 'companyId': _activeCompanyId} : data,
      permissions: tenantScoped ? _tenantRowPermissions() : null,
    );
  }

  Future<Row?> getDocument(String collectionId, String documentId) async {
    final row = await database?.getRow(
      databaseId: databaseId,
      tableId: collectionId,
      rowId: documentId,
    );
    if (row != null) {
      _assertTenantRow(collectionId, Map<String, dynamic>.from(row.data));
    }
    return row;
  }

  Future<List<Row>> listDocuments(
    String path, {
    int? maxResults,
  }) async {
    const pageSize = 5000;
    if (maxResults != null && maxResults <= 0) return [];
    final activeDatabase = database;
    if (activeDatabase == null) {
      throw StateError(
        'Cannot list Appwrite table "$path": database client is not initialized.',
      );
    }

    if (_isTenantScoped(path) && _activeCompanyId == null) {
      throw StateError('No active company context is selected.');
    }
    final result = <Row>[];
    var offset = 0;

    while (true) {
      final remaining = maxResults == null
          ? pageSize
          : maxResults - result.length;
      if (remaining <= 0) break;
      final requestLimit =
          remaining < pageSize ? remaining : pageSize;
      final page = await activeDatabase.listRows(
        databaseId: databaseId,
        tableId: path,
        queries: [
          if (_isTenantScoped(path)) Query.equal('companyId', _activeCompanyId!),
          Query.limit(requestLimit),
          Query.offset(offset),
        ],
      );

      if (page.rows.isEmpty) break;

      result.addAll(page.rows);

      // Use actual page length rather than the API's total count; a bounded
      // caller stops exactly at maxResults, while unbounded reads remain
      // fully paginated.
      if (page.rows.length < requestLimit) break;
      offset += page.rows.length;
    }

    return result;
  }
}

/// Device-local preference key scoped to the authenticated company and user.
/// Used only for local notification dismissal; it is not a server read receipt.
String userScopedPreferenceKey(String baseKey) {
  final companyId = DatabaseGetter.activeCompanyId ?? 'no-company';
  final userId = DatabaseGetter.me.value?.id ??
      DatabaseGetter.user?.$id ??
      'no-user';
  return '${baseKey}_${companyId}_$userId';
}
