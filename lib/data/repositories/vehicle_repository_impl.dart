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

  VehicleRepositoryImpl({required this.local, required this.syncQueue, required this.deviceIdentity, required this.companyContext, this.remote});
  @override
  Future<List<Vehicle>> getVehicles({String? search, int? limit, int offset = 0}) => local.getVehicles(search: search, limit: limit, offset: offset);
  @override
  Future<Vehicle?> getVehicle(String id) => local.getVehicle(id);

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
    await local.deleteVehicle(id);
    final deviceId = await deviceIdentity.getDeviceId();
    await syncQueue.enqueue(SyncOperation(
      id: '${deviceId}_${DateTime.now().microsecondsSinceEpoch}', companyId: companyContext.companyId,
      deviceId: deviceId, entity: 'vehicle', entityId: id, type: SyncOperationType.delete,
      payload: {'id': id}, createdAt: DateTime.now().toUtc()));
  }
  void _checkCompany(Vehicle v) { if (v.companyId != companyContext.companyId) throw const RepositoryException('Vehicle company does not match the active company.'); }

  Future<void> _enqueue(Vehicle v, SyncOperationType type) async {
    final deviceId = await deviceIdentity.getDeviceId();
    await syncQueue.enqueue(SyncOperation(
      id: '${deviceId}_${v.id}_${DateTime.now().microsecondsSinceEpoch}', companyId: v.companyId, deviceId: deviceId,
      entity: 'vehicle', entityId: v.id, type: type,
      payload: {'id': v.id, 'companyId': v.companyId, 'siteId': v.siteId, 'registration': v.registration,
        'brand': v.brand, 'model': v.model, 'color': v.color, 'status': v.status.name,
        'createdAt': v.createdAt.toIso8601String(), 'updatedAt': v.updatedAt.toIso8601String()},
      createdAt: DateTime.now().toUtc()));
  }
}
