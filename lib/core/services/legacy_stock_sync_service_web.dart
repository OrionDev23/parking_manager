import 'package:appwrite/appwrite.dart';

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
    this.teamId,
  });

  final String companyId;
  final String? teamId;

  bool _isTenantScoped(String entity) => tableByEntity.containsKey(entity);

  List<String> _rowPermissions() {
    final id = teamId;
    if (id == null || id.isEmpty) {
      throw StateError('The active company has no Appwrite team context.');
    }
    return [
      Permission.read(Role.team(id)),
      Permission.update(Role.team(id, 'admin')),
      Permission.update(Role.team(id, 'manager')),
      Permission.delete(Role.team(id, 'admin')),
    ];
  }

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
    final tenantScoped = _isTenantScoped(entity);
    final rowData = tenantScoped ? {...data, 'companyId': companyId} : data;
    if (isNew) {
      await database.createRow(
        databaseId: legacy.databaseId,
        tableId: tableId,
        rowId: id,
        data: rowData,
        permissions: tenantScoped ? _rowPermissions() : null,
      );
    } else {
      if (tenantScoped) {
        final existing = await database.getRow(
          databaseId: legacy.databaseId,
          tableId: tableId,
          rowId: id,
        );
        if (existing.data['companyId'] != companyId) {
          throw StateError('Stock row belongs to another company.');
        }
      }
      await database.updateRow(
        databaseId: legacy.databaseId,
        tableId: tableId,
        rowId: id,
        data: rowData,
        permissions: tenantScoped ? _rowPermissions() : null,
      );
    }
  }

  Future<void> delete({required String entity, required String id}) async {
    final tableId = tableByEntity[entity];
    final database = legacy.DatabaseGetter.database;
    if (tableId == null || database == null) {
      throw StateError('Service Appwrite indisponible.');
    }
    if (_isTenantScoped(entity)) {
      final existing = await database.getRow(
        databaseId: legacy.databaseId,
        tableId: tableId,
        rowId: id,
      );
      if (existing.data['companyId'] != companyId) {
        throw StateError('Stock row belongs to another company.');
      }
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
          permissions: _isTenantScoped(operation.entity) ? _rowPermissions() : null,
        );
        break;
      case SyncOperationType.update:
        if (_isTenantScoped(operation.entity)) {
          final existing = await database.getRow(
            databaseId: legacy.databaseId,
            tableId: tableId,
            rowId: operation.entityId,
          );
          if (existing.data['companyId'] != companyId) {
            throw StateError('Stock row belongs to another company.');
          }
        }
        await database.updateRow(
          databaseId: legacy.databaseId,
          tableId: tableId,
          rowId: operation.entityId,
          data: operation.payload,
          permissions: _isTenantScoped(operation.entity) ? _rowPermissions() : null,
        );
        break;
      case SyncOperationType.delete:
        if (_isTenantScoped(operation.entity)) {
          final existing = await database.getRow(
            databaseId: legacy.databaseId,
            tableId: tableId,
            rowId: operation.entityId,
          );
          if (existing.data['companyId'] != companyId) {
            throw StateError('Stock row belongs to another company.');
          }
        }
        await database.deleteRow(
          databaseId: legacy.databaseId,
          tableId: tableId,
          rowId: operation.entityId,
        );
        break;
    }
  }
}
