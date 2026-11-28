import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:parc_oto/domain/parking/parking_geometry.dart';
import 'package:parc_oto/domain/parking/parking_models.dart';

void main() {
  final createdAt = DateTime.utc(2026, 11, 28, 9);
  final updatedAt = DateTime.utc(2026, 11, 28, 10);


  group('ParkingSite', () {
    test('round trips site hierarchy and optional geographic centre', () {
      final site = ParkingSite(
        id: 'site-001',
        companyId: 'company-001',
        code: 'ANN-01',
        name: 'Dépôt Annaba',
        address: 'Annaba',
        wilaya: 23,
        commune: 'Annaba',
        latitude: 36.9,
        longitude: 7.77,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      final restored = ParkingSite.fromJson(
        Map<String, dynamic>.from(site.toJson()),
      );
      expect(restored.companyId, 'company-001');
      expect(restored.latitude, 36.9);
      expect(restored.longitude, 7.77);
    });

    test('rejects coordinates outside WGS84 bounds', () {
      expect(
        () => ParkingSite(
          id: 'site-invalid',
          companyId: 'company-001',
          code: 'BAD',
          name: 'Invalid',
          latitude: 91,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ).validate(),
        throwsArgumentError,
      );
    });
  });

  group('ParkingLot', () {
    test('round trips a tenant-scoped parking lot', () {
      final lot = ParkingLot(
        id: 'lot-001',
        companyId: 'company-001',
        siteId: 'site-001',
        code: 'P-ANN-01',
        name: 'Parking principal',
        address: 'Annaba',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final restored = ParkingLot.fromJson(
        Map<String, dynamic>.from(lot.toJson()),
      );

      expect(restored.id, lot.id);
      expect(restored.companyId, lot.companyId);
      expect(restored.siteId, lot.siteId);
      expect(restored.code, lot.code);
      expect(restored.status, ParkingLotStatus.active);
    });

    test('rejects a missing tenant or parent ID', () {
      expect(
        () => ParkingLot(
          id: 'lot-001',
          companyId: '',
          siteId: 'site-001',
          code: 'P1',
          name: 'Parking',
          createdAt: createdAt,
          updatedAt: updatedAt,
        ).validate(),
        throwsArgumentError,
      );
    });
  });

  group('ParkingPolygon', () {
    test('validates and round trips a metre-coordinate polygon', () {
      final polygon = ParkingPolygon(
        points: const [
          ParkingPoint(x: 0, y: 0),
          ParkingPoint(x: 20, y: 0),
          ParkingPoint(x: 20, y: 10),
          ParkingPoint(x: 0, y: 10),
        ],
      );

      polygon.validate();
      expect(polygon.signedArea, 200);

      final restored = ParkingPolygon.fromJson(
        Map<String, dynamic>.from(polygon.toJson()),
      );
      expect(restored.points, hasLength(4));
      expect(restored.signedArea, 200);
      expect(polygon.toJson()['unit'], 'm');
    });

    test('rejects self-intersecting geometry', () {
      final polygon = ParkingPolygon(
        points: const [
          ParkingPoint(x: 0, y: 0),
          ParkingPoint(x: 4, y: 4),
          ParkingPoint(x: 0, y: 4),
          ParkingPoint(x: 5, y: 0),
          ParkingPoint(x: 6, y: 3),
        ],
      );

      expect(polygon.validate, throwsArgumentError);
    });
  });

  group('ParkingLayout and background calibration', () {
    test('round trips a calibrated raster background and vector layers', () {
      final transform = ParkingBackgroundTransform(
        originXM: 5,
        originYM: 8,
        metersPerPixel: 0.1,
        rotationDegrees: 90,
        opacity: 0.65,
        calibration: const ParkingBackgroundCalibration(
          firstPixel: ParkingPoint(x: 10, y: 20),
          secondPixel: ParkingPoint(x: 110, y: 20),
          realDistanceM: 10,
        ),
      );
      final layout = ParkingLayout(
        id: 'layout-001',
        companyId: 'company-001',
        parkingLotId: 'lot-001',
        name: 'Plan principal',
        version: 1,
        widthM: 80,
        heightM: 45,
        gridStepM: 0.25,
        backgroundFileId: 'file-001',
        backgroundTransform: transform,
        layersJson: jsonEncode([
          {'id': 'layer-spaces', 'type': 'spaces', 'visible': true},
          {'id': 'layer-annotations', 'type': 'annotations', 'locked': false},
        ]),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final restored = ParkingLayout.fromJson(
        Map<String, dynamic>.from(layout.toJson()),
      );

      expect(restored.widthM, 80);
      expect(restored.heightM, 45);
      expect(restored.backgroundFileId, 'file-001');
      expect(restored.backgroundTransform!.opacity, 0.65);
      expect(
        restored.backgroundTransform!.calibration!.metersPerPixel,
        closeTo(0.1, 1e-10),
      );
      expect(jsonDecode(restored.layersJson), hasLength(2));
    });

    test('transforms image coordinates into local metres', () {
      const transform = ParkingBackgroundTransform(
        originXM: 100,
        originYM: 200,
        metersPerPixel: 0.1,
      );

      final world = transform.imageToWorld(
        const ParkingPoint(x: 10, y: 20),
      );

      expect(world.x, closeTo(101, 1e-10));
      expect(world.y, closeTo(202, 1e-10));
    });

    test('rejects invalid scale, dimensions and non-array layer JSON', () {
      expect(
        () => ParkingBackgroundTransform(metersPerPixel: 0).validate(),
        throwsArgumentError,
      );
      expect(
        () => ParkingLayout(
          id: 'layout-001',
          companyId: 'company-001',
          parkingLotId: 'lot-001',
          name: 'Invalid',
          version: 1,
          widthM: 0,
          heightM: 20,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ).validate(),
        throwsArgumentError,
      );
      expect(
        () => ParkingLayout(
          id: 'layout-002',
          companyId: 'company-001',
          parkingLotId: 'lot-001',
          name: 'Invalid layers',
          version: 1,
          widthM: 20,
          heightM: 20,
          layersJson: '{}',
          createdAt: createdAt,
          updatedAt: updatedAt,
        ).validate(),
        throwsFormatException,
      );
      expect(
        () => ParkingLayout(
          id: 'layout-003',
          companyId: 'company-001',
          parkingLotId: 'lot-001',
          name: 'Duplicate layer ids',
          version: 1,
          widthM: 20,
          heightM: 20,
          layersJson: jsonEncode([
            {'id': 'layer-a', 'type': 'spaces'},
            {'id': 'layer-a', 'type': 'annotations'},
          ]),
          createdAt: createdAt,
          updatedAt: updatedAt,
        ).validate(),
        throwsFormatException,
      );
    });
  });

  group('ParkingZone and ParkingSpace', () {
    test('round trips a polygon zone and preserves controlled enum tokens', () {
      final zone = ParkingZone(
        id: 'zone-001',
        companyId: 'company-001',
        parkingLotId: 'lot-001',
        code: 'PL',
        name: 'Poids lourds',
        type: ParkingZoneType.heavyGoods,
        boundary: ParkingPolygon(
          points: const [
            ParkingPoint(x: 0, y: 0),
            ParkingPoint(x: 30, y: 0),
            ParkingPoint(x: 30, y: 20),
            ParkingPoint(x: 0, y: 20),
          ],
        ),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final json = zone.toJson();
      expect(json['zoneType'], 'heavy_goods');

      final restored = ParkingZone.fromJson(
        Map<String, dynamic>.from(json),
      );
      expect(restored.type, ParkingZoneType.heavyGoods);
      expect(restored.boundary!.signedArea, 600);
    });

    test('round trips a rectangular space using canonical metre keys', () {
      final space = ParkingSpace(
        id: 'space-001',
        companyId: 'company-001',
        parkingZoneId: 'zone-001',
        code: 'A-001',
        rectangle: const ParkingSpaceGeometry(
          centerX: 12.5,
          centerY: 4.25,
          width: 2.5,
          length: 5,
          rotationDegrees: 90,
        ),
        maxLengthMm: 5200,
        maxWidthMm: 2200,
        maxHeightMm: 2100,
        maxWeightKg: 3500,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final json = space.toJson();
      expect(json['xM'], 12.5);
      expect(json['widthM'], 2.5);
      expect(json['lengthM'], 5);
      expect(json['rotationDeg'], 90);

      final restored = ParkingSpace.fromJson(
        Map<String, dynamic>.from(json),
      );
      expect(restored.rectangle!.centerX, 12.5);
      expect(restored.rectangle!.rotationDegrees, 90);
      expect(restored.maxWeightKg, 3500);
      expect(restored.canReceiveAssignment, isTrue);
    });

    test('round trips a non-rectangular space', () {
      final space = ParkingSpace(
        id: 'space-poly-001',
        companyId: 'company-001',
        parkingZoneId: 'zone-001',
        code: 'VIP-01',
        shape: ParkingSpaceShape.polygon,
        polygon: ParkingPolygon(
          points: const [
            ParkingPoint(x: 1, y: 1),
            ParkingPoint(x: 5, y: 1),
            ParkingPoint(x: 4, y: 4),
            ParkingPoint(x: 1, y: 3),
          ],
        ),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final restored = ParkingSpace.fromJson(
        Map<String, dynamic>.from(space.toJson()),
      );
      expect(restored.shape, ParkingSpaceShape.polygon);
      expect(restored.polygon!.points, hasLength(4));
      expect(restored.rectangle, isNull);
    });

    test('does not confuse blocked state with occupancy', () {
      final blocked = ParkingSpace(
        id: 'space-blocked',
        companyId: 'company-001',
        parkingZoneId: 'zone-001',
        code: 'A-099',
        status: ParkingSpaceStatus.blocked,
        rectangle: const ParkingSpaceGeometry(
          centerX: 0,
          centerY: 0,
          width: 2.5,
          length: 5,
        ),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(blocked.canReceiveAssignment, isFalse);
    });

    test('rejects a rectangle with polygon geometry or invalid dimensions', () {
      expect(
        () => ParkingSpace(
          id: 'space-invalid',
          companyId: 'company-001',
          parkingZoneId: 'zone-001',
          code: 'A-100',
          rectangle: const ParkingSpaceGeometry(
            centerX: 0,
            centerY: 0,
            width: -1,
            length: 5,
          ),
          createdAt: createdAt,
          updatedAt: updatedAt,
        ).validate(),
        throwsArgumentError,
      );
    });
  });


    test('allows consecutive assignments and rejects overlapping intervals', () {
      const policy = ParkingAssignmentPolicy();
      final space = ParkingSpace(
        id: 'space-001',
        companyId: 'company-001',
        parkingZoneId: 'zone-001',
        code: 'A-01',
        rectangle: const ParkingSpaceGeometry(
          centerX: 0,
          centerY: 0,
          width: 2.5,
          length: 5,
        ),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      final current = VehicleParkingAssignment(
        id: 'assignment-current',
        companyId: 'company-001',
        vehicleId: 'vehicle-001',
        parkingSpaceId: 'space-001',
        type: ParkingAssignmentType.assigned,
        startAt: DateTime.utc(2026, 11, 28, 8),
        endAt: DateTime.utc(2026, 11, 28, 12),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      final nextReservation = VehicleParkingAssignment(
        id: 'reservation-next',
        companyId: 'company-001',
        vehicleId: 'vehicle-001',
        parkingSpaceId: 'space-001',
        type: ParkingAssignmentType.reserved,
        startAt: DateTime.utc(2026, 11, 28, 12),
        endAt: DateTime.utc(2026, 11, 28, 14),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(
        () => policy.ensureAllowed(
          candidate: nextReservation,
          space: space,
          existing: [current],
        ),
        returnsNormally,
      );

      final overlappingReservation = VehicleParkingAssignment(
        id: 'reservation-overlap',
        companyId: 'company-001',
        vehicleId: 'vehicle-002',
        parkingSpaceId: 'space-001',
        type: ParkingAssignmentType.reserved,
        startAt: DateTime.utc(2026, 11, 28, 11),
        endAt: DateTime.utc(2026, 11, 28, 13),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      expect(
        () => policy.ensureAllowed(
          candidate: overlappingReservation,
          space: space,
          existing: [current],
        ),
        throwsA(
          isA<ParkingAssignmentConflict>().having(
            (error) => error.reason,
            'reason',
            ParkingAssignmentConflictReason.parkingSpaceAlreadyAssigned,
          ),
        ),
      );
    });

    test('prevents one vehicle from occupying two spaces in the same window', () {
      const policy = ParkingAssignmentPolicy();
      final space = ParkingSpace(
        id: 'space-002',
        companyId: 'company-001',
        parkingZoneId: 'zone-001',
        code: 'A-02',
        rectangle: const ParkingSpaceGeometry(
          centerX: 4,
          centerY: 0,
          width: 2.5,
          length: 5,
        ),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      final existing = VehicleParkingAssignment(
        id: 'assignment-existing',
        companyId: 'company-001',
        vehicleId: 'vehicle-001',
        parkingSpaceId: 'space-001',
        startAt: DateTime.utc(2026, 11, 28, 8),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      final candidate = VehicleParkingAssignment(
        id: 'assignment-candidate',
        companyId: 'company-001',
        vehicleId: 'vehicle-001',
        parkingSpaceId: 'space-002',
        startAt: DateTime.utc(2026, 11, 28, 9),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(
        () => policy.ensureAllowed(
          candidate: candidate,
          space: space,
          existing: [existing],
        ),
        throwsA(
          isA<ParkingAssignmentConflict>().having(
            (error) => error.reason,
            'reason',
            ParkingAssignmentConflictReason.vehicleAlreadyAssigned,
          ),
        ),
      );
    });

    test('rejects assignment to blocked spaces and reservations without an end', () {
      const policy = ParkingAssignmentPolicy();
      final blocked = ParkingSpace(
        id: 'space-blocked',
        companyId: 'company-001',
        parkingZoneId: 'zone-001',
        code: 'A-99',
        status: ParkingSpaceStatus.blocked,
        rectangle: const ParkingSpaceGeometry(
          centerX: 0,
          centerY: 0,
          width: 2.5,
          length: 5,
        ),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      final assignment = VehicleParkingAssignment(
        id: 'assignment-blocked',
        companyId: 'company-001',
        vehicleId: 'vehicle-001',
        parkingSpaceId: 'space-blocked',
        startAt: createdAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      expect(
        () => policy.ensureAllowed(
          candidate: assignment,
          space: blocked,
          existing: const [],
        ),
        throwsA(
          isA<ParkingAssignmentConflict>().having(
            (error) => error.reason,
            'reason',
            ParkingAssignmentConflictReason.parkingSpaceUnavailable,
          ),
        ),
      );

      final incompleteReservation = VehicleParkingAssignment(
        id: 'reservation-invalid',
        companyId: 'company-001',
        vehicleId: 'vehicle-001',
        parkingSpaceId: 'space-blocked',
        type: ParkingAssignmentType.reserved,
        startAt: createdAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      expect(incompleteReservation.validate, throwsArgumentError);
    });

  group('VehicleParkingAssignment', () {
    test('keeps reservations distinct from physical occupancy', () {
      final assignment = VehicleParkingAssignment(
        id: 'assignment-001',
        companyId: 'company-001',
        vehicleId: 'vehicle-001',
        parkingSpaceId: 'space-001',
        type: ParkingAssignmentType.reserved,
        startAt: DateTime.utc(2026, 11, 29, 8),
        endAt: DateTime.utc(2026, 11, 29, 12),
        source: ParkingAssignmentSource.connectScan,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final json = assignment.toJson();
      expect(json['sourceType'], 'connect_scan');

      final restored = VehicleParkingAssignment.fromJson(
        Map<String, dynamic>.from(json),
      );
      expect(
        restored.occupancyAt(DateTime.utc(2026, 11, 29, 9)),
        ParkingOccupancy.reserved,
      );
      expect(
        restored.occupancyAt(DateTime.utc(2026, 11, 29, 13)),
        isNull,
      );
    });

    test('requires an end date for ended assignments', () {
      expect(
        () => VehicleParkingAssignment(
          id: 'assignment-invalid',
          companyId: 'company-001',
          vehicleId: 'vehicle-001',
          parkingSpaceId: 'space-001',
          status: ParkingAssignmentStatus.ended,
          startAt: createdAt,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ).validate(),
        throwsArgumentError,
      );
    });
  });

  group('ParkingAccessEvent and ParkingMedia', () {
    test('normalizes registrations without using OCR as automatic identity', () {
      final event = ParkingAccessEvent(
        id: 'event-001',
        companyId: 'company-001',
        parkingLotId: 'lot-001',
        type: ParkingAccessEventType.unknownPlate,
        source: ParkingEventSource.connectScan,
        occurredAt: DateTime.utc(2026, 11, 28, 10, 5),
        // Mobile and server clocks can differ slightly; preserve both facts.
        recordedAt: DateTime.utc(2026, 11, 28, 10, 4),
        registrationCaptured: '12345 - 116 - 23',
        confidence: 0.92,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final restored = ParkingAccessEvent.fromJson(
        Map<String, dynamic>.from(event.toJson()),
      );
      expect(restored.vehicleId, isNull);
      expect(restored.registrationNormalized, '1234511623');
      expect(restored.confidence, 0.92);
      expect(event.toJson()['eventType'], 'unknown_plate');
      expect(event.toJson()['sourceType'], 'connect_scan');
    });

    test('rejects OCR confidence outside its range', () {
      expect(
        () => ParkingAccessEvent(
          id: 'event-invalid',
          companyId: 'company-001',
          parkingLotId: 'lot-001',
          type: ParkingAccessEventType.entry,
          source: ParkingEventSource.connectScan,
          occurredAt: createdAt,
          recordedAt: updatedAt,
          confidence: 1.2,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ).validate(),
        throwsArgumentError,
      );
    });

    test('validates file metadata without storing file bytes in the model', () {
      final media = ParkingMedia(
        id: 'media-001',
        companyId: 'company-001',
        parkingLotId: 'lot-001',
        layoutId: 'layout-001',
        fileId: 'storage-file-001',
        purpose: ParkingMediaPurpose.layoutBackground,
        fileName: 'plan.pdf',
        mimeType: 'application/pdf',
        fileSize: 2048,
        sha256: List.filled(64, 'a').join(),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final restored = ParkingMedia.fromJson(
        Map<String, dynamic>.from(media.toJson()),
      );
      expect(restored.fileSize, 2048);
      expect(restored.purpose, ParkingMediaPurpose.layoutBackground);
      expect(restored.toJson().containsKey('bytes'), isFalse);
    });
  });
}
