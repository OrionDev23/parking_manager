import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/drivers/sqlite_driver_source.dart';
import '../../data/repositories/driver_repository_impl.dart';
import '../../data/remote/drivers/appwrite_driver_source.dart';
import '../sync/sync_operation.dart';
import '../backend/appwrite_backend.dart';
import '../backend/backend_config.dart';
import '../backend/backend_type.dart';
import '../../domain/entities/driver.dart' as domain;
import '../../domain/repositories/driver_repository.dart';
import '../database/local_database.dart';
import '../device/shared_preferences_device_identity.dart';
import '../sync/sqlite_sync_queue.dart';
import '../tenancy/company_context.dart';

class DriverServices {
  final LocalDatabase localDatabase;
  final DriverRepository repository;
  final SqliteDriverSource localSource;
  final AppwriteDriverSource remoteSource;
  final SqliteSyncQueue syncQueue;
  final String companyId;

  DriverServices._({
    required this.localDatabase,
    required this.repository,
    required this.localSource,
    required this.remoteSource,
    required this.syncQueue,
    required this.companyId,
  });

  static Future<DriverServices> create({
    required SharedPreferences preferences,
    required String companyId,
    required String appwriteProjectId,
  }) async {
    final localDatabase = LocalDatabase();
    await localDatabase.open();

    final deviceIdentity = SharedPreferencesDeviceIdentity(
      Future.value(preferences),
      idFactory: () => 'desktop_${DateTime.now().microsecondsSinceEpoch}',
    );
    final syncQueue = SqliteSyncQueue(localDatabase);
    final localSource = SqliteDriverSource(
      localDatabase,
      companyId: companyId,
    );
    final backend = AppwriteBackend(
      BackendConfig(
        type: BackendType.appwrite,
        endpoint: 'https://fra.cloud.appwrite.io/v1',
        projectId: appwriteProjectId,
      ),
    );
    await backend.initialize();
    final remoteSource = AppwriteDriverSource(
      backend: backend,
      companyContext: CompanyContext(companyId: companyId),
      databaseId: '6531ad112080ae3b14a7',
      tableId: '6537d87b492c80f255e8',
    );

    return DriverServices._(
      localDatabase: localDatabase,
      localSource: localSource,
      remoteSource: remoteSource,
      syncQueue: syncQueue,
      companyId: companyId,
      repository: DriverRepositoryImpl(
        local: localSource,
        syncQueue: syncQueue,
        deviceIdentity: deviceIdentity,
        companyContext: CompanyContext(companyId: companyId),
        remote: remoteSource,
      ),
    );
  }

  Future<void> seedLocal(domain.Driver driver) =>
      localSource.upsertDriver(driver);

  /// Backfills missing SQLite cache rows from Appwrite without overwriting
  /// local records that may contain offline changes.
  Future<int> migrateRemoteCache() async {
    var migrated = 0;
    for (final includeArchived in [false, true]) {
      var offset = 0;
      while (true) {
        final page = await remoteSource.getDrivers(
          limit: 100,
          offset: offset,
          includeArchived: includeArchived,
        );
        if (page.isEmpty) break;
        for (final driver in page) {
          if (await localSource.getDriver(driver.id) == null) {
            await localSource.upsertDriver(driver);
            migrated++;
          }
        }
        offset += page.length;
        if (page.length < 100) break;
      }
    }
    debugPrint('[ParcOto Migration] drivers copied to SQLite: $migrated');
    return migrated;
  }

