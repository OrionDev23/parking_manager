import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/vehicles/sqlite_vehicle_source.dart';
import '../../data/remote/vehicles/appwrite_vehicle_source.dart';
import '../../core/sync/sync_operation.dart';
import '../../data/repositories/vehicle_repository_impl.dart';
import '../../domain/entities/vehicle.dart' as domain;
import '../../domain/repositories/vehicle_repository.dart';
import '../backend/appwrite_backend.dart';
import '../backend/backend_config.dart';
import '../backend/backend_type.dart';
import '../database/local_database.dart';
import '../device/shared_preferences_device_identity.dart';
import '../sync/sqlite_sync_queue.dart';
import '../tenancy/company_context.dart';
import '../../providers/client_database.dart' show databaseId, vehiculeid, endpoint;

class VehicleServices {
  final LocalDatabase localDatabase;
  final VehicleRepository repository;
  final SqliteVehicleSource localSource;
  final AppwriteVehicleSource remoteSource;
  final SqliteSyncQueue syncQueue;
  final String companyId;

  VehicleServices._({
    required this.localDatabase,
    required this.repository,
    required this.localSource,
    required this.remoteSource,
    required this.syncQueue,
    required this.companyId,
  });

  static Future<VehicleServices> create({
    required SharedPreferences preferences,
    required String companyId,
  }) async {
    final localDatabase = LocalDatabase();
    await localDatabase.open();

    final deviceIdentity = SharedPreferencesDeviceIdentity(
      Future.value(preferences),
      idFactory: () =>
          'desktop_${DateTime.now().microsecondsSinceEpoch}',
    );
    final syncQueue = SqliteSyncQueue(localDatabase);
    final localSource = SqliteVehicleSource(
      localDatabase,
      companyId: companyId,
    );

    // Constructing the client is offline-safe; requests are made only when a
    // repository read needs to hydrate an empty local cache.
    final backend = AppwriteBackend(
      BackendConfig(
        type: BackendType.appwrite,
        endpoint: endpoint,
        projectId: preferences.getString('project') ?? 'essais',
      ),
    );
    await backend.initialize();
    final remoteSource = AppwriteVehicleSource(
      backend: backend,
      companyContext: CompanyContext(companyId: companyId),
      databaseId: databaseId,
      tableId: vehiculeid,
    );

    return VehicleServices._(
      localDatabase: localDatabase,
      localSource: localSource,
      remoteSource: remoteSource,
      syncQueue: syncQueue,
      companyId: companyId,
      repository: VehicleRepositoryImpl(
        local: localSource,
        syncQueue: syncQueue,
        deviceIdentity: deviceIdentity,
        companyContext: CompanyContext(companyId: companyId),
        remote: remoteSource,
      ),
    );
  }

  Future<void> seedLocal(domain.Vehicle vehicle) =>
      localSource.upsertVehicle(vehicle);

  /// Backfills missing SQLite cache rows from the migrated Appwrite table.
  /// Existing local rows are never overwritten, so pending offline edits survive.
  Future<int> migrateRemoteCache() async {
    var offset = 0;
    var migrated = 0;
    while (true) {
      final page = await remoteSource.getVehicles(limit: 100, offset: offset);
      if (page.isEmpty) break;
      for (final vehicle in page) {
        if (await localSource.getVehicle(vehicle.id) == null) {
          await localSource.upsertVehicle(vehicle);
          migrated++;
        }
      }
      offset += page.length;
      if (page.length < 100) break;
    }
    debugPrint('[ParcOto Migration] vehicles copied to SQLite: $migrated');
    return migrated;
  }

  /// Pulls remote changes into SQLite. A small overlap on the cursor makes
  /// pagination resilient to writes committed while a pull is in progress.
  Future<int> pullRemoteChanges() async {
    final startedAt = DateTime.now().toUtc();
    final cursor = localDatabase.readSyncCursor(
          companyId: companyId,
          entity: 'vehicle',
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final since = cursor.subtract(const Duration(seconds: 5));
    var offset = 0;
    var imported = 0;
    while (true) {
      final page = await remoteSource.getVehiclesUpdatedSince(
        since,
        limit: 100,
        offset: offset,
      );
      if (page.isEmpty) break;
      for (final vehicle in page) {
        final hasLocalMutation = await syncQueue.hasUnresolvedMutation(
          companyId: companyId,
          entity: 'vehicle',
          entityId: vehicle.id,
        );
        if (hasLocalMutation) continue;
        await localSource.upsertVehicle(vehicle);
        imported++;
      }
      offset += page.length;
      if (page.length < 100) break;
    }
    localDatabase.saveSyncCursor(
      companyId: companyId,
      entity: 'vehicle',
      cursor: startedAt.subtract(const Duration(seconds: 5)),
    );
    debugPrint('[ParcOto Sync] vehicles pulled=$imported');
    return imported;
  }

  Future<void> applySyncOperation(SyncOperation operation) async {
    if (operation.companyId != companyId) {
      throw StateError('Vehicle sync operation belongs to another company.');
    }
    switch (operation.type) {
      case SyncOperationType.create:
        final vehicle = domain.Vehicle.fromMap(operation.payload);
        try {
          await remoteSource.createVehicle(vehicle);
        } on AppwriteException catch (error) {
          if (error.code != 409) rethrow;
          // A previous attempt may have committed remotely before its
          // response was lost. Verify this exact tenant-owned row, then
          // converge it to the latest queued payload.
          final existing = await remoteSource.getVehicle(operation.entityId);
          if (existing == null) rethrow;
          await remoteSource.updateVehicle(vehicle);
        }
        return;
      case SyncOperationType.update:
        await remoteSource.updateVehicle(
          domain.Vehicle.fromMap(operation.payload),
        );
        return;
      case SyncOperationType.delete:
        try {
          await remoteSource.deleteVehicle(operation.entityId);
        } on AppwriteException catch (error) {
          // Missing rows already satisfy the desired delete state.
          if (error.code != 404) rethrow;
        }
        return;
    }
  }

  Future<void> dispose() => localDatabase.close();
}
