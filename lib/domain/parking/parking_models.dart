import 'dart:convert';
import 'dart:math' as math;

import 'parking_canvas_document.dart';
import 'parking_geometry.dart';

export 'parking_geometry.dart' show ParkingPoint;

/// Physical availability of the parking itself. This is deliberately separate
/// from whether a space currently has a vehicle assignment.
enum ParkingLotStatus { active, inactive, archived }

enum ParkingLayoutStatus { draft, published, archived }

enum ParkingZoneType {
  standard,
  visitor,
  delivery,
  restricted,
  charging,
  maintenance,
  accessible,
  motorcycle,
  heavyGoods,
  other,
}

enum ParkingZoneStatus { active, inactive }

enum ParkingSpaceType {
  standard,
  visitor,
  delivery,
  restricted,
  charging,
  accessible,
  motorcycle,
  compact,
  heavyGoods,
  other,
}

enum ParkingSpaceStatus { active, inactive, blocked, maintenance }

enum ParkingSpaceShape { rectangle, polygon }

enum ParkingAssignmentType { reserved, assigned, temporary }

enum ParkingAssignmentStatus { active, ended, cancelled }

enum ParkingEventSource { manual, connectScan }

enum ParkingAssignmentSource { manual, connectScan, import, system }

enum ParkingAccessEventType { entry, exit, unknownPlate, manualCorrection }

enum ParkingMediaPurpose { layoutBackground, accessEvidence, attachment }

enum ParkingOccupancy { free, occupied, reserved }

String _requiredString(
  Map<String, dynamic> json,
  String key, {
  int? maxLength,
}) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing or invalid "$key".');
  }
  if (maxLength != null && value.length > maxLength) {
    throw FormatException('"$key" exceeds $maxLength characters.');
  }
  return value;
}

String? _optionalString(
  Map<String, dynamic> json,
  String key, {
  int? maxLength,
}) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('Invalid "$key".');
  }
  if (maxLength != null && value.length > maxLength) {
    throw FormatException('"$key" exceeds $maxLength characters.');
  }
  return value;
}

double _requiredDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num || !value.toDouble().isFinite) {
    throw FormatException('Missing or invalid numeric field "$key".');
  }
  return value.toDouble();
}

double? _optionalDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! num || !value.toDouble().isFinite) {
    throw FormatException('Invalid numeric field "$key".');
  }
  return value.toDouble();
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num || !value.isFinite || value.toInt() != value) {
    throw FormatException('Missing or invalid integer field "$key".');
  }
  return value.toInt();
}

int? _optionalInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! num || !value.isFinite || value.toInt() != value) {
    throw FormatException('Invalid integer field "$key".');
  }
  return value.toInt();
}

DateTime _requiredDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  final parsed = value is DateTime
      ? value
      : value is String
          ? DateTime.tryParse(value)
          : null;
  if (parsed == null) {
    throw FormatException('Missing or invalid date field "$key".');
  }
  return parsed.toUtc();
}

DateTime? _optionalDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  final parsed = value is DateTime
      ? value
      : value is String
          ? DateTime.tryParse(value)
          : null;
  if (parsed == null) {
    throw FormatException('Invalid date field "$key".');
  }
  return parsed.toUtc();
}

String _enumName<T extends Enum>(T value) => value.name.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );

T _enumValue<T extends Enum>(
  Iterable<T> values,
  Object? raw,
  String field, {
  T? defaultValue,
}) {
  if (raw == null && defaultValue != null) return defaultValue;
  if (raw is! String) {
    throw FormatException('Missing or invalid "$field".');
  }
  for (final value in values) {
    final snakeCase = value.name.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
    if (value.name == raw || snakeCase == raw) return value;
  }
  throw FormatException('Unsupported "$field": $raw.');
}

void _validateId(String value, String field) {
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,35}$').hasMatch(value)) {
    throw ArgumentError.value(
      value,
      field,
      'Must be a valid Appwrite identifier (1 to 36 characters).',
    );
  }
}

void _validateCode(String value, String field, {int maxLength = 40}) {
  if (value.trim().isEmpty || value.length > maxLength) {
    throw ArgumentError.value(
      value,
      field,
      'Must contain 1 to $maxLength characters.',
    );
  }
}

void _validateDateOrder(DateTime createdAt, DateTime updatedAt) {
  if (updatedAt.isBefore(createdAt)) {
    throw ArgumentError('updatedAt cannot be earlier than createdAt.');
  }
}

/// A single-ring polygon in the parking plan's metre coordinate system.
///
/// The ring is stored without repeating its first point at the end. Self
/// intersections, duplicate consecutive points and zero-area polygons are
/// rejected before persistence. Holes are intentionally not supported in v1.
class ParkingPolygon {
  final List<ParkingPoint> points;

  ParkingPolygon({required List<ParkingPoint> points})
      : points = List<ParkingPoint>.unmodifiable(points);

  double get signedArea {
    var sum = 0.0;
    for (var i = 0; i < points.length; i++) {
      final a = points[i];
      final b = points[(i + 1) % points.length];
      sum += a.x * b.y - b.x * a.y;
    }
    return sum / 2;
  }

  void validate() {
    if (points.length < 3 || points.length > 2000) {
      throw ArgumentError('A polygon must contain between 3 and 2000 points.');
    }
    if (points.any((point) => !point.isFinite)) {
      throw ArgumentError('Polygon points must be finite.');
    }

    const epsilon = 1e-9;
    for (var i = 0; i < points.length; i++) {
      final current = points[i];
      final next = points[(i + 1) % points.length];
      final dx = current.x - next.x;
      final dy = current.y - next.y;
      if (dx * dx + dy * dy <= epsilon * epsilon) {
        throw ArgumentError('Polygon contains duplicate consecutive points.');
      }
    }

    if (!signedArea.isFinite || signedArea.abs() <= epsilon) {
      throw ArgumentError('Polygon area must be finite and greater than zero.');
    }

    for (var i = 0; i < points.length; i++) {
      final a = points[i];
      final b = points[(i + 1) % points.length];
      for (var j = i + 1; j < points.length; j++) {
        // Consecutive edges share a valid endpoint. The first and last edges
        // are also adjacent and must not be treated as an intersection.
        if (j == i ||
            j == i + 1 ||
            (i == 0 && j == points.length - 1)) {
          continue;
        }
        final c = points[j];
        final d = points[(j + 1) % points.length];
        if (_segmentsIntersect(a, b, c, d, epsilon)) {
          throw ArgumentError('Polygon edges must not self-intersect.');
        }
      }
    }
  }

