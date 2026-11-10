import 'package:appwrite/appwrite.dart';

import '../device/device_identity.dart';
import '../sync/sync_operation.dart';
import '../sync/sqlite_sync_queue.dart';
import '../database/local_database.dart';
import '../../providers/client_database.dart' as legacy;

/// Local-first persistence and outbox adapter for the legacy stock catalogue.
///
/// The legacy Appwrite tables are already provisioned per ParcOto installation.
/// Company identity is therefore enforced in SQLite and in the outbox; it is
/// intentionally not injected as an unknown Appwrite column.
class LegacyStockSyncService {
  static const tableByEntity = <String, String>{
    'part': legacy.partsID,
    'part_category': legacy.categoriesID,
    'part_brand': legacy.brandsID,
    'part_option': legacy.optionsID,
    'supplier': legacy.fournsID,
  };

  final LocalDatabase localDatabase;
  final SqliteSyncQueue queue;
  final DeviceIdentity deviceIdentity;
  final String companyId;

  LegacyStockSyncService({
    required this.localDatabase,
    required this.queue,
    required this.deviceIdentity,
    required this.companyId,
  });

  Future<void> save({
    required String entity,
    required String id,
    required Map<String, dynamic> data,
    required bool isNew,
  }) async {
    final payload = <String, dynamic>{
      ...data,
      r'$id': id,
    };
    final deviceId = await deviceIdentity.getDeviceId();
    final now = DateTime.now().toUtc();
    // The outbox is the source of truth. Queue first so a cache write failure
    // can never leave a visible local row with no operation to synchronize.
    await queue.enqueue(SyncOperation(
      id: '${deviceId}_${entity}_${id}_${now.microsecondsSinceEpoch}',
      companyId: companyId,
      deviceId: deviceId,
      entity: entity,
      entityId: id,
      type: isNew ? SyncOperationType.create : SyncOperationType.update,
      payload: data,
      createdAt: now,
    ));
    localDatabase.cacheLegacyRow(
      companyId: companyId,
      entity: entity,
      entityId: id,
      payload: payload,
    );
  }

  Future<void> delete({
    required String entity,
    required String id,
  }) async {
    final deviceId = await deviceIdentity.getDeviceId();
    final now = DateTime.now().toUtc();
    // Queue first: never discard the only local copy of a pending deletion.
    await queue.enqueue(SyncOperation(
      id: '${deviceId}_${entity}_${id}_${now.microsecondsSinceEpoch}',
      companyId: companyId,
      deviceId: deviceId,
      entity: entity,
      entityId: id,
      type: SyncOperationType.delete,
      payload: <String, dynamic>{r'$id': id},
      createdAt: now,
    ));
    localDatabase.deleteLegacyRow(
      companyId: companyId,
      entity: entity,
      entityId: id,
    );
  }

