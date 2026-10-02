import '../entities/driver.dart';

abstract class DriverRepository {
  Future<List<Driver>> getDrivers({
    String? search, int? limit, int offset = 0, bool includeArchived = false,
  });
  Future<Driver?> getDriver(String id);
  Future<Driver> createDriver(Driver driver);
  Future<Driver> updateDriver(Driver driver);
  Future<void> deleteDriver(String id);
}
