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
  SyncOperationStatus _status(String value) => SyncOperationStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => SyncOperationStatus.pending,
  );

  SyncOperation _fromRow(Row row) => SyncOperation(
    id: row['id'] as String,
    companyId: row['company_id'] as String,
    deviceId: row['device_id'] as String,
    entity: row['entity'] as String,
    entityId: row['entity_id'] as String,
    type: SyncOperationType.values.firstWhere(
      (e) => e.name == row['operation'],
      orElse: () => SyncOperationType.update,
    ),
    payload: Map<String, dynamic>.from(jsonDecode(row['payload'] as String) as Map),
    createdAt: DateTime.parse(row['created_at'] as String),
    status: _status(row['status'] as String),
    attempts: row['attempts'] as int,
  );

  @override
  Future<void> enqueue(SyncOperation operation) async {
    // Only coalesce operations that have not started syncing. Failed
    // operations are deliberately left untouched because the remote write
    // may have succeeded before a network error was returned.
    _db.execute('BEGIN IMMEDIATE');
    try {
      final rows = _db.select(
        '''SELECT * FROM sync_operations
           WHERE company_id = ? AND entity = ? AND entity_id = ?
             AND status = 'pending'
           ORDER BY created_at DESC LIMIT 1''',
        [operation.companyId, operation.entity, operation.entityId],
      );

      if (rows.isNotEmpty) {
        final previous = _fromRow(rows.first);

        // A local create followed by a local delete never needs to reach
        // Appwrite, provided the create was still pending.
        if (previous.type == SyncOperationType.create &&
            operation.type == SyncOperationType.delete) {
          _db.execute('DELETE FROM sync_operations WHERE id = ?', [previous.id]);
          _db.execute('COMMIT');
          return;
        }

        // Keep create semantics when edits happen before the first sync.
        // Otherwise the newest operation determines whether this is an
        // update or a delete. Delete -> recreate is intentionally not merged.
        final mergedType = previous.type == SyncOperationType.create
            ? SyncOperationType.create
            : (previous.type == SyncOperationType.delete
                ? null
                : operation.type);

        if (mergedType != null) {
          _db.execute(
            '''UPDATE sync_operations
               SET operation = ?, payload = ?, device_id = ?
               WHERE id = ?''',
            [
              _type(mergedType),
              jsonEncode(operation.payload),
              operation.deviceId,
              previous.id,
            ],
          );
          _db.execute('COMMIT');
          return;
        }
      }

      _db.execute(
        '''INSERT INTO sync_operations
          (id, company_id, device_id, entity, entity_id, operation,
           payload, created_at, status, attempts)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO NOTHING''',
        [
          operation.id,
          operation.companyId,
          operation.deviceId,
          operation.entity,
          operation.entityId,
          _type(operation.type),
          jsonEncode(operation.payload),
          operation.createdAt.toIso8601String(),
          operation.status.name,
          operation.attempts,
        ],
      );
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  @override
  Future<List<SyncOperation>> pending({int limit = 50, String? companyId}) async {
    final rows = companyId == null
        ? _db.select(
            "SELECT * FROM sync_operations WHERE status IN ('pending','failed','conflict') ORDER BY created_at, rowid LIMIT ?",
            [limit],
          )
        : _db.select(
            "SELECT * FROM sync_operations WHERE status IN ('pending','failed','conflict') AND company_id = ? ORDER BY created_at, rowid LIMIT ?",
            [companyId, limit],
          );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<void> markProcessing(String operationId) async =>
      _db.execute("UPDATE sync_operations SET status='processing' WHERE id=? AND status IN ('pending','failed')", [operationId]);

  @override
  Future<void> recoverInterrupted({String? companyId}) async {
    if (companyId == null) {
      _db.execute("UPDATE sync_operations SET status='pending' WHERE status='processing'");
    } else {
      _db.execute("UPDATE sync_operations SET status='pending' WHERE status='processing' AND company_id=?", [companyId]);
    }
  }

  @override
  Future<void> markCompleted(String operationId) async =>
      _db.execute("UPDATE sync_operations SET status='completed' WHERE id=?", [operationId]);

  @override
  Future<void> markFailed(String operationId) async =>
      _db.execute("UPDATE sync_operations SET status='failed', attempts=attempts+1 WHERE id=?", [operationId]);

  @override
  Future<void> markConflict(String operationId) async =>
      _db.execute("UPDATE sync_operations SET status='conflict' WHERE id=?", [operationId]);
}
