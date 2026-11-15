import '../../../domain/entities/vehicle.dart';
import 'local_vehicle_source.dart';

/// No local vehicle cache on Web: every read goes to Appwrite.
class SqliteVehicleSource implements LocalVehicleSource {
  SqliteVehicleSource(dynamic _, {required this.companyId});
  final String companyId;
  @override
  Future<List<Vehicle>> getVehicles({String? search, int? limit, int offset = 0}) async => [];
  @override
  Future<Vehicle?> getVehicle(String id) async => null;
  @override
  Future<void> upsertVehicle(Vehicle vehicle) async {}
  @override
  Future<void> deleteVehicle(String id) async {}
}
