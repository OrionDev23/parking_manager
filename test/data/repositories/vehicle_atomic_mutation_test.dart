import 'package:flutter_test/flutter_test.dart';

import 'package:parc_oto/core/database/local_database.dart';
import 'package:parc_oto/core/sync/sqlite_sync_queue.dart';
import 'package:parc_oto/core/sync/sync_operation.dart';
import 'package:parc_oto/data/local/vehicles/sqlite_vehicle_source.dart';
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
    test('commits the vehicle row and outbox operation together', () async {
      final value = vehicle();

      await queue.enqueueWithLocalMutation(
        operation(value, SyncOperationType.create),
        localMutation: () => local.upsertVehicleInTransaction(value),
      );

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
