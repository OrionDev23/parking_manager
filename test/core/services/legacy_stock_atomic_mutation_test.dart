import 'package:flutter_test/flutter_test.dart';

import 'package:parc_oto/core/database/local_database.dart';
import 'package:parc_oto/core/device/device_identity.dart';
import 'package:parc_oto/core/services/legacy_stock_sync_service.dart';
import 'package:parc_oto/core/sync/sqlite_sync_queue.dart';

void main() {
  const companyId = 'company-stock-test';
  late LocalDatabase database;
  late SqliteSyncQueue queue;
  late LegacyStockSyncService service;

  setUp(() {
    database = LocalDatabase.inMemoryForTesting();
    queue = SqliteSyncQueue(database);
    service = LegacyStockSyncService(
      localDatabase: database,
      queue: queue,
      deviceIdentity: PersistentDeviceIdentity(
        idFactory: () => 'device-stock-test',
      ),
      companyId: companyId,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('atomic legacy stock cache and outbox mutations', () {
    test('save commits the legacy cache row and outbox operation together', () async {
      await service.save(
        entity: 'part',
        id: 'part-001',
        data: {'name': 'Oil filter'},
        isNew: true,
      );

      final cached = database.readLegacyCache(
        companyId: companyId,
        entity: 'part',
      );
      final pending = await queue.pending(companyId: companyId);

      expect(cached, hasLength(1));
      expect(cached.single[r'$id'], 'part-001');
      expect(cached.single['companyId'], companyId);
      expect(pending, hasLength(1));
      expect(pending.single.entity, 'part');
      expect(pending.single.entityId, 'part-001');
    });

    test('rolls back legacy cache and outbox when cache mutation fails', () async {
      final operation = SyncOperation(
        id: 'stock-rollback-operation',
        companyId: companyId,
        deviceId: 'device-stock-test',
        entity: 'part',
        entityId: 'part-rollback',
        type: SyncOperationType.create,
        payload: {'companyId': companyId, 'name': 'Rollback part'},
        createdAt: DateTime.utc(2026, 11, 22),
      );

      await expectLater(
        queue.enqueueWithLocalMutation(
          operation,
          localMutation: () {
            database.cacheLegacyRow(
              companyId: companyId,
              entity: 'part',
              entityId: 'part-rollback',
              payload: {'name': 'Rollback part'},
            );
            throw StateError('simulated legacy cache write failure');
          },
        ),
        throwsA(isA<StateError>()),
      );

      expect(
        database.readLegacyCache(companyId: companyId, entity: 'part'),
        isEmpty,
      );
      expect(await queue.pending(companyId: companyId), isEmpty);
    });

    test('create followed by delete removes legacy cache and pending create', () async {
      await service.save(
        entity: 'part',
        id: 'part-to-delete',
        data: {'name': 'Temporary part'},
        isNew: true,
      );

      await service.delete(entity: 'part', id: 'part-to-delete');

      expect(
        database.readLegacyCache(companyId: companyId, entity: 'part'),
        isEmpty,
      );
      expect(await queue.pending(companyId: companyId), isEmpty);
    });
  });
}