  /// Pulls the legacy stock catalogue into the company-scoped SQLite
  /// cache. These Appwrite tables are installation-scoped and do not expose
  /// companyId, so tenant isolation is applied by the local cache and outbox.
  Future<int> pullRemoteChanges() async {
    final database = legacy.DatabaseGetter.database;
    if (database == null) {
      throw StateError('Appwrite database unavailable for stock pull.');
    }

    final startedAt = DateTime.now().toUtc();
    var imported = 0;
    for (final entry in tableByEntity.entries) {
      final entity = entry.key;
      final tableId = entry.value;
      final cursor = localDatabase.readSyncCursor(
            companyId: companyId,
            entity: entity,
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      final since = cursor.subtract(const Duration(seconds: 5));
      var offset = 0;
      while (true) {
        final page = await database.listRows(
          databaseId: legacy.databaseId,
          tableId: tableId,
          queries: [
            Query.greaterThan(r'$updatedAt', since.toIso8601String()),
            Query.orderAsc(r'$updatedAt'),
            Query.limit(100),
            Query.offset(offset),
          ],
        );
        if (page.rows.isEmpty) break;
        for (final row in page.rows) {
          final hasLocalMutation = await queue.hasUnresolvedMutation(
            companyId: companyId,
            entity: entity,
            entityId: row.$id,
          );
          if (hasLocalMutation) continue;
          localDatabase.cacheLegacyRow(
            companyId: companyId,
            entity: entity,
            entityId: row.$id,
            payload: <String, dynamic>{
              ...Map<String, dynamic>.from(row.data),
              r'$id': row.$id,
              r'$createdAt': row.$createdAt,
              r'$updatedAt': row.$updatedAt,
            },
          );
          imported++;
        }
        offset += page.rows.length;
        if (page.rows.length < 100) break;
      }
      localDatabase.saveSyncCursor(
        companyId: companyId,
        entity: entity,
        cursor: startedAt.subtract(const Duration(seconds: 5)),
      );
    }

    final reconciled = await _reconcileRemoteSnapshots(startedAt);
    debugPrint(
      '[ParcOto Stock Sync] rows pulled=$imported, remote deletions=$reconciled',
    );
    return imported;
  }

  /// Detects hard deletes once per day. Two full scans must agree, and only
  /// IDs in a previous complete snapshot are eligible for cache removal.
  Future<int> _reconcileRemoteSnapshots(DateTime now) async {
    final lastRun = localDatabase.readReconciliationTime(
      companyId: companyId,
      entity: 'legacy_stock',
    );
    if (lastRun != null &&
        now.difference(lastRun) < const Duration(hours: 24)) {
      return 0;
    }

    final database = legacy.DatabaseGetter.database;
    if (database == null) {
      throw StateError('Appwrite database unavailable for stock reconciliation.');
    }

    Future<Map<String, Set<String>>> scan() async {
      final result = <String, Set<String>>{};
      for (final entry in tableByEntity.entries) {
        final ids = <String>{};
        var offset = 0;
        while (true) {
          final page = await database.listRows(
            databaseId: legacy.databaseId,
            tableId: entry.value,
            queries: [
              Query.orderAsc(r'$id'),
              Query.limit(100),
              Query.offset(offset),
            ],
          );
          ids.addAll(page.rows.map((row) => row.$id));
          if (page.rows.length < 100) break;
          offset += page.rows.length;
        }
        result[entry.key] = ids;
      }
      return result;
    }

    final first = await scan();
    final second = await scan();
    for (final entity in tableByEntity.keys) {
      final firstIds = first[entity]!;
      final secondIds = second[entity]!;
      if (firstIds.length != secondIds.length ||
          !firstIds.containsAll(secondIds)) {
        debugPrint(
          '[ParcOto Stock Sync] $entity reconciliation deferred: unstable snapshot',
        );
        return 0;
      }
    }

    var deleted = 0;
    for (final entity in tableByEntity.keys) {
      final currentIds = second[entity]!;
      final previousIds = localDatabase.readRemoteSnapshotIds(
        companyId: companyId,
        entity: entity,
      );
      for (final missingId in previousIds.difference(currentIds)) {
        final hasLocalMutation = await queue.hasUnresolvedMutation(
          companyId: companyId,
          entity: entity,
          entityId: missingId,
        );
        if (hasLocalMutation) {
          // Keep it in the baseline so a later reconciliation retries.
          currentIds.add(missingId);
          continue;
        }
        localDatabase.deleteLegacyRow(
          companyId: companyId,
          entity: entity,
          entityId: missingId,
        );
        deleted++;
      }
      localDatabase.replaceRemoteSnapshot(
        companyId: companyId,
        entity: entity,
        entityIds: currentIds,
      );
    }

    localDatabase.saveReconciliationTime(
      companyId: companyId,
      entity: 'legacy_stock',
      reconciledAt: now,
    );
    return deleted;
  }

  Future<void> applySyncOperation(SyncOperation operation) async {
    if (operation.companyId != companyId) {
      throw StateError('Stock sync operation belongs to another company.');
    }
    final tableId = tableByEntity[operation.entity];
    if (tableId == null) {
      throw StateError('Unsupported stock entity: ${operation.entity}');
    }

    switch (operation.type) {
      case SyncOperationType.create:
        try {
          await legacy.DatabaseGetter.database!.createRow(
            databaseId: legacy.databaseId,
            tableId: tableId,
            rowId: operation.entityId,
            data: operation.payload,
          );
        } on AppwriteException catch (error) {
          // A timeout can happen after Appwrite committed the row. Retrying
          // the create then returns 409 even though this exact row exists.
          // Verify the row ID before treating the operation as an idempotent
          // replay; never convert unrelated conflicts into updates.
          if (error.code != 409) rethrow;
          try {
            await legacy.DatabaseGetter.database!.getRow(
              databaseId: legacy.databaseId,
              tableId: tableId,
              rowId: operation.entityId,
            );
          } on AppwriteException catch (lookupError) {
            if (lookupError.code == 404) throw error;
            rethrow;
          }
          await legacy.DatabaseGetter.database!.updateRow(
            databaseId: legacy.databaseId,
            tableId: tableId,
            rowId: operation.entityId,
            data: operation.payload,
          );
        }
        break;
      case SyncOperationType.update:
        await legacy.DatabaseGetter.database!.updateRow(
          databaseId: legacy.databaseId,
          tableId: tableId,
          rowId: operation.entityId,
          data: operation.payload,
        );
        break;
      case SyncOperationType.delete:
        try {
          await legacy.DatabaseGetter.database!.deleteRow(
            databaseId: legacy.databaseId,
            tableId: tableId,
            rowId: operation.entityId,
          );
        } on AppwriteException catch (error) {
          // Deleting an already absent row is the desired final state. This
          // makes retries safe if Appwrite deleted it but the response was lost.
          if (error.code != 404) rethrow;
        }
        break;
    }
  }
}
