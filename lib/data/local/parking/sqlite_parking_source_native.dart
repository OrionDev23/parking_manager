import 'dart:convert';
import 'dart:math' as math;

import 'package:sqlite3/sqlite3.dart';

import '../../../core/database/local_database.dart';
import '../../../domain/parking/parking_geometry.dart';
import '../../../domain/parking/parking_models.dart';
import 'local_parking_source.dart';

/// SQLite implementation for native Parcoto installations.
///
/// Every query is scoped by company_id. Parent references are checked before
/// writes; SQLite foreign keys provide a second tenant boundary at commit time.
class SqliteParkingSource implements LocalParkingSource {
  final LocalDatabase localDatabase;
  final String companyId;

  SqliteParkingSource(
    this.localDatabase, {
    required this.companyId,
  }) {
    if (companyId.trim().isEmpty) {
      throw ArgumentError.value(companyId, 'companyId');
    }
  }

  Database get _db => localDatabase.database;

  T _transaction<T>(T Function() action) {
    _db.execute('BEGIN IMMEDIATE');
    try {
      final result = action();
      _db.execute('COMMIT');
      return result;
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  void _assertTenantOwnership(String table, String id) {
    final rows = _db.select(
      'SELECT company_id FROM $table WHERE id = ? LIMIT 1',
      [id],
    );
    if (rows.isNotEmpty && rows.first['company_id'] != companyId) {
      throw StateError('$table ID is already owned by another company.');
    }
  }

  Row? _rowById(String table, String id) {
    final rows = _db.select(
      'SELECT * FROM $table WHERE id = ? AND company_id = ? LIMIT 1',
      [id, companyId],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Map<String, dynamic> _payload(Row row) {
    final decoded = jsonDecode(row['payload'] as String);
    if (decoded is! Map) {
      throw const FormatException('Stored Parking payload is not an object.');
    }
    return Map<String, dynamic>.from(decoded);
  }


  List<ParkingPoint> _spaceFootprint(ParkingSpace space) {
    if (space.polygon != null) return space.polygon!.points;
    final geometry = space.rectangle!;
    final angle = geometry.rotationDegrees * math.pi / 180;
    final cosine = math.cos(angle);
    final sine = math.sin(angle);
    final halfWidth = geometry.width / 2;
    final halfLength = geometry.length / 2;
    final corners = [
      ParkingPoint(x: -halfWidth, y: -halfLength),
      ParkingPoint(x: halfWidth, y: -halfLength),
      ParkingPoint(x: halfWidth, y: halfLength),
      ParkingPoint(x: -halfWidth, y: halfLength),
    ];
    return [
      for (final point in corners)
        ParkingPoint(
          x: geometry.centerX + point.x * cosine - point.y * sine,
          y: geometry.centerY + point.x * sine + point.y * cosine,
        ),
    ];
  }

  bool _insidePolygon(ParkingPoint point, ParkingPolygon polygon) {
    const epsilon = 1e-8;
    var inside = false;
    final points = polygon.points;
    for (var i = 0, j = points.length - 1; i < points.length; j = i++) {
      final a = points[j];
      final b = points[i];
      final cross = (b.x - a.x) * (point.y - a.y) -
          (b.y - a.y) * (point.x - a.x);
      if (cross.abs() <= epsilon &&
          point.x >= math.min(a.x, b.x) - epsilon &&
          point.x <= math.max(a.x, b.x) + epsilon &&
          point.y >= math.min(a.y, b.y) - epsilon &&
          point.y <= math.max(a.y, b.y) + epsilon) {
        return true;
      }
      final crossesY = (a.y > point.y) != (b.y > point.y);
      if (crossesY) {
        final intersectionX =
            (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x;
        if (point.x < intersectionX) inside = !inside;
      }
    }
    return inside;
  }

  bool _segmentWithinPolygon(
    ParkingPoint start,
    ParkingPoint end,
    ParkingPolygon polygon,
  ) {
    const epsilon = 1e-8;
    if (!_insidePolygon(start, polygon) || !_insidePolygon(end, polygon)) {
      return false;
    }

    final dx = end.x - start.x;
    final dy = end.y - start.y;
    final lengthSquared = dx * dx + dy * dy;
    if (lengthSquared <= epsilon * epsilon) return true;

    final cuts = <double>[0, 1];
    final points = polygon.points;
    for (var i = 0; i < points.length; i++) {
      final edgeStart = points[i];
      final edgeEnd = points[(i + 1) % points.length];
      final edgeX = edgeEnd.x - edgeStart.x;
      final edgeY = edgeEnd.y - edgeStart.y;
      final offsetX = edgeStart.x - start.x;
      final offsetY = edgeStart.y - start.y;
      final denominator = dx * edgeY - dy * edgeX;

      if (denominator.abs() <= epsilon) {
        final collinear = offsetX * dy - offsetY * dx;
        if (collinear.abs() > epsilon) continue;
        final firstT = (offsetX * dx + offsetY * dy) / lengthSquared;
        final secondOffsetX = edgeEnd.x - start.x;
        final secondOffsetY = edgeEnd.y - start.y;
        final secondT =
            (secondOffsetX * dx + secondOffsetY * dy) / lengthSquared;
        if (firstT > epsilon && firstT < 1 - epsilon) {
          cuts.add(firstT);
        }
        if (secondT > epsilon && secondT < 1 - epsilon) {
          cuts.add(secondT);
        }
        continue;
      }

      final t = (offsetX * edgeY - offsetY * edgeX) / denominator;
      final u = (offsetX * dy - offsetY * dx) / denominator;
      if (t >= -epsilon &&
          t <= 1 + epsilon &&
          u >= -epsilon &&
          u <= 1 + epsilon) {
        cuts.add(t.clamp(0.0, 1.0).toDouble());
      }
    }

    cuts.sort();
    for (var i = 0; i < cuts.length - 1; i++) {
      final lower = cuts[i];
      final upper = cuts[i + 1];
      if (upper - lower <= epsilon) continue;
      final t = (lower + upper) / 2;
      final probe = ParkingPoint(
        x: start.x + dx * t,
        y: start.y + dy * t,
      );
      if (!_insidePolygon(probe, polygon)) return false;
    }
    return true;
  }

  void _validateSetupGeometry({
    required ParkingLayout layout,
    required List<ParkingZone> zones,
    required List<ParkingSpace> spaces,
  }) {
    const epsilon = 1e-7;
    bool inPlan(ParkingPoint point) =>
        point.isFinite &&
        point.x >= -epsilon &&
        point.y >= -epsilon &&
        point.x <= layout.widthM + epsilon &&
        point.y <= layout.heightM + epsilon;

    for (final zone in zones) {
      final boundary = zone.boundary;
      if (boundary == null) continue;
      if (boundary.points.any((point) => !inPlan(point))) {
        throw ArgumentError(
          'Zone "' + zone.code + '" extends outside the plan.',
        );
      }
    }

    final zonesById = {for (final zone in zones) zone.id: zone};
    for (final space in spaces) {
      final footprint = _spaceFootprint(space);
      if (footprint.any((point) => !inPlan(point))) {
        throw ArgumentError(
          'Space "' + space.code + '" extends outside the plan.',
        );
      }
      final zone = zonesById[space.parkingZoneId]!;
      final boundary = zone.boundary;
      if (boundary != null) {
        for (var i = 0; i < footprint.length; i++) {
          final start = footprint[i];
          final end = footprint[(i + 1) % footprint.length];
          if (!_segmentWithinPolygon(start, end, boundary)) {
            throw ArgumentError(
              'Space "' + space.code + '" extends outside zone "' +
                  zone.code + '".',
            );
          }
        }
      }
    }
  }

  void _insertNewSite(ParkingSite site) {
    final json = site.toJson();
    _db.execute(
      '''INSERT INTO sites
        (id, company_id, code, name, status, created_at, updated_at, payload)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        site.id,
        companyId,
        site.code,
        site.name,
        json['status'],
        site.createdAt.toUtc().toIso8601String(),
        site.updatedAt.toUtc().toIso8601String(),
        jsonEncode(json),
      ],
    );
  }

  void _insertNewLot(ParkingLot parkingLot) {
    final json = parkingLot.toJson();
    _db.execute(
      '''INSERT INTO parking_lots
        (id, company_id, site_id, code, name, address, status,
         created_at, updated_at, payload)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        parkingLot.id,
        companyId,
        parkingLot.siteId,
        parkingLot.code,
        parkingLot.name,
        parkingLot.address,
        json['status'],
        parkingLot.createdAt.toUtc().toIso8601String(),
        parkingLot.updatedAt.toUtc().toIso8601String(),
        jsonEncode(json),
      ],
    );
  }

  void _insertNewLayout(ParkingLayout layout) {
    final json = layout.toJson();
    _db.execute(
      '''INSERT INTO parking_layouts
        (id, company_id, parking_lot_id, name, version, status,
         width_m, height_m, unit, grid_step_m, background_file_id,
         background_transform_json, layers_json, created_at, updated_at,
         payload)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'm', ?, ?, ?, ?, ?, ?, ?)''',
      [
        layout.id,
        companyId,
        layout.parkingLotId,
        layout.name,
        layout.version,
        json['status'],
        layout.widthM,
        layout.heightM,
        layout.gridStepM,
        layout.backgroundFileId,
        json['backgroundTransformJson'],
        layout.layersJson,
        layout.createdAt.toUtc().toIso8601String(),
        layout.updatedAt.toUtc().toIso8601String(),
        jsonEncode(json),
      ],
    );
  }

  void _insertNewZone(ParkingZone zone) {
    final json = zone.toJson();
    _db.execute(
      '''INSERT INTO parking_zones
        (id, company_id, parking_lot_id, code, name, zone_type, status,
         geometry_json, sort_order, color_token, created_at, updated_at,
         payload)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        zone.id,
        companyId,
        zone.parkingLotId,
        zone.code,
        zone.name,
        json['zoneType'],
        json['status'],
        json['geometryJson'],
        zone.sortOrder,
        zone.colorToken,
        zone.createdAt.toUtc().toIso8601String(),
        zone.updatedAt.toUtc().toIso8601String(),
        jsonEncode(json),
      ],
    );
  }

  void _insertNewSpace(ParkingSpace space) {
    final json = space.toJson();
    final geometry = space.rectangle;
    _db.execute(
      '''INSERT INTO parking_spaces
        (id, company_id, parking_zone_id, code, space_type, status,
         x_m, y_m, width_m, length_m, rotation_deg, shape_type,
         geometry_json, row_code, sort_order, max_length_mm, max_width_mm,
         max_height_mm, max_weight_kg, created_at, updated_at, payload)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        space.id,
        companyId,
        space.parkingZoneId,
        space.code,
        json['spaceType'],
        json['status'],
        geometry?.centerX,
        geometry?.centerY,
        geometry?.width,
        geometry?.length,
        geometry?.rotationDegrees ?? 0,
        json['shapeType'],
        json['geometryJson'],
        space.rowCode,
        space.sortOrder,
        space.maxLengthMm,
        space.maxWidthMm,
        space.maxHeightMm,
        space.maxWeightKg,
        space.createdAt.toUtc().toIso8601String(),
        space.updatedAt.toUtc().toIso8601String(),
        jsonEncode(json),
      ],
    );
  }

  @override
  Future<void> createParkingSetup({
    required ParkingSite site,
    required ParkingLot parkingLot,
    required ParkingLayout layout,
    required List<ParkingZone> zones,
    required List<ParkingSpace> spaces,
  }) async {
    site.validate();
    parkingLot.validate();
    layout.validate();
    if (zones.isEmpty || spaces.isEmpty) {
      throw ArgumentError(
        'A new parking setup requires at least one zone and one space.',
      );
    }
    if (site.companyId != companyId ||
        parkingLot.companyId != companyId ||
        layout.companyId != companyId) {
      throw StateError(
        'Every parking setup entity must belong to the active company.',
      );
    }
    if (parkingLot.siteId != site.id || layout.parkingLotId != parkingLot.id) {
      throw ArgumentError('Parking setup parent references are inconsistent.');
    }

    final zoneIds = <String>{};
    for (final zone in zones) {
      zone.validate();
      if (zone.companyId != companyId || zone.parkingLotId != parkingLot.id) {
        throw ArgumentError('Every zone must belong to the new parking.');
      }
      if (!zoneIds.add(zone.id)) {
        throw ArgumentError('Duplicate zone ID: ' + zone.id + '.');
      }
    }
    final spaceIds = <String>{};
    for (final space in spaces) {
      space.validate();
      if (space.companyId != companyId ||
          !zoneIds.contains(space.parkingZoneId)) {
        throw ArgumentError('Every space must belong to a zone in this parking.');
      }
      if (!spaceIds.add(space.id)) {
        throw ArgumentError('Duplicate space ID: ' + space.id + '.');
      }
    }
    _validateSetupGeometry(layout: layout, zones: zones, spaces: spaces);

    _transaction(() {
      _assertTenantOwnership('sites', site.id);
      _assertTenantOwnership('parking_lots', parkingLot.id);
      _assertTenantOwnership('parking_layouts', layout.id);
      for (final zone in zones) {
        _assertTenantOwnership('parking_zones', zone.id);
      }
      for (final space in spaces) {
        _assertTenantOwnership('parking_spaces', space.id);
      }
      _insertNewSite(site);
      _insertNewLot(parkingLot);
      _insertNewLayout(layout);
      for (final zone in zones) {
        _insertNewZone(zone);
      }
      for (final space in spaces) {
        _insertNewSpace(space);
      }
    });
  }

  @override
  Future<List<ParkingSite>> getSites() async => _db
      .select(
        'SELECT payload FROM sites WHERE company_id = ? ORDER BY name, code',
        [companyId],
      )
      .map((row) => ParkingSite.fromJson(_payload(row)))
      .toList(growable: false);

  @override
  Future<ParkingSite?> getSite(String id) async {
    final row = _rowById('sites', id);
    return row == null ? null : ParkingSite.fromJson(_payload(row));
  }

  @override
  Future<void> upsertSite(ParkingSite site) async {
    site.validate();
    if (site.companyId != companyId) {
      throw StateError('Site company does not match the active company.');
    }
    _transaction(() {
      _assertTenantOwnership('sites', site.id);
      final json = site.toJson();
      _db.execute(
        '''INSERT INTO sites
          (id, company_id, code, name, status, created_at, updated_at, payload)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            code=excluded.code, name=excluded.name, status=excluded.status,
            updated_at=excluded.updated_at, payload=excluded.payload
          WHERE sites.company_id=excluded.company_id''',
        [
          site.id,
          companyId,
          site.code,
          site.name,
          json['status'],
          site.createdAt.toUtc().toIso8601String(),
          site.updatedAt.toUtc().toIso8601String(),
          jsonEncode(json),
        ],
      );
    });
  }

  @override
  Future<List<ParkingLot>> getParkingLots({String? siteId}) async {
    final rows = siteId == null
        ? _db.select(
            'SELECT payload FROM parking_lots '
            'WHERE company_id = ? ORDER BY name, code',
            [companyId],
          )
        : _db.select(
            'SELECT payload FROM parking_lots '
            'WHERE company_id = ? AND site_id = ? ORDER BY name, code',
            [companyId, siteId],
          );
    return rows
        .map((row) => ParkingLot.fromJson(_payload(row)))
        .toList(growable: false);
  }

  @override
  Future<ParkingLot?> getParkingLot(String id) async {
    final row = _rowById('parking_lots', id);
    return row == null ? null : ParkingLot.fromJson(_payload(row));
  }

  @override
  Future<void> upsertParkingLot(ParkingLot parkingLot) async {
    parkingLot.validate();
    if (parkingLot.companyId != companyId) {
      throw StateError('Parking company does not match the active company.');
    }
    _transaction(() {
      _assertTenantOwnership('parking_lots', parkingLot.id);
      if (_rowById('sites', parkingLot.siteId) == null) {
        throw StateError('The selected site does not exist in this company.');
      }
      final json = parkingLot.toJson();
      _db.execute(
        '''INSERT INTO parking_lots
          (id, company_id, site_id, code, name, address, status,
           created_at, updated_at, payload)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            site_id=excluded.site_id, code=excluded.code, name=excluded.name,
            address=excluded.address, status=excluded.status,
            updated_at=excluded.updated_at, payload=excluded.payload
          WHERE parking_lots.company_id=excluded.company_id''',
        [
          parkingLot.id,
          companyId,
          parkingLot.siteId,
          parkingLot.code,
          parkingLot.name,
          parkingLot.address,
          json['status'],
          parkingLot.createdAt.toUtc().toIso8601String(),
          parkingLot.updatedAt.toUtc().toIso8601String(),
          jsonEncode(json),
        ],
      );
    });
  }

  @override
  Future<List<ParkingLayout>> getLayouts(String parkingLotId) async => _db
      .select(
        'SELECT payload FROM parking_layouts '
        'WHERE company_id = ? AND parking_lot_id = ? '
        'ORDER BY version DESC',
        [companyId, parkingLotId],
      )
      .map((row) => ParkingLayout.fromJson(_payload(row)))
      .toList(growable: false);

  @override
  Future<ParkingLayout?> getLayout(String id) async {
    final row = _rowById('parking_layouts', id);
    return row == null ? null : ParkingLayout.fromJson(_payload(row));
  }

  ParkingLayout? _getLayoutSync(String id) {
    final row = _rowById('parking_layouts', id);
    return row == null ? null : ParkingLayout.fromJson(_payload(row));
  }

  @override
  Future<void> upsertLayout(ParkingLayout layout) async {
    layout.validate();
    if (layout.companyId != companyId) {
      throw StateError('Layout company does not match the active company.');
    }
    _transaction(() {
      _assertTenantOwnership('parking_layouts', layout.id);
      if (_rowById('parking_lots', layout.parkingLotId) == null) {
        throw StateError('The selected parking does not exist in this company.');
      }
      final json = layout.toJson();
      _db.execute(
        '''INSERT INTO parking_layouts
          (id, company_id, parking_lot_id, name, version, status,
           width_m, height_m, unit, grid_step_m, background_file_id,
           background_transform_json, layers_json, created_at, updated_at,
           payload)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'm', ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            name=excluded.name, status=excluded.status,
            width_m=excluded.width_m, height_m=excluded.height_m,
            grid_step_m=excluded.grid_step_m,
            background_file_id=excluded.background_file_id,
            background_transform_json=excluded.background_transform_json,
            layers_json=excluded.layers_json, updated_at=excluded.updated_at,
            payload=excluded.payload
          WHERE parking_layouts.company_id=excluded.company_id''',
        [
          layout.id,
          companyId,
          layout.parkingLotId,
          layout.name,
          layout.version,
          json['status'],
          layout.widthM,
          layout.heightM,
          layout.gridStepM,
          layout.backgroundFileId,
          json['backgroundTransformJson'],
          layout.layersJson,
          layout.createdAt.toUtc().toIso8601String(),
          layout.updatedAt.toUtc().toIso8601String(),
          jsonEncode(json),
        ],
      );
    });
  }

  @override
  Future<List<ParkingZone>> getZones(String parkingLotId) async => _db
      .select(
        'SELECT payload FROM parking_zones '
        'WHERE company_id = ? AND parking_lot_id = ? '
        'ORDER BY sort_order, code',
        [companyId, parkingLotId],
      )
      .map((row) => ParkingZone.fromJson(_payload(row)))
      .toList(growable: false);

  @override
  Future<ParkingZone?> getZone(String id) async {
    final row = _rowById('parking_zones', id);
    return row == null ? null : ParkingZone.fromJson(_payload(row));
  }

  @override
  Future<void> upsertZone(ParkingZone zone) async {
    zone.validate();
    if (zone.companyId != companyId) {
      throw StateError('Zone company does not match the active company.');
    }
    _transaction(() {
      _assertTenantOwnership('parking_zones', zone.id);
      if (_rowById('parking_lots', zone.parkingLotId) == null) {
        throw StateError('The selected parking does not exist in this company.');
      }
      final json = zone.toJson();
      _db.execute(
        '''INSERT INTO parking_zones
          (id, company_id, parking_lot_id, code, name, zone_type, status,
           geometry_json, sort_order, color_token, created_at, updated_at,
           payload)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            code=excluded.code, name=excluded.name,
            zone_type=excluded.zone_type, status=excluded.status,
            geometry_json=excluded.geometry_json,
            sort_order=excluded.sort_order, color_token=excluded.color_token,
            updated_at=excluded.updated_at, payload=excluded.payload
          WHERE parking_zones.company_id=excluded.company_id''',
        [
          zone.id,
          companyId,
          zone.parkingLotId,
          zone.code,
          zone.name,
          json['zoneType'],
          json['status'],
          json['geometryJson'],
          zone.sortOrder,
          zone.colorToken,
          zone.createdAt.toUtc().toIso8601String(),
          zone.updatedAt.toUtc().toIso8601String(),
          jsonEncode(json),
        ],
      );
    });
  }

  @override
  Future<List<ParkingSpace>> getSpaces(String parkingZoneId) async => _db
      .select(
        'SELECT payload FROM parking_spaces '
        'WHERE company_id = ? AND parking_zone_id = ? '
        'ORDER BY sort_order, code',
        [companyId, parkingZoneId],
      )
      .map((row) => ParkingSpace.fromJson(_payload(row)))
      .toList(growable: false);

  @override
  Future<ParkingSpace?> getSpace(String id) async {
    final row = _rowById('parking_spaces', id);
    return row == null ? null : ParkingSpace.fromJson(_payload(row));
  }

  ParkingSpace? _getSpaceSync(String id) {
    final row = _rowById('parking_spaces', id);
    return row == null ? null : ParkingSpace.fromJson(_payload(row));
  }

  @override
  Future<void> upsertSpace(ParkingSpace space) async {
    space.validate();
    if (space.companyId != companyId) {
      throw StateError('Space company does not match the active company.');
    }
    _transaction(() {
      _assertTenantOwnership('parking_spaces', space.id);
      if (_rowById('parking_zones', space.parkingZoneId) == null) {
        throw StateError('The selected zone does not exist in this company.');
      }
      if (!space.canReceiveAssignment) {
        final activeRows = _db.select(
          '''SELECT id FROM vehicle_parking_assignments
             WHERE company_id = ? AND parking_space_id = ?
               AND status = 'active' LIMIT 1''',
          [companyId, space.id],
        );
        if (activeRows.isNotEmpty) {
          throw StateError(
            'End or cancel the active assignment before blocking this space.',
          );
        }
      }
      final json = space.toJson();
      final geometry = space.rectangle;
      _db.execute(
        '''INSERT INTO parking_spaces
          (id, company_id, parking_zone_id, code, space_type, status,
           x_m, y_m, width_m, length_m, rotation_deg, shape_type,
           geometry_json, row_code, sort_order, max_length_mm, max_width_mm,
           max_height_mm, max_weight_kg, created_at, updated_at, payload)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            parking_zone_id=excluded.parking_zone_id, code=excluded.code,
            space_type=excluded.space_type, status=excluded.status,
            x_m=excluded.x_m, y_m=excluded.y_m, width_m=excluded.width_m,
            length_m=excluded.length_m, rotation_deg=excluded.rotation_deg,
            shape_type=excluded.shape_type, geometry_json=excluded.geometry_json,
            row_code=excluded.row_code, sort_order=excluded.sort_order,
            max_length_mm=excluded.max_length_mm, max_width_mm=excluded.max_width_mm,
            max_height_mm=excluded.max_height_mm, max_weight_kg=excluded.max_weight_kg,
            updated_at=excluded.updated_at, payload=excluded.payload
          WHERE parking_spaces.company_id=excluded.company_id''',
        [
          space.id,
          companyId,
          space.parkingZoneId,
          space.code,
          json['spaceType'],
          json['status'],
          geometry?.centerX,
          geometry?.centerY,
          geometry?.width,
          geometry?.length,
          geometry?.rotationDegrees ?? 0,
          json['shapeType'],
          json['geometryJson'],
          space.rowCode,
          space.sortOrder,
          space.maxLengthMm,
          space.maxWidthMm,
          space.maxHeightMm,
          space.maxWeightKg,
          space.createdAt.toUtc().toIso8601String(),
          space.updatedAt.toUtc().toIso8601String(),
          jsonEncode(json),
        ],
      );
    });
  }

  List<VehicleParkingAssignment> _activeAssignmentsFor({
    required String vehicleId,
    required String parkingSpaceId,
  }) {
    final rows = _db.select(
      '''SELECT payload FROM vehicle_parking_assignments
         WHERE company_id = ? AND status = 'active'
           AND (vehicle_id = ? OR parking_space_id = ?)
         ORDER BY start_at, id''',
      [companyId, vehicleId, parkingSpaceId],
    );
    return rows
        .map((row) => VehicleParkingAssignment.fromJson(_payload(row)))
        .toList(growable: false);
  }

  VehicleParkingAssignment? _assignmentById(String id) {
    final row = _rowById('vehicle_parking_assignments', id);
    return row == null
        ? null
        : VehicleParkingAssignment.fromJson(_payload(row));
  }

  void _insertAssignment(VehicleParkingAssignment assignment) {
    final json = assignment.toJson();
    _db.execute(
      '''INSERT INTO vehicle_parking_assignments
        (id, company_id, vehicle_id, parking_space_id, assignment_type,
         status, source_type, start_at, end_at, entry_event_id, exit_event_id,
         assigned_by, ended_by, notes, created_at, updated_at, payload)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        assignment.id,
        companyId,
        assignment.vehicleId,
        assignment.parkingSpaceId,
        json['assignmentType'],
        json['status'],
        json['sourceType'],
        assignment.startAt.toUtc().toIso8601String(),
        assignment.endAt?.toUtc().toIso8601String(),
        assignment.entryEventId,
        assignment.exitEventId,
        assignment.assignedBy,
        assignment.endedBy,
        assignment.notes,
        assignment.createdAt.toUtc().toIso8601String(),
        assignment.updatedAt.toUtc().toIso8601String(),
        jsonEncode(json),
      ],
    );
  }

  void _endAssignment(
    VehicleParkingAssignment current, {
    required DateTime endedAt,
    String? endedBy,
  }) {
    final utcEnd = endedAt.toUtc();
    if (!utcEnd.isAfter(current.startAt.toUtc())) {
      throw ArgumentError('An assignment must end after it starts.');
    }
    final now = DateTime.now().toUtc();
    final ended = VehicleParkingAssignment(
      id: current.id,
      companyId: current.companyId,
      vehicleId: current.vehicleId,
      parkingSpaceId: current.parkingSpaceId,
      type: current.type,
      status: ParkingAssignmentStatus.ended,
      source: current.source,
      startAt: current.startAt,
      endAt: utcEnd,
      entryEventId: current.entryEventId,
      exitEventId: current.exitEventId,
      assignedBy: current.assignedBy,
      endedBy: endedBy,
      notes: current.notes,
      createdAt: current.createdAt,
      updatedAt: now.isBefore(current.createdAt) ? current.createdAt : now,
    );
    ended.validate();
    final json = ended.toJson();
    _db.execute(
      '''UPDATE vehicle_parking_assignments
         SET status = 'ended', end_at = ?, ended_by = ?, updated_at = ?,
             payload = ?
         WHERE id = ? AND company_id = ? AND status = 'active' ''',
      [
        utcEnd.toIso8601String(),
        endedBy,
        ended.updatedAt.toIso8601String(),
        jsonEncode(json),
        current.id,
        companyId,
      ],
    );
  }

  @override
  Future<List<VehicleParkingAssignment>> getAssignments({
    String? vehicleId,
    String? parkingSpaceId,
    String? parkingLotId,
  }) async {
    final filters = <String>['a.company_id = ?'];
    final args = <Object?>[companyId];
    if (vehicleId != null) {
      filters.add('a.vehicle_id = ?');
      args.add(vehicleId);
    }
    if (parkingSpaceId != null) {
      filters.add('a.parking_space_id = ?');
      args.add(parkingSpaceId);
    }
    if (parkingLotId != null) {
      filters.add('l.id = ?');
      args.add(parkingLotId);
    }
    final sql = StringBuffer(
      'SELECT a.payload FROM vehicle_parking_assignments a '
      'LEFT JOIN parking_spaces s '
      'ON s.id = a.parking_space_id AND s.company_id = a.company_id '
      'LEFT JOIN parking_zones z '
      'ON z.id = s.parking_zone_id AND z.company_id = s.company_id '
      'LEFT JOIN parking_lots l '
      'ON l.id = z.parking_lot_id AND l.company_id = z.company_id WHERE ',
    );
    sql.write(filters.join(' AND '));
    sql.write(' ORDER BY a.start_at DESC, a.id');
    return _db
        .select(sql.toString(), args)
        .map((row) => VehicleParkingAssignment.fromJson(_payload(row)))
        .toList(growable: false);
  }

  @override
  Future<VehicleParkingAssignment?> getAssignment(String id) async =>
      _assignmentById(id);

  @override
  Future<VehicleParkingAssignment?> getCurrentAssignment(
    String vehicleId, {
    DateTime? at,
  }) async {
    final instant = (at ?? DateTime.now()).toUtc();
    final assignments = await getAssignments(vehicleId: vehicleId);
    for (final assignment in assignments) {
      if (assignment.type != ParkingAssignmentType.reserved &&
          assignment.isEffectiveAt(instant)) {
        return assignment;
      }
    }
    return null;
  }

  void _assertAssignmentReferences(VehicleParkingAssignment assignment) {
    if (assignment.companyId != companyId) {
      throw StateError('Assignment company does not match the active company.');
    }
    if (_rowById('vehicles', assignment.vehicleId) == null) {
      throw StateError('The vehicle does not exist in the active company.');
    }
    final space = _getSpaceSync(assignment.parkingSpaceId);
    if (space == null) {
      throw StateError('The parking space does not exist in the active company.');
    }
    if (space.companyId != assignment.companyId) {
      throw StateError('Vehicle and parking space belong to different companies.');
    }
  }

  @override
  Future<void> createAssignment(
    VehicleParkingAssignment assignment, {
    ParkingAccessEvent? event,
  }) async {
    assignment.validate();
    if (assignment.status != ParkingAssignmentStatus.active) {
      throw ArgumentError('New assignments must start in the active state.');
    }
    _transaction(() {
      _assertTenantOwnership('vehicle_parking_assignments', assignment.id);
      _assertAssignmentReferences(assignment);
      final space = _getSpaceSync(assignment.parkingSpaceId)!;
      const policy = ParkingAssignmentPolicy();
      policy.ensureAllowed(
        candidate: assignment,
        space: space,
        existing: _activeAssignmentsFor(
          vehicleId: assignment.vehicleId,
          parkingSpaceId: assignment.parkingSpaceId,
        ),
      );
      _insertAssignment(assignment);
      if (event != null) {
        if (event.assignmentId != assignment.id ||
            event.vehicleId != assignment.vehicleId) {
          throw ArgumentError('Entry event must reference the created assignment and vehicle.');
        }
        _appendAccessEvent(event);
      }
    });
  }

  @override
  Future<void> moveVehicleToSpace({
    required VehicleParkingAssignment nextAssignment,
    required DateTime closePreviousAt,
    String? endedBy,
    ParkingAccessEvent? event,
  }) async {
    nextAssignment.validate();
    if (nextAssignment.status != ParkingAssignmentStatus.active ||
        nextAssignment.type == ParkingAssignmentType.reserved) {
      throw ArgumentError(
        'A vehicle move requires an active physical assignment.',
      );
    }
    _transaction(() {
      _assertTenantOwnership(
        'vehicle_parking_assignments',
        nextAssignment.id,
      );
      _assertAssignmentReferences(nextAssignment);
      final previousRows = _db.select(
        '''SELECT payload FROM vehicle_parking_assignments
           WHERE company_id = ? AND vehicle_id = ?
             AND status = 'active' AND assignment_type <> 'reserved' ''',
        [companyId, nextAssignment.vehicleId],
      );
      if (previousRows.length > 1) {
        throw StateError('Vehicle has more than one active physical assignment.');
      }
      if (previousRows.isNotEmpty) {
        final previous =
            VehicleParkingAssignment.fromJson(_payload(previousRows.single));
        if (closePreviousAt.toUtc().isAfter(nextAssignment.startAt.toUtc())) {
          throw ArgumentError(
            'The previous assignment cannot end after the next one starts.',
          );
        }
        _endAssignment(
          previous,
          endedAt: closePreviousAt,
          endedBy: endedBy,
        );
      }
      final space = _getSpaceSync(nextAssignment.parkingSpaceId)!;
      const policy = ParkingAssignmentPolicy();
      policy.ensureAllowed(
        candidate: nextAssignment,
        space: space,
        existing: _activeAssignmentsFor(
          vehicleId: nextAssignment.vehicleId,
          parkingSpaceId: nextAssignment.parkingSpaceId,
        ),
      );
      _insertAssignment(nextAssignment);
      if (event != null) {
        if (event.assignmentId != nextAssignment.id ||
            event.vehicleId != nextAssignment.vehicleId) {
          throw ArgumentError('Move event must reference the new assignment and vehicle.');
        }
        _appendAccessEvent(event);
      }
    });
  }

  @override
  Future<void> endAssignment({
    required String assignmentId,
    required DateTime endedAt,
    String? endedBy,
    ParkingAccessEvent? event,
  }) async {
    _transaction(() {
      final assignment = _assignmentById(assignmentId);
      if (assignment == null) return;
      if (assignment.status != ParkingAssignmentStatus.active) {
        throw StateError('Assignment is already closed.');
      }
      _endAssignment(assignment, endedAt: endedAt, endedBy: endedBy);
      if (event != null) {
        if (event.assignmentId != assignment.id ||
            event.vehicleId != assignment.vehicleId) {
          throw ArgumentError('Exit event must reference the ended assignment and vehicle.');
        }
        _appendAccessEvent(event);
      }
    });
  }

  String? _parkingLotIdForSpace(String spaceId) {
    final rows = _db.select(
      '''SELECT l.id FROM parking_spaces s
         JOIN parking_zones z
           ON z.id = s.parking_zone_id AND z.company_id = s.company_id
         JOIN parking_lots l
           ON l.id = z.parking_lot_id AND l.company_id = z.company_id
         WHERE s.id = ? AND s.company_id = ? LIMIT 1''',
      [spaceId, companyId],
    );
    return rows.isEmpty ? null : rows.first['id'] as String;
  }

  void _appendAccessEvent(ParkingAccessEvent event) {
    event.validate();
    if (event.companyId != companyId) {
      throw StateError('Event company does not match the active company.');
    }
    _assertTenantOwnership('parking_access_events', event.id);
    if (_rowById('parking_lots', event.parkingLotId) == null) {
      throw StateError('The parking does not exist in the active company.');
    }
    if (event.vehicleId != null &&
        _rowById('vehicles', event.vehicleId!) == null) {
      throw StateError('The vehicle does not exist in the active company.');
    }
    if (event.assignmentId != null) {
      final assignment = _assignmentById(event.assignmentId!);
      if (assignment == null ||
          assignment.companyId != event.companyId ||
          assignment.vehicleId != event.vehicleId ||
          _parkingLotIdForSpace(assignment.parkingSpaceId) !=
              event.parkingLotId) {
        throw StateError(
          'Event assignment does not match its vehicle, parking and tenant.',
        );
      }
    }
    final json = event.toJson();
    _db.execute(
      '''INSERT INTO parking_access_events
        (id, company_id, parking_lot_id, vehicle_id, assignment_id,
         event_type, source_type, occurred_at, recorded_at,
         registration_captured, registration_normalized, confidence,
         device_id, actor_user_id, notes, created_at, updated_at, payload)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        event.id,
        companyId,
        event.parkingLotId,
        event.vehicleId,
        event.assignmentId,
        json['eventType'],
        json['sourceType'],
        event.occurredAt.toUtc().toIso8601String(),
        event.recordedAt.toUtc().toIso8601String(),
        event.registrationCaptured,
        json['registrationNormalized'],
        event.confidence,
        event.deviceId,
        event.actorUserId,
        event.notes,
        event.createdAt.toUtc().toIso8601String(),
        event.updatedAt.toUtc().toIso8601String(),
        jsonEncode(json),
      ],
    );
  }

  @override
  Future<void> appendAccessEvent(ParkingAccessEvent event) async {
    _transaction(() => _appendAccessEvent(event));
  }

  @override
  Future<List<ParkingAccessEvent>> getAccessEvents({
    String? parkingLotId,
    String? vehicleId,
    int? limit,
  }) async {
    final filters = <String>['company_id = ?'];
    final args = <Object?>[companyId];
    if (parkingLotId != null) {
      filters.add('parking_lot_id = ?');
      args.add(parkingLotId);
    }
    if (vehicleId != null) {
      filters.add('vehicle_id = ?');
      args.add(vehicleId);
    }
    if (limit != null) {
      if (limit < 1 || limit > 1000) {
        throw RangeError.range(limit, 1, 1000, 'limit');
      }
      args.add(limit);
    }
    final sql = StringBuffer(
      'SELECT payload FROM parking_access_events WHERE ',
    );
    sql.write(filters.join(' AND '));
    sql.write(' ORDER BY occurred_at DESC, id DESC');
    if (limit != null) sql.write(' LIMIT ?');
    return _db
        .select(sql.toString(), args)
        .map((row) => ParkingAccessEvent.fromJson(_payload(row)))
        .toList(growable: false);
  }

  void _upsertMediaRow(ParkingMedia media) {
    final json = media.toJson();
    _db.execute(
      '''INSERT INTO parking_media
        (id, company_id, parking_lot_id, layout_id, file_id, purpose,
         file_name, mime_type, file_size, sha256, pixel_width, pixel_height,
         created_at, updated_at, payload)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          layout_id=excluded.layout_id, file_id=excluded.file_id,
          purpose=excluded.purpose, file_name=excluded.file_name,
          mime_type=excluded.mime_type, file_size=excluded.file_size,
          sha256=excluded.sha256, pixel_width=excluded.pixel_width,
          pixel_height=excluded.pixel_height, updated_at=excluded.updated_at,
          payload=excluded.payload
        WHERE parking_media.company_id=excluded.company_id''',
      [
        media.id,
        companyId,
        media.parkingLotId,
        media.layoutId,
        media.fileId,
        json['purpose'],
        media.fileName,
        media.mimeType,
        media.fileSize,
        media.sha256,
        media.pixelWidth,
        media.pixelHeight,
        media.createdAt.toUtc().toIso8601String(),
        media.updatedAt.toUtc().toIso8601String(),
        jsonEncode(json),
      ],
    );
  }

  @override
  Future<void> upsertMedia(ParkingMedia media) async {
    media.validate();
    if (media.companyId != companyId) {
      throw StateError('Media company does not match the active company.');
    }
    _transaction(() {
      _assertTenantOwnership('parking_media', media.id);
      if (_rowById('parking_lots', media.parkingLotId) == null) {
        throw StateError('The media parking does not exist in this company.');
      }
      if (media.layoutId != null) {
        final layout = _getLayoutSync(media.layoutId!);
        if (layout == null || layout.parkingLotId != media.parkingLotId) {
          throw StateError('The media layout does not belong to this parking.');
        }
      }
      _upsertMediaRow(media);
    });
  }

  @override
  Future<void> attachLayoutBackground({
    required ParkingLayout layout,
    required ParkingMedia media,
  }) async {
    layout.validate();
    media.validate();
    if (layout.companyId != companyId || media.companyId != companyId) {
      throw StateError('Layout and media must belong to the active company.');
    }
    if (media.purpose != ParkingMediaPurpose.layoutBackground ||
        media.layoutId != layout.id ||
        media.parkingLotId != layout.parkingLotId ||
        media.fileId != layout.backgroundFileId ||
        media.pixelWidth == null ||
        media.pixelHeight == null ||
        layout.backgroundTransform == null) {
      throw ArgumentError(
        'The media and calibrated layout background references are inconsistent.',
      );
    }

    _transaction(() {
      _assertTenantOwnership('parking_media', media.id);
      final current = _getLayoutSync(layout.id);
      if (current == null ||
          current.companyId != companyId ||
          current.parkingLotId != layout.parkingLotId) {
        throw StateError('The target plan does not exist in this parking.');
      }
      if (_rowById('parking_lots', layout.parkingLotId) == null) {
        throw StateError('The target parking does not exist in this company.');
      }

      final json = layout.toJson();
      final changes = _db.execute(
        '''UPDATE parking_layouts
           SET width_m = ?, height_m = ?, background_file_id = ?,
               background_transform_json = ?, layers_json = ?,
               updated_at = ?, payload = ?
           WHERE id = ? AND company_id = ? AND parking_lot_id = ?''',
        [
          layout.widthM,
          layout.heightM,
          layout.backgroundFileId,
          json['backgroundTransformJson'],
          layout.layersJson,
          layout.updatedAt.toUtc().toIso8601String(),
          jsonEncode(json),
          layout.id,
          companyId,
          layout.parkingLotId,
        ],
      );
      if (changes == 0) {
        throw StateError('The target plan could not be updated.');
      }
      _upsertMediaRow(media);
    });
  }

  @override
  Future<List<ParkingMedia>> getMedia(String parkingLotId) async => _db
      .select(
        'SELECT payload FROM parking_media '
        'WHERE company_id = ? AND parking_lot_id = ? ORDER BY created_at DESC',
        [companyId, parkingLotId],
      )
      .map((row) => ParkingMedia.fromJson(_payload(row)))
      .toList(growable: false);
}
