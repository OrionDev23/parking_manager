import 'dart:convert';

import '../../core/device/device_identity.dart';
import '../../core/sync/sync_operation.dart';
import '../../core/sync/sync_queue.dart';
import '../../core/tenancy/company_context.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/repository_exception.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../local/vehicles/local_vehicle_source.dart';
import '../remote/vehicles/remote_vehicle_source.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  final LocalVehicleSource local;
  final RemoteVehicleSource? remote;
  final SyncQueue syncQueue;
  final DeviceIdentity deviceIdentity;
  final CompanyContext companyContext;

  VehicleRepositoryImpl({
    required this.local,
    required this.syncQueue,
    required this.deviceIdentity,
    required this.companyContext,
    this.remote,
  });

  @override
  Future<List<Vehicle>> getVehicles({
    String? search,
    int? limit,
    int offset = 0,
  }) async {
    final cached = await local.getVehicles(
      search: search,
      limit: limit,
      offset: offset,
    );
    if (cached.isNotEmpty || remote == null) return cached;

    // First online read hydrates SQLite. A remote failure must never prevent
    // the user from continuing with whatever data is already stored locally.
    try {
      final remoteVehicles = await remote!.getVehicles(
        search: search,
        limit: limit,
        offset: offset,
      );
      final safeVehicles = remoteVehicles
          .where((vehicle) => vehicle.companyId == companyContext.companyId)
          .toList(growable: false);
      for (final vehicle in safeVehicles) {
        await local.upsertVehicle(vehicle);
      }
      return safeVehicles;
    } catch (_) {
      return cached;
    }
  }

  @override
  Future<Vehicle?> getVehicle(String id) async {
    final cached = await local.getVehicle(id);
    if (cached != null || remote == null) return cached;

    try {
      final vehicle = await remote!.getVehicle(id);
      if (vehicle == null || vehicle.companyId != companyContext.companyId) {
        return null;
      }
      await local.upsertVehicle(vehicle);
      return vehicle;
    } catch (_) {
      // Offline or remote error: there is no cached record for this ID.
      return null;
    }
  }

  @override
  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    _checkCompany(vehicle);
    await local.upsertVehicle(vehicle);
    await _enqueue(vehicle, SyncOperationType.create);
    return vehicle;
  }

  @override
  Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    _checkCompany(vehicle);
    await local.upsertVehicle(vehicle);
    await _enqueue(vehicle, SyncOperationType.update);
    return vehicle;
  }

  @override
  Future<void> deleteVehicle(String id) async {
    final existing = await local.getVehicle(id);
    if (existing == null) return;
    _checkCompany(existing);

    // Queue the tombstone before deleting the local row. If queue persistence
    // fails, retain the record rather than silently losing the pending change.
    final deviceId = await deviceIdentity.getDeviceId();
    await syncQueue.enqueue(
      SyncOperation(
        id: '${deviceId}_${id}_${DateTime.now().microsecondsSinceEpoch}',
        companyId: companyContext.companyId,
        deviceId: deviceId,
        entity: 'vehicle',
        entityId: id,
        type: SyncOperationType.delete,
        payload: {'id': id, 'companyId': existing.companyId},
        createdAt: DateTime.now().toUtc(),
      ),
    );
    await local.deleteVehicle(id);
  }

  void _checkCompany(Vehicle vehicle) {
    if (vehicle.companyId != companyContext.companyId) {
      throw const RepositoryException(
        'Vehicle company does not match the active company.',
      );
    }
  }

  Future<void> _enqueue(Vehicle vehicle, SyncOperationType type) async {
    final deviceId = await deviceIdentity.getDeviceId();
    await syncQueue.enqueue(
      SyncOperation(
        id: '${deviceId}_${vehicle.id}_${DateTime.now().microsecondsSinceEpoch}',
        companyId: vehicle.companyId,
        deviceId: deviceId,
        entity: 'vehicle',
        entityId: vehicle.id,
        type: type,
        payload: jsonDecode(jsonEncode(vehicle.toMap())) as Map<String, dynamic>,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }
}
