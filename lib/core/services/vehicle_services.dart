import 'package:shared_preferences/shared_preferences.dart';

import '../database/local_database.dart';
import '../device/shared_preferences_device_identity.dart';
import '../sync/sqlite_sync_queue.dart';
import '../../data/local/vehicles/sqlite_vehicle_source.dart';
import '../../data/repositories/vehicle_repository_impl.dart';
import '../../domain/entities/vehicle.dart' as domain;
import '../../domain/repositories/vehicle_repository.dart';
import '../tenancy/company_context.dart';

class VehicleServices {
  final LocalDatabase localDatabase;
  final VehicleRepository repository;
  final SqliteVehicleSource localSource;

  VehicleServices._({
    required this.localDatabase,
    required this.repository,
    required this.localSource,
  });

  static Future<VehicleServices> create({
    required SharedPreferences preferences,
    required String companyId,
  }) async {
    final localDatabase = LocalDatabase();
    await localDatabase.open();

    final deviceIdentity = SharedPreferencesDeviceIdentity(
      Future.value(preferences),
      idFactory: () =>
          'desktop_${DateTime.now().microsecondsSinceEpoch}',
    );
    final syncQueue = SqliteSyncQueue(localDatabase);
    final localSource = SqliteVehicleSource(localDatabase);

    return VehicleServices._(
      localDatabase: localDatabase,
      localSource: localSource,
      repository: VehicleRepositoryImpl(
        local: localSource,
        syncQueue: syncQueue,
        deviceIdentity: deviceIdentity,
        companyContext: CompanyContext(companyId: companyId),
      ),
    );
  }

  Future<void> seedLocal(domain.Vehicle vehicle) => localSource.upsertVehicle(vehicle);

  Future<void> dispose() => localDatabase.close();
}
