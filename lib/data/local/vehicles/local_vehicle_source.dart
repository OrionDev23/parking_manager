import '../../../domain/entities/vehicle.dart';

abstract class LocalVehicleSource {
  Future<List<Vehicle>> getVehicles({
    String? search,
    int? limit,
    int offset = 0,
  });
  Future<Vehicle?> getVehicle(String id);
  Future<void> upsertVehicle(Vehicle vehicle);

  /// Synchronous write used only inside an existing SQLite transaction.
  void upsertVehicleInTransaction(Vehicle vehicle);

  Future<void> deleteVehicle(String id);

  /// Synchronous delete used only inside an existing SQLite transaction.
  void deleteVehicleInTransaction(String id);
}