  /// Pulls remote changes into SQLite while preserving records with local
  /// mutations that have not yet been acknowledged by Appwrite.
  Future<int> pullRemoteChanges() async {
    final startedAt = DateTime.now().toUtc();
    final cursor = localDatabase.readSyncCursor(
          companyId: companyId,
          entity: 'driver',
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final since = cursor.subtract(const Duration(seconds: 5));
    var offset = 0;
    var imported = 0;
    while (true) {
      final page = await remoteSource.getDriversUpdatedSince(
        since,
        limit: 100,
        offset: offset,
      );
      if (page.isEmpty) break;
      for (final driver in page) {
        final hasLocalMutation = await syncQueue.hasUnresolvedMutation(
          companyId: companyId,
          entity: 'driver',
          entityId: driver.id,
        );
        if (hasLocalMutation) continue;
        await localSource.upsertDriver(driver);
        imported++;
      }
      offset += page.length;
      if (page.length < 100) break;
    }
    localDatabase.saveSyncCursor(
      companyId: companyId,
      entity: 'driver',
      cursor: startedAt.subtract(const Duration(seconds: 5)),
    );
    final reconciled = await _reconcileRemoteDeletions(startedAt);
    debugPrint(
      '[ParcOto Sync] drivers pulled=$imported, remote deletions=$reconciled',
    );
    return imported;
  }

  /// Driver state 3 is an archive state, not a deletion. Both active and
  /// archived rows are included in each complete remote snapshot.
  Future<int> _reconcileRemoteDeletions(DateTime now) async {
    final lastRun = localDatabase.readReconciliationTime(
      companyId: companyId,
      entity: 'driver',
    );
    if (lastRun != null &&
        now.difference(lastRun) < const Duration(hours: 24)) {
      return 0;
    }

    Future<Set<String>> scanRemoteIds() async {
      final ids = <String>{};
      for (final includeArchived in [false, true]) {
        var offset = 0;
        while (true) {
          final page = await remoteSource.getDrivers(
            limit: 100,
            offset: offset,
            includeArchived: includeArchived,
          );
          ids.addAll(page.map((item) => item.id));
          if (page.length < 100) break;
          offset += page.length;
        }
      }
      return ids;
    }

    final firstScan = await scanRemoteIds();
    final secondScan = await scanRemoteIds();
    if (firstScan.length != secondScan.length ||
        !firstScan.containsAll(secondScan)) {
      debugPrint('[ParcOto Sync] driver reconciliation deferred: unstable snapshot');
      return 0;
    }

    final localDrivers = [
      ...await localSource.getDrivers(),
      ...await localSource.getDrivers(includeArchived: true),
    ];
    final checkedIds = <String>{};
    var deleted = 0;
    for (final driver in localDrivers) {
      if (!checkedIds.add(driver.id) || secondScan.contains(driver.id)) {
        continue;
      }
      final hasLocalMutation = await syncQueue.hasUnresolvedMutation(
        companyId: companyId,
        entity: 'driver',
        entityId: driver.id,
      );
      if (hasLocalMutation) continue;
      await localSource.deleteDriver(driver.id);
      deleted++;
    }

    localDatabase.saveReconciliationTime(
      companyId: companyId,
      entity: 'driver',
      reconciledAt: now,
    );
    return deleted;
  }

  Future<void> applySyncOperation(SyncOperation operation) async {
    if (operation.companyId != companyId) {
      throw StateError('Driver sync operation belongs to another company.');
    }
    switch (operation.type) {
      case SyncOperationType.create:
        final driver = domain.Driver.fromMap(operation.payload);
        try {
          await remoteSource.createDriver(driver);
        } on AppwriteException catch (error) {
          if (error.code != 409) rethrow;
          // Recover a create whose remote commit succeeded but whose
          // response was lost. Only update after verifying tenant ownership.
          final existing = await remoteSource.getDriver(operation.entityId);
          if (existing == null) rethrow;
          await remoteSource.updateDriver(driver);
        }
        return;
      case SyncOperationType.update:
        await remoteSource.updateDriver(
          domain.Driver.fromMap(operation.payload),
        );
        return;
      case SyncOperationType.delete:
        try {
          await remoteSource.deleteDriver(operation.entityId);
        } on AppwriteException catch (error) {
          // Missing rows already satisfy the desired delete state.
          if (error.code != 404) rethrow;
        }
        return;
    }
  }

  Future<void> dispose() => localDatabase.close();
}