  Map<String, Object> toJson() => {
        'version': 1,
        'type': 'polygon',
        'unit': 'm',
        'points': points.map((point) => point.toJson()).toList(growable: false),
      };

  factory ParkingPolygon.fromJson(Map<String, dynamic> json) {
    if (_requiredInt(json, 'version') != 1 ||
        json['type'] != 'polygon' ||
        (json['unit'] != null && json['unit'] != 'm') ||
        json['points'] is! List) {
      throw const FormatException('Unsupported parking polygon schema.');
    }
    final rawPoints = json['points'] as List;
    final polygon = ParkingPolygon(
      points: rawPoints.map((raw) {
        if (raw is! Map) {
          throw const FormatException('Invalid polygon point.');
        }
        return ParkingPoint.fromJson(Map<String, dynamic>.from(raw));
      }).toList(growable: false),
    );
    try {
      polygon.validate();
    } on ArgumentError catch (error) {
      throw FormatException(error.message?.toString() ?? 'Invalid polygon.');
    }
    return polygon;
  }

  static double _cross(ParkingPoint a, ParkingPoint b, ParkingPoint c) =>
      (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);

  static bool _onSegment(
    ParkingPoint a,
    ParkingPoint b,
    ParkingPoint point,
    double epsilon,
  ) {
    return point.x >= math.min(a.x, b.x) - epsilon &&
        point.x <= math.max(a.x, b.x) + epsilon &&
        point.y >= math.min(a.y, b.y) - epsilon &&
        point.y <= math.max(a.y, b.y) + epsilon;
  }

  static bool _segmentsIntersect(
    ParkingPoint a,
    ParkingPoint b,
    ParkingPoint c,
    ParkingPoint d,
    double epsilon,
  ) {
    final abC = _cross(a, b, c);
    final abD = _cross(a, b, d);
    final cdA = _cross(c, d, a);
    final cdB = _cross(c, d, b);

    final properIntersection =
        ((abC > epsilon && abD < -epsilon) ||
                (abC < -epsilon && abD > epsilon)) &&
            ((cdA > epsilon && cdB < -epsilon) ||
                (cdA < -epsilon && cdB > epsilon));
    if (properIntersection) return true;

    if (abC.abs() <= epsilon && _onSegment(a, b, c, epsilon)) return true;
    if (abD.abs() <= epsilon && _onSegment(a, b, d, epsilon)) return true;
    if (cdA.abs() <= epsilon && _onSegment(c, d, a, epsilon)) return true;
    if (cdB.abs() <= epsilon && _onSegment(c, d, b, epsilon)) return true;
    return false;
  }
}

/// Pixel-space calibration captured from two points on an imported drawing.
class ParkingBackgroundCalibration {
  final ParkingPoint firstPixel;
  final ParkingPoint secondPixel;
  final double realDistanceM;

  const ParkingBackgroundCalibration({
    required this.firstPixel,
    required this.secondPixel,
    required this.realDistanceM,
  });

  double get pixelDistance => math.sqrt(
        math.pow(secondPixel.x - firstPixel.x, 2) +
            math.pow(secondPixel.y - firstPixel.y, 2),
      );

  double get metersPerPixel => realDistanceM / pixelDistance;

  void validate() {
    if (!firstPixel.isFinite ||
        !secondPixel.isFinite ||
        !realDistanceM.isFinite ||
        realDistanceM <= 0 ||
        pixelDistance <= 1e-9) {
      throw ArgumentError('Background calibration is invalid.');
    }
  }

  Map<String, Object> toJson() => {
        'firstPixel': firstPixel.toJson(),
        'secondPixel': secondPixel.toJson(),
        'realDistanceM': realDistanceM,
      };

  factory ParkingBackgroundCalibration.fromJson(
    Map<String, dynamic> json,
  ) {
    final calibration = ParkingBackgroundCalibration(
      firstPixel: ParkingPoint.fromJson(
        Map<String, dynamic>.from(json['firstPixel'] as Map),
      ),
      secondPixel: ParkingPoint.fromJson(
        Map<String, dynamic>.from(json['secondPixel'] as Map),
      ),
      realDistanceM: _requiredDouble(json, 'realDistanceM'),
    );
    try {
      calibration.validate();
    } on ArgumentError catch (error) {
      throw FormatException(error.message?.toString() ?? 'Invalid calibration.');
    }
    return calibration;
  }
}

/// Transformation from the imported raster image into the metre coordinate
/// system. Calibration determines scale; origin and rotation determine pose.
class ParkingBackgroundTransform {
  final double originXM;
  final double originYM;
  final double metersPerPixel;
  final double rotationDegrees;
  final double opacity;
  final ParkingBackgroundCalibration? calibration;

  const ParkingBackgroundTransform({
    this.originXM = 0,
    this.originYM = 0,
    required this.metersPerPixel,
    this.rotationDegrees = 0,
    this.opacity = 1,
    this.calibration,
  });

  void validate() {
    if (!originXM.isFinite ||
        !originYM.isFinite ||
        !metersPerPixel.isFinite ||
        metersPerPixel <= 0 ||
        !rotationDegrees.isFinite ||
        !opacity.isFinite ||
        opacity < 0 ||
        opacity > 1) {
      throw ArgumentError('Background transformation is invalid.');
    }
    calibration?.validate();
  }

