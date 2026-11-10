import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/serializables/activity.dart';
import 'package:encrypt/encrypt.dart' as en;

import '../admin_parameters.dart';
import '../main.dart';
import '../screens/entreprise/entreprise.dart';
import '../screens/sidemenu/sidemenu.dart';
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
const partsID = "parts";
const backupId = "backup";
const storageId = "storage";
const endpoint = "https://fra.cloud.appwrite.io/v1";
String? project;

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
  static int _projectGeneration = 0;

  /// Called when the authenticated tenant expires while the legacy auth
  /// adapter is loading its profile. Keeps session teardown centralized.
  static Future<void> Function()? onSessionExpired;

  static bool _isCurrentProject(int generation, String projectId) =>
      generation == _projectGeneration && _configuredProjectId == projectId;

  static String? get activeProjectId => _configuredProjectId;
  static int get tenantRevision => _projectGeneration;

  static bool isCurrentTenant(String projectId) =>
      _isCurrentProject(_projectGeneration, projectId);

  static bool isCurrentTenantRevision(String projectId, int revision) =>
      _isCurrentProject(revision, projectId);

  /// Invalidates asynchronous work even when the next session uses the same
  /// Appwrite project. This is required for logout/login in one tenant.
  static void invalidatePendingRequests() {
    _projectGeneration++;
    gettingUser = false;
    settingSecretKey = false;
    MyEntrepriseState.downloading = false;
  }

  DatabaseGetter() {
    final requestedProject = project ?? prefs.getString('project');
    if (requestedProject == null || requestedProject.isEmpty) return;

    // Rebuild the legacy Appwrite clients only when the project actually
    // changes. Never carry profile, licensing, team or encryption state
    // from one project into another.
    if (_configuredProjectId != requestedProject) {
      _projectGeneration++;
      _configuredProjectId = requestedProject;
      project = requestedProject;
      user = null;
      me.value = null;
      myTeams = List.empty(growable: true);
      trialDate = null;
      limits = {};
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

        if (trialDate == null ||
            trialDate!.difference(DateTime.now()).inMilliseconds <= 0) {
          await onSessionExpired?.call();
          // The callback invalidates pending requests, so use the captured
          // account to revoke this expired session even after generation changes.
          if (_configuredProjectId != projectId) return;
          try {
            await activeAccount.deleteSession(sessionId: 'current');
          } catch (error) {
            // The session may already have been revoked server-side.
            if (kDebugMode) {
              debugPrint('Expired session revocation failed: $error');
            }
          } finally {
            if (_configuredProjectId == projectId) {
              user = null;
              me.value = null;
              myTeams = List.empty(growable: true);
              trialDate = null;
              PanesListState.signedIn.value = false;
              PanesListState.index.value = 0;
            }
          }
          return;
        }

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
        rowId: '1',
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
    final activeDatabase = database;
    if (projectId == null || activeDatabase == null) return;
    final generation = _projectGeneration;

    if (MyEntrepriseState.p == null && !MyEntrepriseState.downloading) {
      MyEntrepriseState.downloading = true;
      try {
        final value = await activeDatabase.getRow(
          databaseId: databaseId,
          tableId: entrepriseid,
          rowId: '1',
        );
        if (_isCurrentProject(generation, projectId)) {
          MyEntrepriseState.p = value.convertTo(
            (p0) => Entreprise.fromJson(p0),
          );
        }
      } catch (_) {
        // The company profile is optional during initial rendering.
      } finally {
        if (_isCurrentProject(generation, projectId)) {
          MyEntrepriseState.downloading = false;
        }
      }
    }
    if (kIsWeb && _isCurrentProject(generation, projectId)) {
      await downloadLogo();
    }
  }

  static Future<void> downloadLogo() async {
    final projectId = _configuredProjectId;
    final activeStorage = storage;
    if (projectId == null || activeStorage == null) return;
    final generation = _projectGeneration;
    try {
      final value = await activeStorage.getFileDownload(
        bucketId: buckedId,
        fileId: 'mylogo.png',
      );
      if (_isCurrentProject(generation, projectId)) {
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
        Permission.read(Role.users()),
        Permission.write(Role.user(me.value!.id)),
        Permission.update(Role.user(me.value!.id)),
        Permission.delete(Role.user(me.value!.id)),
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
      data: activity.toJson(),
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
    await database?.createRow(
      databaseId: databaseId,
      tableId: collectionId,
      rowId: documentId,
      data: data,
    );
  }

  Future<void> updateDocument({
    required String collectionId,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    await database?.updateRow(
      databaseId: databaseId,
      tableId: collectionId,
      rowId: documentId,
      data: data,
    );
  }

  Future<Row?> getDocument(String collectionId, String documentId) async {
    return database?.getRow(
      databaseId: databaseId,
      tableId: collectionId,
      rowId: documentId,
    );
  }

  Future<List<Row>> listDocuments(String path) async {
    List<Row> result = List.empty(growable: true);
    int nextPageToken = 0;
    bool hasNextPage = true;
    while (hasNextPage) {
      await database
          ?.listRows(
            databaseId: databaseId,
            tableId: path,
            queries: [Query.limit(5000), Query.offset(nextPageToken)],
          )
          .then((value) {
            hasNextPage = value.total >= 5000;
            nextPageToken += 5000;
            result.addAll(value.rows);
          });
    }

    return result;
  }
}
