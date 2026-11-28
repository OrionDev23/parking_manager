import 'package:flutter_test/flutter_test.dart';

import 'package:parc_oto/core/database/local_database.dart';
import 'package:parc_oto/data/local/parking/sqlite_parking_source.dart';
import 'package:parc_oto/data/local/vehicles/sqlite_vehicle_source.dart';
import 'package:parc_oto/domain/entities/vehicle.dart';
import 'package:parc_oto/domain/parking/parking_geometry.dart';
import 'package:parc_oto/domain/parking/parking_models.dart';

void main() {
  const companyId = 'company-parking-001';
  const otherCompanyId = 'company-parking-002';
  final createdAt = DateTime.utc(2026, 11, 28, 8);
  final updatedAt = DateTime.utc(2026, 11, 28, 8, 5);

  late LocalDatabase database;
  late SqliteParkingSource parking;
  late SqliteVehicleSource vehicles;

  setUp(() {
    database = LocalDatabase.inMemoryForTesting();
    parking = SqliteParkingSource(database, companyId: companyId);
    vehicles = SqliteVehicleSource(database, companyId: companyId);
  });

  tearDown(() async {
    await database.close();
  });

  ParkingSite site({
    String id = 'site-001',
    String tenant = companyId,
    String code = 'ANN-01',
  }) =>
      ParkingSite(
        id: id,
        companyId: tenant,
        code: code,
        name: 'Dépôt Annaba',
        address: 'Annaba',
        wilaya: 23,
        commune: 'Annaba',
        latitude: 36.9,
        longitude: 7.77,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  ParkingLot lot({
    String id = 'lot-001',
    String tenant = companyId,
    String parentSiteId = 'site-001',
  }) =>
      ParkingLot(
        id: id,
        companyId: tenant,
        siteId: parentSiteId,
        code: 'P-ANN-01',
        name: 'Parking principal',
        address: 'Dépôt Annaba',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  ParkingLayout layout() => ParkingLayout(
        id: 'layout-001',
        companyId: companyId,
        parkingLotId: 'lot-001',
        name: 'Plan principal',
        version: 1,
        widthM: 80,
        heightM: 45,
        gridStepM: 0.25,
        backgroundTransform: const ParkingBackgroundTransform(
          metersPerPixel: 0.1,
          opacity: 0.7,
        ),
        layersJson:
            '[{"id":"spaces","type":"spaces","visible":true},'
            '{"id":"annotations","type":"annotations","visible":true}]',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  ParkingZone zone({
    String id = 'zone-001',
    String tenant = companyId,
    String parentLotId = 'lot-001',
  }) =>
      ParkingZone(
        id: id,
        companyId: tenant,
        parkingLotId: parentLotId,
        code: 'A',
        name: 'Zone A',
        type: ParkingZoneType.standard,
        boundary: ParkingPolygon(
          points: const [
            ParkingPoint(x: 0, y: 0),
            ParkingPoint(x: 40, y: 0),
            ParkingPoint(x: 40, y: 25),
            ParkingPoint(x: 0, y: 25),
          ],
        ),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  ParkingSpace space({
    String id = 'space-001',
    String tenant = companyId,
    String parentZoneId = 'zone-001',
    String code = 'A-01',
    double x = 5,
    ParkingSpaceStatus status = ParkingSpaceStatus.active,
  }) =>
      ParkingSpace(
        id: id,
        companyId: tenant,
        parkingZoneId: parentZoneId,
        code: code,
        status: status,
        rectangle: ParkingSpaceGeometry(
          centerX: x,
          centerY: 5,
          width: 2.5,
          length: 5,
          rotationDegrees: 0,
        ),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  Vehicle vehicle({
    String id = 'vehicle-001',
    String tenant = companyId,
    String registration = '12345-116-23',
  }) =>
      Vehicle(
        id: id,
        companyId: tenant,
        registration: registration,
        foreignRegistration: false,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  VehicleParkingAssignment assignment({
    String id = 'assignment-001',
    String vehicleId = 'vehicle-001',
    String spaceId = 'space-001',
    ParkingAssignmentType type = ParkingAssignmentType.assigned,
    DateTime? startAt,
    DateTime? endAt,
  }) =>
      VehicleParkingAssignment(
        id: id,
        companyId: companyId,
        vehicleId: vehicleId,
        parkingSpaceId: spaceId,
        type: type,
        startAt: startAt ?? DateTime.utc(2026, 11, 28, 9),
        endAt: endAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  ParkingAccessEvent accessEvent({
    required String id,
    required String assignmentId,
    String vehicleId = 'vehicle-001',
    ParkingAccessEventType type = ParkingAccessEventType.entry,
    DateTime? occurredAt,
  }) {
    final time = occurredAt ?? DateTime.utc(2026, 11, 28, 9);
    return ParkingAccessEvent(
      id: id,
      companyId: companyId,
      parkingLotId: 'lot-001',
      vehicleId: vehicleId,
      assignmentId: assignmentId,
      type: type,
      source: ParkingEventSource.manual,
      occurredAt: time,
      recordedAt: time,
      createdAt: time,
      updatedAt: time,
    );
  }

  Future<void> seedConfiguration({bool withSecondSpace = false}) async {
    await parking.upsertSite(site());
    await parking.upsertParkingLot(lot());
    await parking.upsertLayout(layout());
    await parking.upsertZone(zone());
    await parking.upsertSpace(space());
    if (withSecondSpace) {
      await parking.upsertSpace(
        space(id: 'space-002', code: 'A-02', x: 9),
      );
    }
  }

  group('SqliteParkingSource configuration', () {
    test('persists site, parking, calibrated plan, zone and spaces', () async {
      await seedConfiguration(withSecondSpace: true);

      final sites = await parking.getSites();
      final lots = await parking.getParkingLots(siteId: 'site-001');
      final layouts = await parking.getLayouts('lot-001');
      final zones = await parking.getZones('lot-001');
      final spaces = await parking.getSpaces('zone-001');

      expect(sites, hasLength(1));
      expect(sites.single.wilaya, 23);
      expect(lots.single.id, 'lot-001');
      expect(layouts.single.widthM, 80);
      expect(layouts.single.backgroundTransform!.opacity, 0.7);
      expect(zones.single.boundary!.signedArea, 1000);
      expect(spaces.map((item) => item.code), ['A-01', 'A-02']);
      expect(spaces.first.rectangle!.centerX, 5);
    });

    test('isolates tenants and rejects cross-tenant parent references', () async {
      await parking.upsertSite(site());
      final otherTenant = SqliteParkingSource(
        database,
        companyId: otherCompanyId,
      );
      await otherTenant.upsertSite(
        site(
          id: 'site-other',
          tenant: otherCompanyId,
          code: 'OTHER-01',
        ),
      );

      expect(await parking.getSites(), hasLength(1));
      expect(await otherTenant.getSites(), hasLength(1));
      expect(
        () => otherTenant.upsertParkingLot(
          lot(
            id: 'lot-other',
            tenant: otherCompanyId,
            parentSiteId: 'site-001',
          ),
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        () => otherTenant.upsertSite(
          site(id: 'site-001', tenant: otherCompanyId, code: 'TRANSFER'),
        ),
        throwsA(isA<StateError>()),
      );
      expect((await parking.getSite('site-001'))?.companyId, companyId);
    });

    test('refuses to block or deactivate a space with an active assignment',
        () async {
      await seedConfiguration();
      await vehicles.upsertVehicle(vehicle());
      await parking.createAssignment(assignment());

      expect(
        () => parking.upsertSpace(
          space(status: ParkingSpaceStatus.blocked),
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        (await parking.getSpace('space-001'))!.status,
        ParkingSpaceStatus.active,
      );
    });

    test('stores media metadata without putting file bytes in SQLite payload',
        () async {
      await seedConfiguration();
      final media = ParkingMedia(
        id: 'media-001',
        companyId: companyId,
        parkingLotId: 'lot-001',
        layoutId: 'layout-001',
        fileId: 'storage-file-001',
        purpose: ParkingMediaPurpose.layoutBackground,
        fileName: 'plan.pdf',
        mimeType: 'application/pdf',
        fileSize: 4096,
        sha256: List.filled(64, 'b').join(),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      await parking.upsertMedia(media);
      final restored = (await parking.getMedia('lot-001')).single;

      expect(restored.fileId, media.fileId);
      expect(restored.fileSize, 4096);
      expect(restored.toJson().containsKey('bytes'), isFalse);
    });
  });

  group('SqliteParkingSource assignment transactions', () {
    test('creates an assignment and entry event in one transaction', () async {
      await seedConfiguration();
      await vehicles.upsertVehicle(vehicle());

      final created = assignment();
      await parking.createAssignment(
        created,
        event: accessEvent(
          id: 'event-entry-001',
          assignmentId: created.id,
        ),
      );

      final current = await parking.getCurrentAssignment('vehicle-001');
      final events = await parking.getAccessEvents(parkingLotId: 'lot-001');

      expect(current?.id, created.id);
      expect(events, hasLength(1));
      expect(events.single.assignmentId, created.id);
      expect(events.single.vehicleId, 'vehicle-001');
    });

    test('rolls back assignment creation when its entry event is invalid',
        () async {
      await seedConfiguration();
      await vehicles.upsertVehicle(vehicle());

      final created = assignment();
      await expectLater(
        parking.createAssignment(
          created,
          event: accessEvent(
            id: 'event-invalid-001',
            assignmentId: 'another-assignment',
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(await parking.getAssignment(created.id), isNull);
      expect(await parking.getAccessEvents(parkingLotId: 'lot-001'), isEmpty);
    });

    test('rejects overlapping reservations but accepts adjacent time windows',
        () async {
      await seedConfiguration();
      await vehicles.upsertVehicle(vehicle());
      final current = assignment(
        startAt: DateTime.utc(2026, 11, 28, 8),
        endAt: DateTime.utc(2026, 11, 28, 12),
      );
      await parking.createAssignment(current);

      final overlapping = assignment(
        id: 'reservation-overlap',
        vehicleId: 'vehicle-002',
        type: ParkingAssignmentType.reserved,
        startAt: DateTime.utc(2026, 11, 28, 11),
        endAt: DateTime.utc(2026, 11, 28, 13),
      );
      await vehicles.upsertVehicle(
        vehicle(id: 'vehicle-002', registration: '22222-116-23'),
      );
      await expectLater(
        parking.createAssignment(overlapping),
        throwsA(
          isA<ParkingAssignmentConflict>().having(
            (error) => error.reason,
            'reason',
            ParkingAssignmentConflictReason.parkingSpaceAlreadyAssigned,
          ),
        ),
      );

      final adjacent = assignment(
        id: 'reservation-adjacent',
        type: ParkingAssignmentType.reserved,
        startAt: DateTime.utc(2026, 11, 28, 12),
        endAt: DateTime.utc(2026, 11, 28, 14),
      );
      await expectLater(parking.createAssignment(adjacent), completes);
      expect(await parking.getAssignments(parkingSpaceId: 'space-001'),
          hasLength(2));
    });

    test('does not allow a vehicle to occupy two spaces in overlapping windows',
        () async {
      await seedConfiguration(withSecondSpace: true);
      await vehicles.upsertVehicle(vehicle());
      await parking.createAssignment(assignment());

      await expectLater(
        parking.createAssignment(
          assignment(
            id: 'assignment-second-space',
            spaceId: 'space-002',
            startAt: DateTime.utc(2026, 11, 28, 10),
          ),
        ),
        throwsA(
          isA<ParkingAssignmentConflict>().having(
            (error) => error.reason,
            'reason',
            ParkingAssignmentConflictReason.vehicleAlreadyAssigned,
          ),
        ),
      );
      expect(
        (await parking.getAssignments(vehicleId: 'vehicle-001')).single.id,
        'assignment-001',
      );
    });

    test('moves a vehicle and records the correction event atomically',
        () async {
      await seedConfiguration(withSecondSpace: true);
      await vehicles.upsertVehicle(vehicle());
      final previous = assignment(
        startAt: DateTime.utc(2026, 11, 28, 8),
      );
      await parking.createAssignment(previous);

      final next = assignment(
        id: 'assignment-next',
        spaceId: 'space-002',
        startAt: DateTime.utc(2026, 11, 28, 10),
      );
      await parking.moveVehicleToSpace(
        nextAssignment: next,
        closePreviousAt: DateTime.utc(2026, 11, 28, 10),
        event: accessEvent(
          id: 'event-move-001',
          assignmentId: next.id,
          type: ParkingAccessEventType.manualCorrection,
          occurredAt: DateTime.utc(2026, 11, 28, 10),
        ),
      );

      expect(
        (await parking.getAssignment(previous.id))!.status,
        ParkingAssignmentStatus.ended,
      );
      expect(
        (await parking.getCurrentAssignment('vehicle-001'))!.id,
        next.id,
      );
      expect((await parking.getAccessEvents()).single.assignmentId, next.id);
    });

    test('rolls back a move when its destination is already occupied',
        () async {
      await seedConfiguration(withSecondSpace: true);
      await vehicles.upsertVehicle(vehicle());
      await vehicles.upsertVehicle(
        vehicle(id: 'vehicle-002', registration: '22222-116-23'),
      );
      await parking.createAssignment(
        assignment(
          id: 'assignment-a',
          vehicleId: 'vehicle-001',
          spaceId: 'space-001',
        ),
      );
      await parking.createAssignment(
        assignment(
          id: 'assignment-b',
          vehicleId: 'vehicle-002',
          spaceId: 'space-002',
        ),
      );

      await expectLater(
        parking.moveVehicleToSpace(
          nextAssignment: assignment(
            id: 'assignment-a-next',
            vehicleId: 'vehicle-001',
            spaceId: 'space-002',
            startAt: DateTime.utc(2026, 11, 28, 10),
          ),
          closePreviousAt: DateTime.utc(2026, 11, 28, 10),
        ),
        throwsA(isA<ParkingAssignmentConflict>()),
      );

      expect(
        (await parking.getAssignment('assignment-a'))!.status,
        ParkingAssignmentStatus.active,
      );
      expect(
        (await parking.getCurrentAssignment('vehicle-001'))!.parkingSpaceId,
        'space-001',
      );
    });

    test('ends an assignment with its exit event in one transaction', () async {
      await seedConfiguration();
      await vehicles.upsertVehicle(vehicle());
      final current = assignment();
      await parking.createAssignment(current);

      await parking.endAssignment(
        assignmentId: current.id,
        endedAt: DateTime.utc(2026, 11, 28, 11),
        event: accessEvent(
          id: 'event-exit-001',
          assignmentId: current.id,
          type: ParkingAccessEventType.exit,
          occurredAt: DateTime.utc(2026, 11, 28, 11),
        ),
      );

      expect(
        (await parking.getAssignment(current.id))!.status,
        ParkingAssignmentStatus.ended,
      );
      expect(await parking.getCurrentAssignment('vehicle-001'), isNull);
      final events = await parking.getAccessEvents(parkingLotId: 'lot-001');
      expect(events.single.type, ParkingAccessEventType.exit);
      expect(events.single.assignmentId, current.id);
    });

    test('rolls back assignment closure when its exit event is inconsistent',
        () async {
      await seedConfiguration();
      await vehicles.upsertVehicle(vehicle());
      await vehicles.upsertVehicle(
        vehicle(id: 'vehicle-002', registration: '22222-116-23'),
      );
      final current = assignment();
      await parking.createAssignment(current);

      await expectLater(
        parking.endAssignment(
          assignmentId: current.id,
          endedAt: DateTime.utc(2026, 11, 28, 11),
          event: accessEvent(
            id: 'event-exit-invalid',
            assignmentId: current.id,
            vehicleId: 'vehicle-002',
            type: ParkingAccessEventType.exit,
            occurredAt: DateTime.utc(2026, 11, 28, 11),
          ),
        ),
        throwsA(isA<StateError>()),
      );

      expect(
        (await parking.getAssignment(current.id))!.status,
        ParkingAssignmentStatus.active,
      );
      expect(await parking.getAccessEvents(), isEmpty);
    });
  });
}
