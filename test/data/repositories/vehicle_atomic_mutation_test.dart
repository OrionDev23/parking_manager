import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:parc_oto/core/database/local_database.dart';
import 'package:parc_oto/core/device/device_identity.dart';
import 'package:parc_oto/core/sync/sqlite_sync_queue.dart';
import 'package:parc_oto/core/sync/sync_operation.dart';
import 'package:parc_oto/core/tenancy/company_context.dart';
import 'package:parc_oto/data/local/vehicles/sqlite_vehicle_source.dart';
import 'package:parc_oto/data/repositories/vehicle_repository_impl.dart';
import 'package:parc_oto/domain/entities/vehicle.dart';

void main() {
  const companyId = 'company-test-001';
  late LocalDatabase database;
  late SqliteSyncQueue queue;
  late SqliteVehicleSource local;

  setUp(() {
    database = LocalDatabase.inMemoryForTesting();
    queue = SqliteSyncQueue(database);
    local = SqliteVehicleSource(database, companyId: companyId);
  });

  tearDown(() async {
    await database.close();
  });

  Vehicle vehicle({
    String id = 'vehicle-test-001',
    String registration = '12345-123-23',
  }) {
    final now = DateTime.utc(2026, 11, 22);
    return Vehicle(
      id: id,
      companyId: companyId,
      registration: registration,
      foreignRegistration: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  SyncOperation operation(
    Vehicle value,
    SyncOperationType type, {
    String? operationId,
  }) {
    return SyncOperation(
      id: operationId ?? 'device-${value.id}-${type.name}',
      companyId: value.companyId,
      deviceId: 'device-test',
      entity: 'vehicle',
      entityId: value.id,
      type: type,
      payload: value.toMap(),
      createdAt: DateTime.utc(2026, 11, 22),
    );
  }

  group('atomic vehicle cache and outbox mutations', () {
    test('upgrades an existing v11 outbox without losing pending work', () {
      final legacyDatabase = sqlite3.openInMemory();
      try {
        legacyDatabase.execute(
          'CREATE TABLE schema_migrations '
          '(version INTEGER PRIMARY KEY, applied_at TEXT NOT NULL)',
        );
        legacyDatabase.execute(
          "INSERT INTO schema_migrations(version, applied_at) "
          "VALUES (11, '2026-11-21T00:00:00.000Z')",
        );
        legacyDatabase.execute('''CREATE TABLE sync_operations (
          id TEXT PRIMARY KEY,
          company_id TEXT NOT NULL,
          device_id TEXT NOT NULL,
          entity TEXT NOT NULL,
          entity_id TEXT NOT NULL,
          operation TEXT NOT NULL,
          payload TEXT NOT NULL,
          created_at TEXT NOT NULL,
          status TEXT NOT NULL,
          attempts INTEGER NOT NULL DEFAULT 0,
          conflict_reason TEXT,
          conflicted_at TEXT
        )''');
        legacyDatabase.execute('''CREATE TABLE vehicles (
          id TEXT PRIMARY KEY, company_id TEXT NOT NULL, site_id TEXT,
          registration TEXT NOT NULL, brand TEXT, model TEXT, color TEXT,
          status TEXT NOT NULL, created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL, payload TEXT
        )''');
        legacyDatabase.execute('''CREATE TABLE drivers (
          id TEXT PRIMARY KEY, company_id TEXT NOT NULL, site_id TEXT,
          first_name TEXT NOT NULL DEFAULT '', last_name TEXT NOT NULL DEFAULT '',
          registration TEXT NOT NULL DEFAULT '', email TEXT, phone TEXT,
          state INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL, payload TEXT NOT NULL DEFAULT '{}'
        )''');
        legacyDatabase.execute(
          '''INSERT INTO sync_operations
             (id, company_id, device_id, entity, entity_id, operation,
              payload, created_at, status, attempts)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
          [
            'legacy-operation-001',
            companyId,
            'legacy-device',
            'vehicle',
            'vehicle-legacy-001',
            'create',
            '{"id":"vehicle-legacy-001","companyId":"company-test-001"}',
            '2026-11-21T00:00:00.000Z',
            'pending',
            2,
          ],
        );

        LocalDatabase.migrateForTesting(legacyDatabase);

        final row = legacyDatabase
            .select(
              "SELECT * FROM sync_operations WHERE id='legacy-operation-001'",
            )
            .single;
        final version = legacyDatabase
            .select('SELECT MAX(version) AS version FROM schema_migrations')
            .single['version'];

        expect(version, 19);
        expect(row['id'], 'legacy-operation-001');
        expect(row['company_id'], companyId);
        expect(row['entity_id'], 'vehicle-legacy-001');
        expect(row['status'], 'pending');
        expect(row['attempts'], 2);
        expect(
          row['payload'],
          '{"id":"vehicle-legacy-001","companyId":"company-test-001"}',
        );
        expect(row['idempotency_key'], 'legacy-operation-001');
        expect(row['payload_version'], 1);
        final localTables = legacyDatabase.select(
          "SELECT name FROM sqlite_master WHERE type='table'",
        ).map((item) => item['name'] as String).toSet();
        final eventColumns = legacyDatabase
            .select('PRAGMA table_info(parking_access_events)')
            .map((row) => row['name'] as String)
            .toSet();
        expect(eventColumns, contains('assignment_id'));
        final assignmentIndexes = legacyDatabase
            .select("PRAGMA index_list('vehicle_parking_assignments')")
            .map((row) => row['name'] as String)
            .toSet();
        expect(
          assignmentIndexes,
          containsAll({
            'idx_parking_assignment_space_window',
            'idx_parking_assignment_vehicle_window',
          }),
        );
        expect(assignmentIndexes, isNot(contains('ux_parking_active_space')));
        expect(assignmentIndexes, isNot(contains('ux_parking_active_vehicle')));
        final mediaColumns = legacyDatabase
            .select('PRAGMA table_info(parking_media)')
            .map((row) => row['name'] as String)
            .toSet();
        expect(
          mediaColumns,
          containsAll({'pixel_width', 'pixel_height'}),
        );
        expect(
          localTables,
          containsAll({
            'sites',
            'vehicle_assignments',
            'parking_lots',
            'parking_layouts',
            'parking_zones',
            'parking_spaces',
            'vehicle_parking_assignments',
            'parking_access_events',
            'parking_media',
          }),
        );
      } finally {
        legacyDatabase.close();
      }
    });

    test('opens with the version 19 parking schema and ordered outbox', () async {
      final migrations = database.database.select(
        'SELECT version FROM schema_migrations ORDER BY version',
      );
      final latestVersion = migrations.last['version'] as int;
      final columns = database.database
          .select('PRAGMA table_info(sync_operations)')
          .map((row) => row['name'] as String)
          .toSet();

      expect(latestVersion, 19);
      expect(
        columns,
        containsAll({
          'payload_version',
          'idempotency_key',
          'next_attempt_at',
          'last_error_code',
          'last_error_message',
          'completed_at',
          'base_revision',
          'depends_on_operation_id',
          'sequence_no',
        }),
      );
    });


    test('releases dependent operations only after the parent is completed', () async {
      final parent = SyncOperation(
        id: 'site-create-op',
        companyId: companyId,
        deviceId: 'device-test',
        entity: 'site',
        entityId: 'site-001',
        type: SyncOperationType.create,
        payload: {'id': 'site-001', 'companyId': companyId},
        createdAt: DateTime.utc(2026, 11, 22),
      );
      final child = SyncOperation(
        id: 'parking-create-op',
        companyId: companyId,
        deviceId: 'device-test',
        entity: 'parking_lot',
        entityId: 'parking-001',
        type: SyncOperationType.create,
        dependsOnOperationId: parent.id,
        payload: {'id': 'parking-001', 'companyId': companyId},
        createdAt: DateTime.utc(2026, 11, 22),
      );

      await queue.enqueue(parent);
      await queue.enqueue(child);

      final readyBeforeAck = await queue.pending(companyId: companyId);
      expect(readyBeforeAck.map((item) => item.id), [parent.id]);
      final storedChild = database.database
          .select(
            "SELECT sequence_no, depends_on_operation_id FROM sync_operations WHERE id=?",
            [child.id],
          )
          .single;
      expect(storedChild['sequence_no'], 2);
      expect(storedChild['depends_on_operation_id'], parent.id);

      await queue.markConflict(parent.id, reason: 'Parent validation failed.');
      await queue.pending(companyId: companyId);
      final blockedChild = (await queue.conflicts(companyId: companyId))
          .singleWhere((item) => item.id == child.id);
      expect(blockedChild.conflictReason, 'dependency_blocked');

      await queue.retryConflict(parent.id);
      final readyAfterRetry = await queue.pending(companyId: companyId);
      expect(readyAfterRetry.map((item) => item.id), [parent.id]);

      await queue.markCompleted(parent.id);
      final readyAfterAck = await queue.pending(companyId: companyId);
      expect(readyAfterAck.map((item) => item.id), [child.id]);
    });

    test('enforces tenant parentage and single active parking occupancy', () {
      final db = database.database;
      const now = '2026-11-22T10:00:00.000Z';

      db.execute(
        """INSERT INTO sites
           (id, company_id, code, name, status, created_at, updated_at)
           VALUES ('site-a', ?, 'A', 'Site A', 'active', ?, ?)""",
        [companyId, now, now],
      );
      db.execute(
        """INSERT INTO parking_lots
           (id, company_id, site_id, code, name, created_at, updated_at)
           VALUES ('lot-a', ?, 'site-a', 'P1', 'Parking principal', ?, ?)""",
        [companyId, now, now],
      );
      db.execute(
        """INSERT INTO parking_zones
           (id, company_id, parking_lot_id, code, name, created_at, updated_at)
           VALUES ('zone-a', ?, 'lot-a', 'A', 'Zone A', ?, ?)""",
        [companyId, now, now],
      );
      db.execute(
        """INSERT INTO parking_spaces
           (id, company_id, parking_zone_id, code, x_m, y_m, width_m,
            length_m, created_at, updated_at)
           VALUES ('space-a', ?, 'zone-a', 'A-01', 1, 1, 2.5, 5, ?, ?)""",
        [companyId, now, now],
      );
      db.execute(
        """INSERT INTO parking_spaces
           (id, company_id, parking_zone_id, code, x_m, y_m, width_m,
            length_m, created_at, updated_at)
           VALUES ('space-b', ?, 'zone-a', 'A-02', 4, 1, 2.5, 5, ?, ?)""",
        [companyId, now, now],
      );
      db.execute(
        """INSERT INTO vehicles
           (id, company_id, registration, status, created_at, updated_at, payload)
           VALUES ('vehicle-a', ?, '11111-111-11', 'active', ?, ?, '{}')""",
        [companyId, now, now],
      );
      db.execute(
        """INSERT INTO vehicles
           (id, company_id, registration, status, created_at, updated_at, payload)
           VALUES ('vehicle-b', ?, '22222-222-22', 'active', ?, ?, '{}')""",
        [companyId, now, now],
      );

      db.execute(
        """INSERT INTO vehicle_parking_assignments
           (id, company_id, vehicle_id, parking_space_id, status, start_at,
            created_at, updated_at)
           VALUES ('assignment-a', ?, 'vehicle-a', 'space-a', 'active', ?, ?, ?)""",
        [companyId, now, now, now],
      );

      // A future reservation may share the current space/vehicle only
      // when the interval policy confirms that the time windows do not overlap.
      db.execute(
        """INSERT INTO vehicle_parking_assignments
           (id, company_id, vehicle_id, parking_space_id, assignment_type,
            status, start_at, end_at, created_at, updated_at)
           VALUES ('reservation-a', ?, 'vehicle-a', 'space-a', 'reserved',
                   'active', '2026-11-23T10:00:00.000Z',
                   '2026-11-23T12:00:00.000Z', ?, ?)""",
        [companyId, now, now],
      );

      expect(
        () => db.execute(
          """INSERT INTO vehicle_parking_assignments
             (id, company_id, vehicle_id, parking_space_id, status, start_at,
              created_at, updated_at)
             VALUES ('assignment-b', ?, 'vehicle-b', 'space-a', 'active', ?, ?, ?)""",
          [companyId, now, now, now],
        ),
        throwsA(isA<SqliteException>()),
      );
      expect(
        () => db.execute(
          """INSERT INTO vehicle_parking_assignments
             (id, company_id, vehicle_id, parking_space_id, status, start_at,
              created_at, updated_at)
             VALUES ('assignment-c', ?, 'vehicle-a', 'space-b', 'active', ?, ?, ?)""",
          [companyId, now, now, now],
        ),
        throwsA(isA<SqliteException>()),
      );
      expect(
        () => db.execute(
          """INSERT INTO parking_lots
             (id, company_id, site_id, code, name, created_at, updated_at)
             VALUES ('lot-cross-tenant', 'company-other', 'site-a', 'P2', 'Invalid', ?, ?)""",
          [now, now],
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('commits the vehicle row and outbox operation together', () async {
      final value = vehicle();

      final repository = VehicleRepositoryImpl(
        local: local,
        atomicSyncQueue: queue,
        deviceIdentity: PersistentDeviceIdentity(
          idFactory: () => 'device-test',
        ),
        companyContext: const CompanyContext(companyId: companyId),
      );

      await repository.createVehicle(value);

      final cached = await local.getVehicle(value.id);
      final pending = await queue.pending(companyId: companyId);

      expect(cached, isNotNull);
      expect(cached!.registration, value.registration);
      expect(pending, hasLength(1));
      expect(pending.single.entityId, value.id);
      expect(pending.single.type, SyncOperationType.create);
      expect(pending.single.idempotencyKey, pending.single.id);
      expect(pending.single.payloadVersion, 1);
    });

    test('refuses to reassign an existing local vehicle ID to another tenant', () async {
      final original = vehicle();
      await local.upsertVehicle(original);

      final otherTenantSource = SqliteVehicleSource(
        database,
        companyId: 'company-other-001',
      );
      final attemptedTransfer = Vehicle(
        id: original.id,
        companyId: 'company-other-001',
        registration: '99999-999-99',
        foreignRegistration: false,
        createdAt: original.createdAt,
        updatedAt: original.updatedAt,
      );

      expect(
        () => otherTenantSource.upsertVehicleInTransaction(attemptedTransfer),
        throwsA(isA<StateError>()),
      );
      expect((await local.getVehicle(original.id))?.companyId, companyId);
      expect(await otherTenantSource.getVehicle(original.id), isNull);
    });

    test('rolls back both writes when the local mutation fails', () async {
      final value = vehicle();

      await expectLater(
        queue.enqueueWithLocalMutation(
          operation(value, SyncOperationType.create),
          localMutation: () {
            local.upsertVehicleInTransaction(value);
            throw StateError('simulated local write failure');
          },
        ),
        throwsA(isA<StateError>()),
      );

      expect(await local.getVehicle(value.id), isNull);
      expect(await queue.pending(companyId: companyId), isEmpty);
    });

    test('defers failed operations until their retry deadline', () async {
      final value = vehicle();
      final now = DateTime.now().toUtc();
      await queue.enqueueWithLocalMutation(
        operation(value, SyncOperationType.create),
        localMutation: () => local.upsertVehicleInTransaction(value),
      );

      await queue.markFailed(
        'device-${value.id}-create',
        errorCode: 'temporary_network_error',
        errorMessage: 'Connection temporarily unavailable.',
        nextAttemptAt: now.add(const Duration(minutes: 5)),
      );

      final failedRow = database.database
          .select(
            "SELECT * FROM sync_operations WHERE id='device-${value.id}-create'",
          )
          .single;
      expect(failedRow['attempts'], 1);
      expect(failedRow['last_error_code'], 'temporary_network_error');
      expect(
        failedRow['last_error_message'],
        'Connection temporarily unavailable.',
      );
      expect(failedRow['next_attempt_at'], isNotNull);
      expect(await queue.pending(companyId: companyId), isEmpty);

      database.database.execute(
        "UPDATE sync_operations SET next_attempt_at=? WHERE id=?",
        [
          now.subtract(const Duration(seconds: 1)).toIso8601String(),
          'device-${value.id}-create',
        ],
      );

      expect(await queue.pending(companyId: companyId), hasLength(1));
    });

    test('coalesces create then update without losing create semantics', () async {
      final created = vehicle();
      final updated = vehicle(registration: '54321-123-23');

      await queue.enqueueWithLocalMutation(
        operation(
          created,
          SyncOperationType.create,
          operationId: 'create-operation',
        ),
        localMutation: () => local.upsertVehicleInTransaction(created),
      );

      await queue.enqueueWithLocalMutation(
        operation(
          updated,
          SyncOperationType.update,
          operationId: 'update-operation',
        ),
        localMutation: () => local.upsertVehicleInTransaction(updated),
      );

      final cached = await local.getVehicle(created.id);
      final pending = await queue.pending(companyId: companyId);

      expect(cached?.registration, updated.registration);
      expect(pending, hasLength(1));
      expect(pending.single.id, 'create-operation');
      expect(pending.single.type, SyncOperationType.create);
      expect(pending.single.payload['registration'], updated.registration);
    });

    test('create then delete removes both pending row and local vehicle', () async {
      final value = vehicle();

      await queue.enqueueWithLocalMutation(
        operation(value, SyncOperationType.create),
        localMutation: () => local.upsertVehicleInTransaction(value),
      );

      final delete = SyncOperation(
        id: 'delete-operation',
        companyId: companyId,
        deviceId: 'device-test',
        entity: 'vehicle',
        entityId: value.id,
        type: SyncOperationType.delete,
        payload: {'id': value.id, 'companyId': companyId},
        createdAt: DateTime.utc(2026, 11, 22, 1),
      );

      await queue.enqueueWithLocalMutation(
        delete,
        localMutation: () => local.deleteVehicleInTransaction(value.id),
      );

      expect(await local.getVehicle(value.id), isNull);
      expect(await queue.pending(companyId: companyId), isEmpty);
    });
  });
}
