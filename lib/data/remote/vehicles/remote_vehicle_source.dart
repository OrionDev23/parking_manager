import '../../../domain/entities/vehicle.dart';

abstract class RemoteVehicleSource {
  Future<List<Vehicle>> getVehicles({String? search, int? limit, int offset = 0});
  Future<Vehicle?> getVehicle(String id);
  Future<List<Vehicle>> getVehiclesUpdatedSince(DateTime since, {int limit = 100, int offset = 0});
  Future<Vehicle> createVehicle(Vehicle vehicle);
  Future<Vehicle> updateVehicle(Vehicle vehicle);
  Future<void> deleteVehicle(String id);
}
