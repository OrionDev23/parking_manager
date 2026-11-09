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
