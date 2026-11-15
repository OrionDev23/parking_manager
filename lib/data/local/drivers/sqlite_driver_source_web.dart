import '../../../domain/entities/driver.dart';
import 'local_driver_source.dart';

/// No local driver cache on Web: every read goes to Appwrite.
class SqliteDriverSource implements LocalDriverSource {
  SqliteDriverSource(dynamic _, {required this.companyId});
  final String companyId;
  @override
  Future<List<Driver>> getDrivers({
    String? search,
    int? limit,
    int offset = 0,
    bool includeArchived = false,
  }) async => [];
  @override
  Future<Driver?> getDriver(String id) async => null;
  @override
  Future<void> upsertDriver(Driver driver) async {}
  @override
  Future<void> deleteDriver(String id) async {}
}
