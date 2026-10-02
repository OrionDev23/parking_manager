import 'dart:convert';
import 'package:sqlite3/sqlite3.dart';
import 'sync_operation.dart';
import '../database/local_database.dart';
import 'sync_queue.dart';

class SqliteSyncQueue implements SyncQueue {
  final LocalDatabase localDatabase;
  SqliteSyncQueue(this.localDatabase);
  Database get _db => localDatabase.database;

  String _type(SyncOperationType value) => value.name;
  SyncOperationStatus _status(String value) => SyncOperationStatus.values.firstWhere((e) => e.name == value, orElse: () => SyncOperationStatus.pending);

  SyncOperation _fromRow(Row row) => SyncOperation(
    id: row['id'] as String, companyId: row['company_id'] as String, deviceId: row['device_id'] as String,
    entity: row['entity'] as String, entityId: row['entity_id'] as String,
    type: SyncOperationType.values.firstWhere((e) => e.name == row['operation'], orElse: () => SyncOperationType.update),
    payload: Map<String, dynamic>.from(jsonDecode(row['payload'] as String) as Map),
    createdAt: DateTime.parse(row['created_at'] as String), status: _status(row['status'] as String), attempts: row['attempts'] as int);

  @override
  Future<void> enqueue(SyncOperation operation) async {
    _db.execute('''INSERT INTO sync_operations
      (id, company_id, device_id, entity, entity_id, operation, payload, created_at, status, attempts)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO NOTHING''', [operation.id, operation.companyId, operation.deviceId, operation.entity,
      operation.entityId, _type(operation.type), jsonEncode(operation.payload), operation.createdAt.toIso8601String(),
      _status(operation.status).name, operation.attempts]);
  }

  @override
  Future<List<SyncOperation>> pending({int limit = 50}) async => _db
      .select("SELECT * FROM sync_operations WHERE status IN ('pending','failed') ORDER BY created_at LIMIT ?", [limit])
      .map(_fromRow).toList(growable: false);

  @override
  Future<void> markCompleted(String operationId) async => _db.execute("UPDATE sync_operations SET status='completed' WHERE id=?", [operationId]);
  @override
  Future<void> markFailed(String operationId) async => _db.execute("UPDATE sync_operations SET status='failed', attempts=attempts+1 WHERE id=?", [operationId]);
  @override
  Future<void> markConflict(String operationId) async => _db.execute("UPDATE sync_operations SET status='conflict' WHERE id=?", [operationId]);
}
