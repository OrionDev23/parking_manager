import '../entities/vehicle.dart';

abstract class VehicleRepository {
  Future<List<Vehicle>> getVehicles({String? search, int? limit, int offset = 0});
  Future<Vehicle?> getVehicle(String id);
  Future<Vehicle> createVehicle(Vehicle vehicle);
  Future<Vehicle> updateVehicle(Vehicle vehicle);
  Future<void> deleteVehicle(String id);
}
