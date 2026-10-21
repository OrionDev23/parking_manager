import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/vehicles/sqlite_vehicle_source.dart';
import '../../data/remote/vehicles/appwrite_vehicle_source.dart';
import '../../data/repositories/vehicle_repository_impl.dart';
import '../../domain/entities/vehicle.dart' as domain;
import '../../domain/repositories/vehicle_repository.dart';
import '../backend/appwrite_backend.dart';
import '../backend/backend_config.dart';
import '../backend/backend_type.dart';
import '../database/local_database.dart';
import '../device/shared_preferences_device_identity.dart';
import '../sync/sqlite_sync_queue.dart';
import '../tenancy/company_context.dart';
import '../../providers/client_database.dart' show databaseId, vehiculeid, endpoint;

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
    final localSource = SqliteVehicleSource(
      localDatabase,
      companyId: companyId,
    );

    // Constructing the client is offline-safe; requests are made only when a
    // repository read needs to hydrate an empty local cache.
    final backend = AppwriteBackend(
      BackendConfig(
        type: BackendType.appwrite,
        endpoint: endpoint,
        projectId: preferences.getString('project') ?? 'essais',
      ),
    );
    await backend.initialize();
    final remoteSource = AppwriteVehicleSource(
      backend: backend,
      companyContext: CompanyContext(companyId: companyId),
      databaseId: databaseId,
      tableId: vehiculeid,
    );

    return VehicleServices._(
      localDatabase: localDatabase,
      localSource: localSource,
      repository: VehicleRepositoryImpl(
        local: localSource,
        syncQueue: syncQueue,
        deviceIdentity: deviceIdentity,
        companyContext: CompanyContext(companyId: companyId),
        remote: remoteSource,
      ),
    );
  }

  Future<void> seedLocal(domain.Vehicle vehicle) =>
      localSource.upsertVehicle(vehicle);

  Future<void> dispose() => localDatabase.close();
}
