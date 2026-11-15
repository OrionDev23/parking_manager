import '../device/device_identity.dart';
import '../sync/sync_operation.dart';
import '../sync/sqlite_sync_queue.dart';
import '../database/local_database.dart';
import '../../providers/client_database.dart' as legacy;

/// Online-only Appwrite adapter for the legacy stock catalogue.
class LegacyStockSyncService {
  static const tableByEntity = <String, String>{
    'part': legacy.partsID,
    'part_category': legacy.categoriesID,
    'part_brand': legacy.brandsID,
    'part_option': legacy.optionsID,
    'supplier': legacy.fournsID,
    'storage': legacy.storageId,
  };

  LegacyStockSyncService({
    required LocalDatabase localDatabase,
    required SqliteSyncQueue queue,
    required DeviceIdentity deviceIdentity,
    required this.companyId,
  });

  final String companyId;

  Future<void> save({
    required String entity,
    required String id,
    required Map<String, dynamic> data,
    required bool isNew,
  }) async {
    final tableId = tableByEntity[entity];
    final database = legacy.DatabaseGetter.database;
    if (tableId == null || database == null) {
      throw StateError('Service Appwrite indisponible.');
    }
    if (isNew) {
      await database.createRow(
        databaseId: legacy.databaseId,
        tableId: tableId,
        rowId: id,
        data: data,
      );
    } else {
      await database.updateRow(
        databaseId: legacy.databaseId,
        tableId: tableId,
        rowId: id,
        data: data,
      );
    }
  }

  Future<void> delete({required String entity, required String id}) async {
    final tableId = tableByEntity[entity];
    final database = legacy.DatabaseGetter.database;
    if (tableId == null || database == null) {
      throw StateError('Service Appwrite indisponible.');
    }
    await database.deleteRow(
      databaseId: legacy.databaseId,
      tableId: tableId,
      rowId: id,
    );
  }

  Future<int> pullRemoteChanges() async => 0;

  Future<void> applySyncOperation(SyncOperation operation) async {
    final tableId = tableByEntity[operation.entity];
    final database = legacy.DatabaseGetter.database;
    if (operation.companyId != companyId || tableId == null || database == null) {
      throw StateError('Opération Appwrite invalide ou service indisponible.');
    }
    switch (operation.type) {
      case SyncOperationType.create:
        await database.createRow(
          databaseId: legacy.databaseId,
          tableId: tableId,
          rowId: operation.entityId,
          data: operation.payload,
        );
        break;
      case SyncOperationType.update:
        await database.updateRow(
          databaseId: legacy.databaseId,
          tableId: tableId,
          rowId: operation.entityId,
          data: operation.payload,
        );
        break;
      case SyncOperationType.delete:
        await database.deleteRow(
          databaseId: legacy.databaseId,
          tableId: tableId,
          rowId: operation.entityId,
        );
        break;
    }
  }
}
