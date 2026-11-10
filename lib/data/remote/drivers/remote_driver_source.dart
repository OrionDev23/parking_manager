import '../../../domain/entities/driver.dart';

abstract class RemoteDriverSource {
  Future<List<Driver>> getDrivers({
    String? search, int? limit, int offset = 0, bool includeArchived = false,
  });
  Future<Driver?> getDriver(String id);
  Future<List<Driver>> getDriversUpdatedSince(DateTime since, {int limit = 100, int offset = 0});
  Future<Driver> createDriver(Driver driver);
  Future<Driver> updateDriver(Driver driver);
  Future<void> deleteDriver(String id);
}
