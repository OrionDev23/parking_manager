import 'dart:math' as math;

/// Geometry is stored in parking-plan world coordinates (metres), never pixels.
/// [centerX] and [centerY] identify the centre of the rectangular space.
class ParkingSpaceGeometry {
  final double centerX;
  final double centerY;
  final double width;
  final double length;
  final double rotationDegrees;

  const ParkingSpaceGeometry({
    required this.centerX,
    required this.centerY,
    required this.width,
    required this.length,
    this.rotationDegrees = 0,
  });

  bool get isValid =>
      centerX.isFinite &&
      centerY.isFinite &&
      width.isFinite &&
      length.isFinite &&
      rotationDegrees.isFinite &&
      width > 0 &&
      length > 0;

  ParkingSpaceGeometry translated(double dx, double dy) {
    if (!dx.isFinite || !dy.isFinite) {
      throw ArgumentError('Translation must contain finite coordinates.');
    }
    return ParkingSpaceGeometry(
      centerX: centerX + dx,
      centerY: centerY + dy,
      width: width,
      length: length,
      rotationDegrees: rotationDegrees,
    );
  }

  Map<String, Object> toJson() => {
        'centerX': centerX,
        'centerY': centerY,
        'width': width,
        'length': length,
        'rotationDegrees': rotationDegrees,
      };

  factory ParkingSpaceGeometry.fromJson(Map<String, Object?> json) {
    double readNumber(String key) {
      final value = json[key];
      if (value is num && value.toDouble().isFinite) return value.toDouble();
      throw FormatException('Invalid parking geometry field: $key');
    }

    final geometry = ParkingSpaceGeometry(
      centerX: readNumber('centerX'),
      centerY: readNumber('centerY'),
      width: readNumber('width'),
      length: readNumber('length'),
      rotationDegrees: json['rotationDegrees'] == null
          ? 0
          : readNumber('rotationDegrees'),
    );
    if (!geometry.isValid) {
      throw const FormatException('Parking geometry dimensions must be positive.');
    }
    return geometry;
  }
}

enum ParkingRowOrientation {
  horizontal,
  vertical,
}

/// Input for deterministic guided generation of a row of parking spaces.
///
/// The anchor is the centre of the first space. [angleDegrees] rotates the
/// whole row clockwise in the plan coordinate system. The orientation chooses
/// which dimension is used as the default pitch axis; angle then rotates it.
class ParkingRowSpec {
  final String zoneCode;
  final String rowCode;
  final String spacePrefix;
  final int count;
  final int firstNumber;
  final int numberPadding;
  final double anchorX;
  final double anchorY;
  final double spaceWidth;
  final double spaceLength;
  final double gap;
  final double angleDegrees;
  final ParkingRowOrientation orientation;

  const ParkingRowSpec({
    required this.zoneCode,
    required this.rowCode,
    required this.spacePrefix,
    required this.count,
    this.firstNumber = 1,
    this.numberPadding = 2,
    required this.anchorX,
    required this.anchorY,
    required this.spaceWidth,
    required this.spaceLength,
    this.gap = 0.25,
    this.angleDegrees = 0,
    this.orientation = ParkingRowOrientation.horizontal,
  });

  void validate() {
    if (zoneCode.trim().isEmpty || rowCode.trim().isEmpty) {
      throw ArgumentError('Zone and row codes are required.');
    }
    if (count < 1 || count > 1000) {
      throw RangeError.range(count, 1, 1000, 'count');
    }
    if (firstNumber < 0 || numberPadding < 1 || numberPadding > 8) {
      throw ArgumentError('Invalid numbering configuration.');
    }
    final values = [
      anchorX,
      anchorY,
      spaceWidth,
      spaceLength,
      gap,
      angleDegrees,
    ];
    if (values.any((value) => !value.isFinite) ||
        spaceWidth <= 0 ||
        spaceLength <= 0 ||
        gap < 0) {
      throw ArgumentError('Row geometry must contain finite, valid dimensions.');
    }
    if (spacePrefix.contains('/') || spacePrefix.contains(r'\\')) {
      throw ArgumentError('Space prefix cannot contain path separators.');
    }
  }
}

class GeneratedParkingSpace {
  final String code;
  final String zoneCode;
  final String rowCode;
  final int sortOrder;
  final ParkingSpaceGeometry geometry;

  const GeneratedParkingSpace({
    required this.code,
    required this.zoneCode,
    required this.rowCode,
    required this.sortOrder,
    required this.geometry,
  });
}

/// Generates stable codes and centre-based geometry for a single row.
///
/// This class intentionally has no Appwrite, SQLite or Flutter dependency.
/// Persisting generated spaces is a repository/use-case responsibility.
class ParkingRowGenerator {
  const ParkingRowGenerator();

  List<GeneratedParkingSpace> generate(ParkingRowSpec spec) {
    spec.validate();

    final radians = spec.angleDegrees * math.pi / 180;
    final basePitch = spec.orientation == ParkingRowOrientation.horizontal
        ? spec.spaceWidth + spec.gap
        : spec.spaceLength + spec.gap;
    final dx = math.cos(radians) * basePitch;
    final dy = math.sin(radians) * basePitch;

    return List<GeneratedParkingSpace>.generate(spec.count, (index) {
      final number = (spec.firstNumber + index)
          .toString()
          .padLeft(spec.numberPadding, '0');
      final width = spec.spaceWidth;
      final length = spec.spaceLength;
      return GeneratedParkingSpace(
        code: '${spec.spacePrefix}$number',
        zoneCode: spec.zoneCode,
        rowCode: spec.rowCode,
        sortOrder: index,
        geometry: ParkingSpaceGeometry(
          centerX: spec.anchorX + dx * index,
          centerY: spec.anchorY + dy * index,
          width: width,
          length: length,
          rotationDegrees: spec.angleDegrees,
        ),
      );
    }, growable: false);
  }
}
