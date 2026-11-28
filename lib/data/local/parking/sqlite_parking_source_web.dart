import '../../../domain/parking/parking_models.dart';
import 'local_parking_source.dart';

/// Parking has no Appwrite remote implementation yet. Web remains online-only;
/// do not simulate a successful write or keep data in an in-memory fake.
class SqliteParkingSource implements LocalParkingSource {
  SqliteParkingSource(dynamic _, {required this.companyId});

  final String companyId;

  UnsupportedError _unsupported() => UnsupportedError(
        'Parking storage is not available on Parcoto Web until the remote '
        'Parking tables and API handlers are provisioned.',
      );

  @override
  Future<List<ParkingSite>> getSites() async => throw _unsupported();
  @override
  Future<ParkingSite?> getSite(String id) async => throw _unsupported();
  @override
  Future<void> upsertSite(ParkingSite site) async => throw _unsupported();

  @override
  Future<List<ParkingLot>> getParkingLots({String? siteId}) async =>
      throw _unsupported();
  @override
  Future<ParkingLot?> getParkingLot(String id) async => throw _unsupported();
  @override
  Future<void> upsertParkingLot(ParkingLot parkingLot) async =>
      throw _unsupported();

  @override
  Future<List<ParkingLayout>> getLayouts(String parkingLotId) async =>
      throw _unsupported();
  @override
  Future<ParkingLayout?> getLayout(String id) async => throw _unsupported();
  @override
  Future<void> upsertLayout(ParkingLayout layout) async =>
      throw _unsupported();

  @override
  Future<List<ParkingZone>> getZones(String parkingLotId) async =>
      throw _unsupported();
  @override
  Future<ParkingZone?> getZone(String id) async => throw _unsupported();
  @override
  Future<void> upsertZone(ParkingZone zone) async => throw _unsupported();

  @override
  Future<List<ParkingSpace>> getSpaces(String parkingZoneId) async =>
      throw _unsupported();
  @override
  Future<ParkingSpace?> getSpace(String id) async => throw _unsupported();
  @override
  Future<void> upsertSpace(ParkingSpace space) async => throw _unsupported();

  @override
  Future<List<VehicleParkingAssignment>> getAssignments({
    String? vehicleId,
    String? parkingSpaceId,
    String? parkingLotId,
  }) async => throw _unsupported();
  @override
  Future<VehicleParkingAssignment?> getAssignment(String id) async =>
      throw _unsupported();
  @override
  Future<VehicleParkingAssignment?> getCurrentAssignment(
    String vehicleId, {
    DateTime? at,
  }) async => throw _unsupported();
  @override
  Future<void> createAssignment(VehicleParkingAssignment assignment) async =>
      throw _unsupported();
  @override
  Future<void> moveVehicleToSpace({
    required VehicleParkingAssignment nextAssignment,
    required DateTime closePreviousAt,
    String? endedBy,
  }) async => throw _unsupported();
  @override
  Future<void> endAssignment({
    required String assignmentId,
    required DateTime endedAt,
    String? endedBy,
  }) async => throw _unsupported();

  @override
  Future<void> appendAccessEvent(ParkingAccessEvent event) async =>
      throw _unsupported();
  @override
  Future<List<ParkingAccessEvent>> getAccessEvents({
    String? parkingLotId,
    String? vehicleId,
    int? limit,
  }) async => throw _unsupported();

  @override
  Future<void> upsertMedia(ParkingMedia media) async => throw _unsupported();
  @override
  Future<List<ParkingMedia>> getMedia(String parkingLotId) async =>
      throw _unsupported();
}