  ParkingPoint imageToWorld(ParkingPoint pixel) {
    validate();
    if (!pixel.isFinite) {
      throw ArgumentError('Image coordinate must be finite.');
    }
    final scale = calibration?.metersPerPixel ?? metersPerPixel;
    final angle = rotationDegrees * math.pi / 180;
    final cosine = math.cos(angle);
    final sine = math.sin(angle);
    // Raster pixels use a top-left origin with Y increasing downward;
    // parking-plan coordinates use a bottom-left origin with Y increasing up.
    final imageY = -pixel.y;
    return ParkingPoint(
      x: originXM + (pixel.x * cosine - imageY * sine) * scale,
      y: originYM + (pixel.x * sine + imageY * cosine) * scale,
    );
  }

  Map<String, Object?> toJson() => {
        'originXM': originXM,
        'originYM': originYM,
        'metersPerPixel': metersPerPixel,
        'rotationDegrees': rotationDegrees,
        'opacity': opacity,
        'calibration': calibration?.toJson(),
      };

  factory ParkingBackgroundTransform.fromJson(Map<String, dynamic> json) =>
      ParkingBackgroundTransform(
        originXM: _optionalDouble(json, 'originXM') ?? 0,
        originYM: _optionalDouble(json, 'originYM') ?? 0,
        metersPerPixel: _requiredDouble(json, 'metersPerPixel'),
        rotationDegrees: _optionalDouble(json, 'rotationDegrees') ?? 0,
        opacity: _optionalDouble(json, 'opacity') ?? 1,
        calibration: json['calibration'] == null
            ? null
            : ParkingBackgroundCalibration.fromJson(
                Map<String, dynamic>.from(json['calibration'] as Map),
              ),
      )..validate();
}

enum ParkingSiteStatus { active, inactive, archived }

