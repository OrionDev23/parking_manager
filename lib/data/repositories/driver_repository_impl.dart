import 'dart:convert';

import '../../core/device/device_identity.dart';
import '../../core/sync/sync_operation.dart';
import '../../core/sync/sync_queue.dart';
import '../../core/tenancy/company_context.dart';
import '../../domain/entities/driver.dart';
import '../../domain/repositories/driver_repository.dart';
import '../../domain/repositories/repository_exception.dart';
import '../local/drivers/local_driver_source.dart';
import '../remote/drivers/remote_driver_source.dart';

class DriverRepositoryImpl implements DriverRepository {
  final LocalDriverSource local;
  final RemoteDriverSource? remote;
  final SyncQueue syncQueue;
  final DeviceIdentity deviceIdentity;
  final CompanyContext companyContext;

  DriverRepositoryImpl({
    required this.local,
    required this.syncQueue,
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
  }) => local.getDrivers(
    search: search,
    limit: limit,
    offset: offset,
    includeArchived: includeArchived,
  );

  @override
  Future<Driver?> getDriver(String id) => local.getDriver(id);

  @override
  Future<Driver> createDriver(Driver driver) async {
    _checkCompany(driver);
    await local.upsertDriver(driver);
    await _enqueue(driver, SyncOperationType.create);
    return driver;
  }

  @override
  Future<Driver> updateDriver(Driver driver) async {
    _checkCompany(driver);
    await local.upsertDriver(driver);
    await _enqueue(driver, SyncOperationType.update);
    return driver;
  }

  @override
  Future<void> deleteDriver(String id) async {
    final existing = await local.getDriver(id);
    if (existing == null) return;
    _checkCompany(existing);
    await local.deleteDriver(id);
    final deviceId = await deviceIdentity.getDeviceId();
    await syncQueue.enqueue(SyncOperation(
      id: '${deviceId}_${id}_${DateTime.now().microsecondsSinceEpoch}',
      companyId: companyContext.companyId,
      deviceId: deviceId,
      entity: 'driver',
      entityId: id,
      type: SyncOperationType.delete,
      payload: {'id': id, 'companyId': existing.companyId},
      createdAt: DateTime.now().toUtc(),
    ));
  }

  void _checkCompany(Driver driver) {
    if (driver.companyId != companyContext.companyId) {
      throw const RepositoryException(
        'Driver company does not match the active company.',
      );
    }
  }

  Future<void> _enqueue(Driver driver, SyncOperationType type) async {
    final deviceId = await deviceIdentity.getDeviceId();
    await syncQueue.enqueue(SyncOperation(
      id: '${deviceId}_${driver.id}_${DateTime.now().microsecondsSinceEpoch}',
      companyId: driver.companyId,
      deviceId: deviceId,
      entity: 'driver',
      entityId: driver.id,
      type: type,
      payload: jsonDecode(jsonEncode(driver.toMap())) as Map<String, dynamic>,
      createdAt: DateTime.now().toUtc(),
    ));
  }
}
