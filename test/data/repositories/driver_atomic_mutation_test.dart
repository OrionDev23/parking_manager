import 'package:flutter_test/flutter_test.dart';

import 'package:parc_oto/core/database/local_database.dart';
import 'package:parc_oto/core/device/device_identity.dart';
import 'package:parc_oto/core/sync/sqlite_sync_queue.dart';
import 'package:parc_oto/core/sync/sync_operation.dart';
import 'package:parc_oto/core/tenancy/company_context.dart';
import 'package:parc_oto/data/local/drivers/sqlite_driver_source.dart';
import 'package:parc_oto/data/repositories/driver_repository_impl.dart';
import 'package:parc_oto/domain/entities/driver.dart';

void main() {
  const companyId = 'company-driver-test';
  late LocalDatabase database;
  late SqliteSyncQueue queue;
  late SqliteDriverSource local;

  setUp(() {
    database = LocalDatabase.inMemoryForTesting();
    queue = SqliteSyncQueue(database);
    local = SqliteDriverSource(database, companyId: companyId);
  });

  tearDown(() async {
    await database.close();
  });

  Driver driver({
    String id = 'driver-test-001',
    String firstName = 'Amine',
  }) {
    final now = DateTime.utc(2026, 11, 22);
    return Driver(
      id: id,
      companyId: companyId,
      firstName: firstName,
      lastName: 'Test',
      registration: 'CH-001',
      createdAt: now,
      updatedAt: now,
    );
  }

  DriverRepositoryImpl repository() => DriverRepositoryImpl(
    local: local,
    atomicSyncQueue: queue,
    deviceIdentity: PersistentDeviceIdentity(
      idFactory: () => 'device-driver-test',
    ),
    companyContext: const CompanyContext(companyId: companyId),
  );

  group('atomic driver cache and outbox mutations', () {
    test('repository create commits driver and outbox together', () async {
      final value = driver();

      await repository().createDriver(value);

      final cached = await local.getDriver(value.id);
      final pending = await queue.pending(companyId: companyId);

      expect(cached, isNotNull);
      expect(cached!.firstName, value.firstName);
      expect(pending, hasLength(1));
      expect(pending.single.entity, 'driver');
      expect(pending.single.type, SyncOperationType.create);
      expect(pending.single.idempotencyKey, pending.single.id);
    });

    test('rolls back driver row and outbox when local mutation fails', () async {
      final value = driver();
      final operation = SyncOperation(
        id: 'driver-rollback-op',
        companyId: companyId,
        deviceId: 'device-driver-test',
        entity: 'driver',
        entityId: value.id,
        type: SyncOperationType.create,
        payload: value.toMap(),
        createdAt: DateTime.utc(2026, 11, 22),
      );

      await expectLater(
        queue.enqueueWithLocalMutation(
          operation,
          localMutation: () {
            local.upsertDriverInTransaction(value);
            throw StateError('simulated driver write failure');
          },
        ),
        throwsA(isA<StateError>()),
      );

      expect(await local.getDriver(value.id), isNull);
      expect(await queue.pending(companyId: companyId), isEmpty);
    });

    test('refuses to reassign an existing local driver ID to another tenant', () async {
      final original = driver();
      await local.upsertDriver(original);

      final otherTenantSource = SqliteDriverSource(
        database,
        companyId: 'company-other-driver',
      );
      final attemptedTransfer = Driver(
        id: original.id,
        companyId: 'company-other-driver',
        firstName: 'Other',
        lastName: 'Tenant',
        registration: 'CH-OTHER',
        createdAt: original.createdAt,
        updatedAt: original.updatedAt,
      );

      expect(
        () => otherTenantSource.upsertDriverInTransaction(attemptedTransfer),
        throwsA(isA<StateError>()),
      );
      expect((await local.getDriver(original.id))?.companyId, companyId);
      expect(await otherTenantSource.getDriver(original.id), isNull);
    });

    test('coalesces driver create followed by update', () async {
      final created = driver();
      final updated = driver(firstName: 'Amine Updated');

      await repository().createDriver(created);
      await repository().updateDriver(updated);

      final cached = await local.getDriver(created.id);
      final pending = await queue.pending(companyId: companyId);

      expect(cached?.firstName, 'Amine Updated');
      expect(pending, hasLength(1));
      expect(pending.single.type, SyncOperationType.create);
      expect(pending.single.payload['firstName'], 'Amine Updated');
    });

    test('create followed by delete removes local driver and pending create', () async {
      final value = driver();

      await repository().createDriver(value);
      await repository().deleteDriver(value.id);

      expect(await local.getDriver(value.id), isNull);
      expect(await queue.pending(companyId: companyId), isEmpty);
    });

    test('rejects a driver from another company before persisting it', () async {
      final wrongTenant = Driver(
        id: 'driver-other-tenant',
        companyId: 'company-other',
        firstName: 'Other',
        lastName: 'Tenant',
        registration: 'CH-OTHER',
        createdAt: DateTime.utc(2026, 11, 22),
        updatedAt: DateTime.utc(2026, 11, 22),
      );

      await expectLater(
        local.upsertDriver(wrongTenant),
        throwsA(isA<StateError>()),
      );

      expect(await local.getDriver(wrongTenant.id), isNull);
    });
  });
}
