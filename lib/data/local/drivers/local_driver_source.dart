import '../../../domain/entities/driver.dart';

abstract class LocalDriverSource {
  Future<List<Driver>> getDrivers({
    String? search, int? limit, int offset = 0, bool includeArchived = false,
  });
  Future<Driver?> getDriver(String id);
  Future<void> upsertDriver(Driver driver);
  Future<void> deleteDriver(String id);
}
