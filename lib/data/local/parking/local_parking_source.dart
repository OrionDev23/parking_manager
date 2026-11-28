import '../../../domain/parking/parking_models.dart';

/// Tenant-scoped local persistence contract for the Parking module.
///
/// This interface deliberately does not expose Appwrite or synchronization.
/// Until the remote Parking schema and server-side mutation handlers are
/// provisioned, records remain local drafts and are never sent to the outbox.
abstract interface class LocalParkingSource {
  Future<List<ParkingSite>> getSites();
  Future<ParkingSite?> getSite(String id);
  Future<void> upsertSite(ParkingSite site);

  Future<List<ParkingLot>> getParkingLots({String? siteId});
  Future<ParkingLot?> getParkingLot(String id);
  Future<void> upsertParkingLot(ParkingLot parkingLot);

  Future<List<ParkingLayout>> getLayouts(String parkingLotId);
  Future<ParkingLayout?> getLayout(String id);
  Future<void> upsertLayout(ParkingLayout layout);

  Future<List<ParkingZone>> getZones(String parkingLotId);
  Future<ParkingZone?> getZone(String id);
  Future<void> upsertZone(ParkingZone zone);

  Future<List<ParkingSpace>> getSpaces(String parkingZoneId);
  Future<ParkingSpace?> getSpace(String id);
  Future<void> upsertSpace(ParkingSpace space);

  Future<List<VehicleParkingAssignment>> getAssignments({
    String? vehicleId,
    String? parkingSpaceId,
    String? parkingLotId,
  });
  Future<VehicleParkingAssignment?> getAssignment(String id);
  Future<VehicleParkingAssignment?> getCurrentAssignment(
    String vehicleId, {
    DateTime? at,
  });
  Future<void> createAssignment(
    VehicleParkingAssignment assignment, {
    ParkingAccessEvent? event,
  });
  Future<void> moveVehicleToSpace({
    required VehicleParkingAssignment nextAssignment,
    required DateTime closePreviousAt,
    String? endedBy,
    ParkingAccessEvent? event,
  });
  Future<void> endAssignment({
    required String assignmentId,
    required DateTime endedAt,
    String? endedBy,
    ParkingAccessEvent? event,
  });

  Future<void> appendAccessEvent(ParkingAccessEvent event);
  Future<List<ParkingAccessEvent>> getAccessEvents({
    String? parkingLotId,
    String? vehicleId,
    int? limit,
  });

  Future<void> upsertMedia(ParkingMedia media);
  Future<List<ParkingMedia>> getMedia(String parkingLotId);
}
