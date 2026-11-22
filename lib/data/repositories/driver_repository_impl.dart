import 'dart:convert';

import '../../core/device/device_identity.dart';
import '../../core/sync/atomic_sync_queue.dart';
import '../../core/sync/sync_operation.dart';
import '../../core/tenancy/company_context.dart';
import '../../domain/entities/driver.dart';
import '../../domain/repositories/driver_repository.dart';
import '../../domain/repositories/repository_exception.dart';
import '../local/drivers/local_driver_source.dart';
import '../remote/drivers/remote_driver_source.dart';

class DriverRepositoryImpl implements DriverRepository {
  final LocalDriverSource local;
  final RemoteDriverSource? remote;
  final AtomicSyncQueue atomicSyncQueue;
  final DeviceIdentity deviceIdentity;
  final CompanyContext companyContext;

  DriverRepositoryImpl({
    required this.local,
    required this.atomicSyncQueue,
    required this.deviceIdentity,
    required this.companyContext,
    this.remote,
  });

  @override
  Future<List<Driver>> getDrivers({
    String? search,
    int? limit,
    int offset = 0,
    bool includeArchived = false,
  }) async {
    final localDrivers = await local.getDrivers(
      search: search,
      limit: limit,
      offset: offset,
      includeArchived: includeArchived,
    );
    if (localDrivers.isNotEmpty || remote == null) return localDrivers;

    // First online read hydrates the local cache. Later reads are local-first.
    final remoteDrivers = await remote!.getDrivers(
      search: search,
      limit: limit,
      offset: offset,
      includeArchived: includeArchived,
    );
    final safeDrivers = remoteDrivers
        .where((driver) => driver.companyId == companyContext.companyId)
        .toList(growable: false);
    for (final driver in safeDrivers) {
      await local.upsertDriver(driver);
    }
    return safeDrivers;
  }

  @override
  Future<Driver?> getDriver(String id) => local.getDriver(id);

  @override
  Future<Driver> createDriver(Driver driver) async {
    _checkCompany(driver);
    final operation = await _operation(driver, SyncOperationType.create);
    await atomicSyncQueue.enqueueWithLocalMutation(
      operation,
      localMutation: () => local.upsertDriverInTransaction(driver),
    );
    return driver;
  }

  @override
  Future<Driver> updateDriver(Driver driver) async {
    _checkCompany(driver);
    final operation = await _operation(driver, SyncOperationType.update);
    await atomicSyncQueue.enqueueWithLocalMutation(
      operation,
      localMutation: () => local.upsertDriverInTransaction(driver),
    );
    return driver;
  }

  @override
  Future<void> deleteDriver(String id) async {
    final existing = await local.getDriver(id);
    if (existing == null) return;
    _checkCompany(existing);
    final deviceId = await deviceIdentity.getDeviceId();
    await atomicSyncQueue.enqueueWithLocalMutation(
      SyncOperation(
        id: '${deviceId}_${id}_${DateTime.now().microsecondsSinceEpoch}',
        companyId: companyContext.companyId,
        deviceId: deviceId,
        entity: 'driver',
        entityId: id,
        type: SyncOperationType.delete,
        payload: {'id': id, 'companyId': existing.companyId},
        createdAt: DateTime.now().toUtc(),
      ),
      localMutation: () => local.deleteDriverInTransaction(id),
    );
  }

  void _checkCompany(Driver driver) {
    if (driver.companyId != companyContext.companyId) {
      throw const RepositoryException(
        'Driver company does not match the active company.',
      );
    }
  }

  Future<SyncOperation> _operation(
    Driver driver,
    SyncOperationType type,
  ) async {
    final deviceId = await deviceIdentity.getDeviceId();
    return SyncOperation(
      id: '${deviceId}_${driver.id}_${DateTime.now().microsecondsSinceEpoch}',
      companyId: driver.companyId,
      deviceId: deviceId,
      entity: 'driver',
      entityId: driver.id,
      type: type,
      payload: jsonDecode(jsonEncode(driver.toMap())) as Map<String, dynamic>,
      createdAt: DateTime.now().toUtc(),
    );
  }
}