class ParkingSite {
  final String id;
  final String companyId;
  final String code;
  final String name;
  final String? address;
  final int? wilaya;
  final String? commune;
  final double? latitude;
  final double? longitude;
  final ParkingSiteStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ParkingSite({
    required this.id,
    required this.companyId,
    required this.code,
    required this.name,
    this.address,
    this.wilaya,
    this.commune,
    this.latitude,
    this.longitude,
    this.status = ParkingSiteStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  void validate() {
    _validateId(id, 'id');
    _validateId(companyId, 'companyId');
    _validateCode(code, 'code');
    if (name.trim().isEmpty || name.length > 120) {
      throw ArgumentError.value(name, 'name', 'Must contain 1 to 120 characters.');
    }
    if ((address?.length ?? 0) > 500 || (commune?.length ?? 0) > 120) {
      throw ArgumentError('Site address and commune exceed their limits.');
    }
    if (latitude != null &&
        (!latitude!.isFinite || latitude! < -90 || latitude! > 90)) {
      throw ArgumentError.value(latitude, 'latitude');
    }
    if (longitude != null &&
        (!longitude!.isFinite || longitude! < -180 || longitude! > 180)) {
      throw ArgumentError.value(longitude, 'longitude');
    }
    _validateDateOrder(createdAt, updatedAt);
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'companyId': companyId,
        'code': code,
        'name': name,
        'address': address,
        'wilaya': wilaya,
        'commune': commune,
        'latitude': latitude,
        'longitude': longitude,
        'status': _enumName(status),
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory ParkingSite.fromJson(Map<String, dynamic> json) => ParkingSite(
        id: _requiredString(json, 'id', maxLength: 36),
        companyId: _requiredString(json, 'companyId', maxLength: 36),
        code: _requiredString(json, 'code', maxLength: 40),
        name: _requiredString(json, 'name', maxLength: 120),
        address: _optionalString(json, 'address', maxLength: 500),
        wilaya: _optionalInt(json, 'wilaya'),
        commune: _optionalString(json, 'commune', maxLength: 120),
        latitude: _optionalDouble(json, 'latitude'),
        longitude: _optionalDouble(json, 'longitude'),
        status: _enumValue(
          ParkingSiteStatus.values,
          json['status'],
          'status',
          defaultValue: ParkingSiteStatus.active,
        ),
        createdAt: _requiredDate(json, 'createdAt'),
        updatedAt: _requiredDate(json, 'updatedAt'),
      )..validate();
}

class ParkingLot {
  final String id;
  final String companyId;
  final String siteId;
  final String code;
  final String name;
  final String? address;
  final ParkingLotStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ParkingLot({
    required this.id,
    required this.companyId,
    required this.siteId,
    required this.code,
    required this.name,
    this.address,
    this.status = ParkingLotStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  void validate() {
    _validateId(id, 'id');
    _validateId(companyId, 'companyId');
    _validateId(siteId, 'siteId');
    _validateCode(code, 'code');
    if (name.trim().isEmpty || name.length > 120) {
      throw ArgumentError.value(name, 'name', 'Must contain 1 to 120 characters.');
    }
    if ((address?.length ?? 0) > 500) {
      throw ArgumentError.value(address, 'address', 'Maximum 500 characters.');
    }
    _validateDateOrder(createdAt, updatedAt);
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'companyId': companyId,
        'siteId': siteId,
        'code': code,
        'name': name,
        'address': address,
        'status': _enumName(status),
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory ParkingLot.fromJson(Map<String, dynamic> json) =>
      ParkingLot(
        id: _requiredString(json, 'id', maxLength: 36),
        companyId: _requiredString(json, 'companyId', maxLength: 36),
        siteId: _requiredString(json, 'siteId', maxLength: 36),
        code: _requiredString(json, 'code', maxLength: 40),
        name: _requiredString(json, 'name', maxLength: 120),
        address: _optionalString(json, 'address', maxLength: 500),
        status: _enumValue(
          ParkingLotStatus.values,
          json['status'],
          'status',
          defaultValue: ParkingLotStatus.active,
        ),
        createdAt: _requiredDate(json, 'createdAt'),
        updatedAt: _requiredDate(json, 'updatedAt'),
      )..validate();
}

class ParkingLayout {
  final String id;
  final String companyId;
  final String parkingLotId;
  final String name;
  final int version;
  final ParkingLayoutStatus status;
  final double widthM;
  final double heightM;
  final double gridStepM;
  final String? backgroundFileId;
  final ParkingBackgroundTransform? backgroundTransform;
  /// Versioned JSON array; keeping it encoded avoids lossy map conversions
  /// before the canvas object schema is introduced.
  final String layersJson;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ParkingLayout({
    required this.id,
    required this.companyId,
    required this.parkingLotId,
    required this.name,
    required this.version,
    this.status = ParkingLayoutStatus.draft,
    required this.widthM,
    required this.heightM,
    this.gridStepM = 0.25,
    this.backgroundFileId,
    this.backgroundTransform,
    this.layersJson = '[]',
    required this.createdAt,
    required this.updatedAt,
  });

  void validate() {
    _validateId(id, 'id');
    _validateId(companyId, 'companyId');
    _validateId(parkingLotId, 'parkingLotId');
    if (name.trim().isEmpty || name.length > 120) {
      throw ArgumentError.value(name, 'name', 'Must contain 1 to 120 characters.');
    }
    if (version < 1) throw ArgumentError.value(version, 'version');
    if (!widthM.isFinite ||
        !heightM.isFinite ||
        widthM <= 0 ||
        heightM <= 0 ||
        !gridStepM.isFinite ||
        gridStepM <= 0) {
      throw ArgumentError('Layout dimensions and grid step must be positive.');
    }
    if ((backgroundFileId?.length ?? 0) > 36) {
      throw ArgumentError.value(backgroundFileId, 'backgroundFileId');
    }
    backgroundTransform?.validate();
    _validateLayersJson(
      layersJson,
      widthM: widthM,
      heightM: heightM,
    );
    _validateDateOrder(createdAt, updatedAt);
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'companyId': companyId,
        'parkingLotId': parkingLotId,
        'name': name,
        'version': version,
        'status': _enumName(status),
        'widthM': widthM,
        'heightM': heightM,
        'unit': 'm',
        'gridStepM': gridStepM,
        'backgroundFileId': backgroundFileId,
        'backgroundTransformJson': backgroundTransform == null
            ? null
            : jsonEncode(backgroundTransform!.toJson()),
        'layersJson': layersJson,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory ParkingLayout.fromJson(Map<String, dynamic> json) {
    final rawTransform = json['backgroundTransformJson'];
    Map<String, dynamic>? transform;
    if (rawTransform is String && rawTransform.isNotEmpty) {
      final decoded = jsonDecode(rawTransform);
      if (decoded is! Map) {
        throw const FormatException('Invalid background transform JSON.');
      }
      transform = Map<String, dynamic>.from(decoded);
    } else if (rawTransform is Map) {
      transform = Map<String, dynamic>.from(rawTransform);
    } else if (rawTransform != null) {
      throw const FormatException('Invalid background transform JSON.');
    }
    final layout = ParkingLayout(
      id: _requiredString(json, 'id', maxLength: 36),
      companyId: _requiredString(json, 'companyId', maxLength: 36),
      parkingLotId: _requiredString(json, 'parkingLotId', maxLength: 36),
      name: _requiredString(json, 'name', maxLength: 120),
      version: _requiredInt(json, 'version'),
      status: _enumValue(
        ParkingLayoutStatus.values,
        json['status'],
        'status',
        defaultValue: ParkingLayoutStatus.draft,
      ),
      widthM: _requiredDouble(json, 'widthM'),
      heightM: _requiredDouble(json, 'heightM'),
      gridStepM: _optionalDouble(json, 'gridStepM') ?? 0.25,
      backgroundFileId:
          _optionalString(json, 'backgroundFileId', maxLength: 36),
      backgroundTransform: transform == null
          ? null
          : ParkingBackgroundTransform.fromJson(transform),
      layersJson: _optionalString(json, 'layersJson') ?? '[]',
      createdAt: _requiredDate(json, 'createdAt'),
      updatedAt: _requiredDate(json, 'updatedAt'),
    );
    final unit = json['unit'];
    if (unit != null && unit != 'm') {
      throw const FormatException('Parking layout coordinates must use metres.');
    }
    layout.validate();
    return layout;
  }
}

class ParkingZone {
  final String id;
  final String companyId;
  final String parkingLotId;
  final String code;
  final String name;
  final ParkingZoneType type;
  final ParkingZoneStatus status;
  final ParkingPolygon? boundary;
  final int sortOrder;
  final String? colorToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ParkingZone({
    required this.id,
    required this.companyId,
    required this.parkingLotId,
    required this.code,
    required this.name,
    this.type = ParkingZoneType.standard,
    this.status = ParkingZoneStatus.active,
    this.boundary,
    this.sortOrder = 0,
    this.colorToken,
    required this.createdAt,
    required this.updatedAt,
  });

  void validate() {
    _validateId(id, 'id');
    _validateId(companyId, 'companyId');
    _validateId(parkingLotId, 'parkingLotId');
    _validateCode(code, 'code');
    if (name.trim().isEmpty || name.length > 120) {
      throw ArgumentError.value(name, 'name', 'Must contain 1 to 120 characters.');
    }
    if (sortOrder < 0) throw ArgumentError.value(sortOrder, 'sortOrder');
    if ((colorToken?.length ?? 0) > 32) {
      throw ArgumentError.value(colorToken, 'colorToken');
    }
    boundary?.validate();
    _validateDateOrder(createdAt, updatedAt);
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'companyId': companyId,
        'parkingLotId': parkingLotId,
        'code': code,
        'name': name,
        'zoneType': _enumName(type),
        'status': _enumName(status),
        'geometryJson':
            boundary == null ? null : jsonEncode(boundary!.toJson()),
        'sortOrder': sortOrder,
        'colorToken': colorToken,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory ParkingZone.fromJson(Map<String, dynamic> json) {
    final rawBoundary = json['geometryJson'];
    Map<String, dynamic>? boundaryJson;
    if (rawBoundary is String && rawBoundary.isNotEmpty) {
      final decoded = jsonDecode(rawBoundary);
      if (decoded is! Map) {
        throw const FormatException('Invalid zone geometry JSON.');
      }
      boundaryJson = Map<String, dynamic>.from(decoded);
    } else if (rawBoundary is Map) {
      boundaryJson = Map<String, dynamic>.from(rawBoundary);
    } else if (rawBoundary != null) {
      throw const FormatException('Invalid zone geometry JSON.');
    }
    return ParkingZone(
      id: _requiredString(json, 'id', maxLength: 36),
      companyId: _requiredString(json, 'companyId', maxLength: 36),
      parkingLotId: _requiredString(json, 'parkingLotId', maxLength: 36),
      code: _requiredString(json, 'code', maxLength: 40),
      name: _requiredString(json, 'name', maxLength: 120),
      type: _enumValue(
        ParkingZoneType.values,
        json['zoneType'],
        'zoneType',
        defaultValue: ParkingZoneType.standard,
      ),
      status: _enumValue(
        ParkingZoneStatus.values,
        json['status'],
        'status',
        defaultValue: ParkingZoneStatus.active,
      ),
      boundary: boundaryJson == null
          ? null
          : ParkingPolygon.fromJson(boundaryJson),
      sortOrder: _optionalInt(json, 'sortOrder') ?? 0,
      colorToken: _optionalString(json, 'colorToken', maxLength: 32),
      createdAt: _requiredDate(json, 'createdAt'),
      updatedAt: _requiredDate(json, 'updatedAt'),
    )..validate();
  }
}

class ParkingSpace {
  final String id;
  final String companyId;
  final String parkingZoneId;
  final String code;
  final ParkingSpaceType type;
  final ParkingSpaceStatus status;
  final ParkingSpaceShape shape;
  final ParkingSpaceGeometry? rectangle;
  final ParkingPolygon? polygon;
  final String? rowCode;
  final int sortOrder;
  final int? maxLengthMm;
  final int? maxWidthMm;
  final int? maxHeightMm;
  final int? maxWeightKg;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ParkingSpace({
    required this.id,
    required this.companyId,
    required this.parkingZoneId,
    required this.code,
    this.type = ParkingSpaceType.standard,
    this.status = ParkingSpaceStatus.active,
    this.shape = ParkingSpaceShape.rectangle,
    this.rectangle,
    this.polygon,
    this.rowCode,
    this.sortOrder = 0,
    this.maxLengthMm,
    this.maxWidthMm,
    this.maxHeightMm,
    this.maxWeightKg,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get canReceiveAssignment => status == ParkingSpaceStatus.active;

  void validate() {
    _validateId(id, 'id');
    _validateId(companyId, 'companyId');
    _validateId(parkingZoneId, 'parkingZoneId');
    _validateCode(code, 'code');
    if (sortOrder < 0) throw ArgumentError.value(sortOrder, 'sortOrder');
    if ((rowCode?.length ?? 0) > 40) {
      throw ArgumentError.value(rowCode, 'rowCode');
    }
    for (final entry in {
      'maxLengthMm': maxLengthMm,
      'maxWidthMm': maxWidthMm,
      'maxHeightMm': maxHeightMm,
      'maxWeightKg': maxWeightKg,
    }.entries) {
      if (entry.value != null && entry.value! <= 0) {
        throw ArgumentError.value(entry.value, entry.key, 'Must be positive.');
      }
    }
    switch (shape) {
      case ParkingSpaceShape.rectangle:
        if (rectangle == null || polygon != null || !rectangle!.isValid) {
          throw ArgumentError('Rectangular spaces require valid rectangle geometry only.');
        }
        break;
      case ParkingSpaceShape.polygon:
        if (polygon == null || rectangle != null) {
          throw ArgumentError('Polygon spaces require polygon geometry only.');
        }
        polygon!.validate();
        break;
    }
    _validateDateOrder(createdAt, updatedAt);
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'companyId': companyId,
        'parkingZoneId': parkingZoneId,
        'code': code,
        'spaceType': _enumName(type),
        'status': _enumName(status),
        'shapeType': _enumName(shape),
        if (rectangle != null) ...{
          'xM': rectangle!.centerX,
          'yM': rectangle!.centerY,
          'widthM': rectangle!.width,
          'lengthM': rectangle!.length,
          'rotationDeg': rectangle!.rotationDegrees,
        },
        'geometryJson':
            polygon == null ? null : jsonEncode(polygon!.toJson()),
        'rowCode': rowCode,
        'sortOrder': sortOrder,
        'maxLengthMm': maxLengthMm,
        'maxWidthMm': maxWidthMm,
        'maxHeightMm': maxHeightMm,
        'maxWeightKg': maxWeightKg,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory ParkingSpace.fromJson(Map<String, dynamic> json) {
    final shape = _enumValue(
      ParkingSpaceShape.values,
      json['shapeType'],
      'shapeType',
      defaultValue: ParkingSpaceShape.rectangle,
    );
    final rawPolygon = json['geometryJson'];
    Map<String, dynamic>? polygonJson;
    if (rawPolygon is String && rawPolygon.isNotEmpty) {
      final decoded = jsonDecode(rawPolygon);
      if (decoded is! Map) {
        throw const FormatException('Invalid space geometry JSON.');
      }
      polygonJson = Map<String, dynamic>.from(decoded);
    } else if (rawPolygon is Map) {
      polygonJson = Map<String, dynamic>.from(rawPolygon);
    } else if (rawPolygon != null) {
      throw const FormatException('Invalid space geometry JSON.');
    }

    ParkingSpaceGeometry? rectangle;
    if (shape == ParkingSpaceShape.rectangle) {
      rectangle = ParkingSpaceGeometry.fromJson({
        'xM': json['xM'],
        'yM': json['yM'],
        'width': json['widthM'] ?? json['width'],
        'length': json['lengthM'] ?? json['length'],
        'rotationDegrees': json['rotationDeg'] ?? json['rotationDegrees'],
      });
    }
    return ParkingSpace(
      id: _requiredString(json, 'id', maxLength: 36),
      companyId: _requiredString(json, 'companyId', maxLength: 36),
      parkingZoneId: _requiredString(json, 'parkingZoneId', maxLength: 36),
      code: _requiredString(json, 'code', maxLength: 40),
      type: _enumValue(
        ParkingSpaceType.values,
        json['spaceType'],
        'spaceType',
        defaultValue: ParkingSpaceType.standard,
      ),
      status: _enumValue(
        ParkingSpaceStatus.values,
        json['status'],
        'status',
        defaultValue: ParkingSpaceStatus.active,
      ),
      shape: shape,
      rectangle: rectangle,
      polygon: polygonJson == null
          ? null
          : ParkingPolygon.fromJson(polygonJson),
      rowCode: _optionalString(json, 'rowCode', maxLength: 40),
      sortOrder: _optionalInt(json, 'sortOrder') ?? 0,
      maxLengthMm: _optionalInt(json, 'maxLengthMm'),
      maxWidthMm: _optionalInt(json, 'maxWidthMm'),
      maxHeightMm: _optionalInt(json, 'maxHeightMm'),
      maxWeightKg: _optionalInt(json, 'maxWeightKg'),
      createdAt: _requiredDate(json, 'createdAt'),
      updatedAt: _requiredDate(json, 'updatedAt'),
    )..validate();
  }
}

class VehicleParkingAssignment {
  final String id;
  final String companyId;
  final String vehicleId;
  final String parkingSpaceId;
  final ParkingAssignmentType type;
  final ParkingAssignmentStatus status;
  final ParkingAssignmentSource source;
  final DateTime startAt;
  final DateTime? endAt;
  final String? entryEventId;
  final String? exitEventId;
  final String? assignedBy;
  final String? endedBy;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VehicleParkingAssignment({
    required this.id,
    required this.companyId,
    required this.vehicleId,
    required this.parkingSpaceId,
    this.type = ParkingAssignmentType.assigned,
    this.status = ParkingAssignmentStatus.active,
    this.source = ParkingAssignmentSource.manual,
    required this.startAt,
    this.endAt,
    this.entryEventId,
    this.exitEventId,
    this.assignedBy,
    this.endedBy,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool isEffectiveAt(DateTime instant) {
    final utc = instant.toUtc();
    return status == ParkingAssignmentStatus.active &&
        !utc.isBefore(startAt.toUtc()) &&
        (endAt == null || utc.isBefore(endAt!.toUtc()));
  }

  ParkingOccupancy? occupancyAt(DateTime instant) {
    if (!isEffectiveAt(instant)) return null;
    return type == ParkingAssignmentType.reserved
        ? ParkingOccupancy.reserved
        : ParkingOccupancy.occupied;
  }

  void validate() {
    _validateId(id, 'id');
    _validateId(companyId, 'companyId');
    _validateId(vehicleId, 'vehicleId');
    _validateId(parkingSpaceId, 'parkingSpaceId');
    for (final pair in {
      'entryEventId': entryEventId,
      'exitEventId': exitEventId,
      'assignedBy': assignedBy,
      'endedBy': endedBy,
    }.entries) {
      if ((pair.value?.length ?? 0) > 36) {
        throw ArgumentError.value(pair.value, pair.key);
      }
    }
    if ((notes?.length ?? 0) > 2000) {
      throw ArgumentError.value(notes, 'notes', 'Maximum 2000 characters.');
    }
    if (endAt != null && !endAt!.isAfter(startAt)) {
      throw ArgumentError('endAt must be later than startAt.');
    }
    if (type == ParkingAssignmentType.reserved && endAt == null) {
      throw ArgumentError('Reservations require a defined endAt.');
    }
    if (status == ParkingAssignmentStatus.ended && endAt == null) {
      throw ArgumentError('Ended assignments require endAt.');
    }
    _validateDateOrder(createdAt, updatedAt);
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'companyId': companyId,
        'vehicleId': vehicleId,
        'parkingSpaceId': parkingSpaceId,
        'assignmentType': _enumName(type),
        'status': _enumName(status),
        'sourceType': _enumName(source),
        'startAt': startAt.toUtc().toIso8601String(),
        'endAt': endAt?.toUtc().toIso8601String(),
        'entryEventId': entryEventId,
        'exitEventId': exitEventId,
        'assignedBy': assignedBy,
        'endedBy': endedBy,
        'notes': notes,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory VehicleParkingAssignment.fromJson(Map<String, dynamic> json) =>
      VehicleParkingAssignment(
        id: _requiredString(json, 'id', maxLength: 36),
        companyId: _requiredString(json, 'companyId', maxLength: 36),
        vehicleId: _requiredString(json, 'vehicleId', maxLength: 36),
        parkingSpaceId: _requiredString(json, 'parkingSpaceId', maxLength: 36),
        type: _enumValue(
          ParkingAssignmentType.values,
          json['assignmentType'],
          'assignmentType',
          defaultValue: ParkingAssignmentType.assigned,
        ),
        status: _enumValue(
          ParkingAssignmentStatus.values,
          json['status'],
          'status',
          defaultValue: ParkingAssignmentStatus.active,
        ),
        source: _enumValue(
          ParkingAssignmentSource.values,
          json['sourceType'],
          'sourceType',
          defaultValue: ParkingAssignmentSource.manual,
        ),
        startAt: _requiredDate(json, 'startAt'),
        endAt: _optionalDate(json, 'endAt'),
        entryEventId: _optionalString(json, 'entryEventId', maxLength: 36),
        exitEventId: _optionalString(json, 'exitEventId', maxLength: 36),
        assignedBy: _optionalString(json, 'assignedBy', maxLength: 36),
        endedBy: _optionalString(json, 'endedBy', maxLength: 36),
        notes: _optionalString(json, 'notes', maxLength: 2000),
        createdAt: _requiredDate(json, 'createdAt'),
        updatedAt: _requiredDate(json, 'updatedAt'),
      )..validate();
}

enum ParkingAssignmentConflictReason {
  parkingSpaceAlreadyAssigned,
  vehicleAlreadyAssigned,
  parkingSpaceUnavailable,
  tenantMismatch,
  spaceReferenceMismatch,
}

class ParkingAssignmentConflict implements Exception {
  final ParkingAssignmentConflictReason reason;
  final String? conflictingAssignmentId;

  const ParkingAssignmentConflict(
    this.reason, {
    this.conflictingAssignmentId,
  });

  @override
  String toString() =>
      'Parking assignment conflict: ${reason.name}'
      '${conflictingAssignmentId == null ? '' : ' ($conflictingAssignmentId)'}';
}

/// Enforces time-window conflicts before an assignment is written.
///
/// Intervals are half-open [startAt, endAt): an assignment ending at 10:00
/// does not conflict with another one starting at 10:00. The repository must
/// call this policy inside the same SQLite transaction as its write.
class ParkingAssignmentPolicy {
  const ParkingAssignmentPolicy();

  void ensureAllowed({
    required VehicleParkingAssignment candidate,
    required ParkingSpace space,
    required Iterable<VehicleParkingAssignment> existing,
  }) {
    candidate.validate();
    space.validate();

    if (candidate.companyId != space.companyId) {
      throw const ParkingAssignmentConflict(
        ParkingAssignmentConflictReason.tenantMismatch,
      );
    }
    if (candidate.parkingSpaceId != space.id) {
      throw const ParkingAssignmentConflict(
        ParkingAssignmentConflictReason.spaceReferenceMismatch,
      );
    }
    if (candidate.status != ParkingAssignmentStatus.active) return;
    if (!space.canReceiveAssignment) {
      throw const ParkingAssignmentConflict(
        ParkingAssignmentConflictReason.parkingSpaceUnavailable,
      );
    }
    for (final current in existing) {
      if (current.id == candidate.id ||
          current.companyId != candidate.companyId ||
          current.status != ParkingAssignmentStatus.active ||
          !_overlaps(candidate, current)) {
        continue;
      }
      if (current.parkingSpaceId == candidate.parkingSpaceId) {
        throw ParkingAssignmentConflict(
          ParkingAssignmentConflictReason.parkingSpaceAlreadyAssigned,
          conflictingAssignmentId: current.id,
        );
      }
      if (current.vehicleId == candidate.vehicleId) {
        throw ParkingAssignmentConflict(
          ParkingAssignmentConflictReason.vehicleAlreadyAssigned,
          conflictingAssignmentId: current.id,
        );
      }
    }
  }

  bool _overlaps(
    VehicleParkingAssignment left,
    VehicleParkingAssignment right,
  ) {
    final leftStart = left.startAt.toUtc();
    final rightStart = right.startAt.toUtc();
    final leftEnd = left.endAt?.toUtc();
    final rightEnd = right.endAt?.toUtc();

    final leftEndsAfterRightStarts =
        leftEnd == null || rightStart.isBefore(leftEnd);
    final rightEndsAfterLeftStarts =
        rightEnd == null || leftStart.isBefore(rightEnd);
    return leftEndsAfterRightStarts && rightEndsAfterLeftStarts;
  }
}

class ParkingAccessEvent {
  final String id;
  final String companyId;
  final String parkingLotId;
  final String? vehicleId;
  final String? assignmentId;
  final ParkingAccessEventType type;
  final ParkingEventSource source;
  final DateTime occurredAt;
  final DateTime recordedAt;
  final String? registrationCaptured;
  final String? registrationNormalized;
  final double? confidence;
  final String? deviceId;
  final String? actorUserId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ParkingAccessEvent({
    required this.id,
    required this.companyId,
    required this.parkingLotId,
    this.vehicleId,
    this.assignmentId,
    required this.type,
    required this.source,
    required this.occurredAt,
    required this.recordedAt,
    this.registrationCaptured,
    this.registrationNormalized,
    this.confidence,
    this.deviceId,
    this.actorUserId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  static String normalizeRegistration(String value) =>
      value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  void validate() {
    _validateId(id, 'id');
    _validateId(companyId, 'companyId');
    _validateId(parkingLotId, 'parkingLotId');
    if (vehicleId != null) _validateId(vehicleId!, 'vehicleId');
    if (assignmentId != null) _validateId(assignmentId!, 'assignmentId');
    if ((registrationCaptured?.length ?? 0) > 40 ||
        (registrationNormalized?.length ?? 0) > 40) {
      throw ArgumentError('Registration values cannot exceed 40 characters.');
    }
    if (registrationCaptured != null &&
        registrationNormalized != null &&
        registrationNormalized != normalizeRegistration(registrationCaptured!)) {
      throw ArgumentError('Normalized registration does not match captured text.');
    }
    if (confidence != null &&
        (!confidence!.isFinite || confidence! < 0 || confidence! > 1)) {
      throw ArgumentError.value(confidence, 'confidence');
    }
    if (type == ParkingAccessEventType.unknownPlate &&
        (registrationCaptured == null || registrationCaptured!.trim().isEmpty)) {
      throw ArgumentError('Unknown-plate events require a captured registration.');
    }
    if (source == ParkingEventSource.manual && confidence != null) {
      throw ArgumentError('Manual events cannot have an OCR confidence score.');
    }
    if ((deviceId?.length ?? 0) > 36 || (actorUserId?.length ?? 0) > 36) {
      throw ArgumentError('Actor and device IDs cannot exceed 36 characters.');
    }
    if ((notes?.length ?? 0) > 2000) {
      throw ArgumentError.value(notes, 'notes', 'Maximum 2000 characters.');
    }
    _validateDateOrder(createdAt, updatedAt);
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'companyId': companyId,
        'parkingLotId': parkingLotId,
        'vehicleId': vehicleId,
        'assignmentId': assignmentId,
        'eventType': _enumName(type),
        'sourceType': _enumName(source),
        'occurredAt': occurredAt.toUtc().toIso8601String(),
        'recordedAt': recordedAt.toUtc().toIso8601String(),
        'registrationCaptured': registrationCaptured,
        'registrationNormalized': registrationNormalized ??
            (registrationCaptured == null
                ? null
                : normalizeRegistration(registrationCaptured!)),
        'confidence': confidence,
        'deviceId': deviceId,
        'actorUserId': actorUserId,
        'notes': notes,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory ParkingAccessEvent.fromJson(Map<String, dynamic> json) =>
      ParkingAccessEvent(
        id: _requiredString(json, 'id', maxLength: 36),
        companyId: _requiredString(json, 'companyId', maxLength: 36),
        parkingLotId: _requiredString(json, 'parkingLotId', maxLength: 36),
        vehicleId: _optionalString(json, 'vehicleId', maxLength: 36),
        assignmentId: _optionalString(json, 'assignmentId', maxLength: 36),
        type: _enumValue(
          ParkingAccessEventType.values,
          json['eventType'],
          'eventType',
        ),
        source: _enumValue(
          ParkingEventSource.values,
          json['sourceType'],
          'sourceType',
        ),
        occurredAt: _requiredDate(json, 'occurredAt'),
        recordedAt: _requiredDate(json, 'recordedAt'),
        registrationCaptured:
            _optionalString(json, 'registrationCaptured', maxLength: 40),
        registrationNormalized:
            _optionalString(json, 'registrationNormalized', maxLength: 40),
        confidence: _optionalDouble(json, 'confidence'),
        deviceId: _optionalString(json, 'deviceId', maxLength: 36),
        actorUserId: _optionalString(json, 'actorUserId', maxLength: 36),
        notes: _optionalString(json, 'notes', maxLength: 2000),
        createdAt: _requiredDate(json, 'createdAt'),
        updatedAt: _requiredDate(json, 'updatedAt'),
      )..validate();
}

class ParkingMedia {
  final String id;
  final String companyId;
  final String parkingLotId;
  final String? layoutId;
  final String fileId;
  final ParkingMediaPurpose purpose;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final int? pixelWidth;
  final int? pixelHeight;
  final String? sha256;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ParkingMedia({
    required this.id,
    required this.companyId,
    required this.parkingLotId,
    this.layoutId,
    required this.fileId,
    required this.purpose,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    this.pixelWidth,
    this.pixelHeight,
    this.sha256,
    required this.createdAt,
    required this.updatedAt,
  });

  void validate() {
    _validateId(id, 'id');
    _validateId(companyId, 'companyId');
    _validateId(parkingLotId, 'parkingLotId');
    if (layoutId != null) _validateId(layoutId!, 'layoutId');
    _validateId(fileId, 'fileId');
    if (fileName.trim().isEmpty || fileName.length > 255) {
      throw ArgumentError.value(fileName, 'fileName');
    }
    if (mimeType.trim().isEmpty || mimeType.length > 120) {
      throw ArgumentError.value(mimeType, 'mimeType');
    }
    if (fileSize <= 0) throw ArgumentError.value(fileSize, 'fileSize');
    if ((pixelWidth == null) != (pixelHeight == null)) {
      throw ArgumentError('Pixel width and height must be provided together.');
    }
    if ((pixelWidth != null && pixelWidth! <= 0) ||
        (pixelHeight != null && pixelHeight! <= 0)) {
      throw ArgumentError('Image pixel dimensions must be positive.');
    }
    if (sha256 != null && !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(sha256!)) {
      throw ArgumentError.value(sha256, 'sha256');
    }
    _validateDateOrder(createdAt, updatedAt);
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'companyId': companyId,
        'parkingLotId': parkingLotId,
        'layoutId': layoutId,
        'fileId': fileId,
        'purpose': _enumName(purpose),
        'fileName': fileName,
        'mimeType': mimeType,
        'fileSize': fileSize,
        'pixelWidth': pixelWidth,
        'pixelHeight': pixelHeight,
        'sha256': sha256,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory ParkingMedia.fromJson(Map<String, dynamic> json) =>
      ParkingMedia(
        id: _requiredString(json, 'id', maxLength: 36),
        companyId: _requiredString(json, 'companyId', maxLength: 36),
        parkingLotId: _requiredString(json, 'parkingLotId', maxLength: 36),
        layoutId: _optionalString(json, 'layoutId', maxLength: 36),
        fileId: _requiredString(json, 'fileId', maxLength: 36),
        purpose: _enumValue(
          ParkingMediaPurpose.values,
          json['purpose'],
          'purpose',
        ),
        fileName: _requiredString(json, 'fileName', maxLength: 255),
        mimeType: _requiredString(json, 'mimeType', maxLength: 120),
        fileSize: _requiredInt(json, 'fileSize'),
        pixelWidth: _optionalInt(json, 'pixelWidth'),
        pixelHeight: _optionalInt(json, 'pixelHeight'),
        sha256: _optionalString(json, 'sha256', maxLength: 64),
        createdAt: _requiredDate(json, 'createdAt'),
        updatedAt: _requiredDate(json, 'updatedAt'),
      )..validate();
}

void _validateLayersJson(
  String value, {
  required double widthM,
  required double heightM,
}) {
  ParkingCanvasDocument.fromJsonString(value).validate(
    widthM: widthM,
    heightM: heightM,
  );
}
