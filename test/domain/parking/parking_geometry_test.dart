import 'package:flutter_test/flutter_test.dart';
import 'package:parc_oto/domain/parking/parking_geometry.dart';

void main() {
  group('ParkingSpaceGeometry', () {
    test('round trips world coordinates without converting to pixels', () {
      const geometry = ParkingSpaceGeometry(
        centerX: 12.5,
        centerY: 8.25,
        width: 2.5,
        length: 5,
        rotationDegrees: 90,
      );

      final restored = ParkingSpaceGeometry.fromJson(geometry.toJson());

      expect(restored.centerX, 12.5);
      expect(restored.centerY, 8.25);
      expect(restored.width, 2.5);
      expect(restored.length, 5);
      expect(restored.rotationDegrees, 90);
    });

    test('rejects non-positive dimensions', () {
      expect(
        () => ParkingSpaceGeometry.fromJson({
          'xM': 0,
          'yM': 0,
          'width': 0,
          'length': 5,
        }),
        throwsFormatException,
      );
    });
  });

  group('ParkingRowGenerator', () {
    const generator = ParkingRowGenerator();

    test('generates deterministic padded codes and horizontal positions', () {
      final spaces = generator.generate(
        const ParkingRowSpec(
          zoneCode: 'A',
          rowCode: 'A1',
          spacePrefix: 'A-',
          count: 3,
          anchorX: 10,
          anchorY: 4,
          spaceWidth: 2.5,
          spaceLength: 5,
          gap: 0.5,
        ),
      );

      expect(spaces.map((space) => space.code), ['A-01', 'A-02', 'A-03']);
      expect(spaces[0].geometry.centerX, 10);
      expect(spaces[1].geometry.centerX, 13);
      expect(spaces[2].geometry.centerX, 16);
      expect(spaces.every((space) => space.geometry.centerY == 4), isTrue);
      expect(spaces.map((space) => space.sortOrder), [0, 1, 2]);
    });

    test('rotates row direction while retaining metre dimensions', () {
      final spaces = generator.generate(
        const ParkingRowSpec(
          zoneCode: 'B',
          rowCode: 'B1',
          spacePrefix: 'B-',
          count: 2,
          anchorX: 1,
          anchorY: 2,
          spaceWidth: 2.5,
          spaceLength: 5,
          gap: 0,
          angleDegrees: 90,
        ),
      );

      expect(spaces[1].geometry.centerX, closeTo(1, 1e-10));
      expect(spaces[1].geometry.centerY, closeTo(4.5, 1e-10));
      expect(spaces[1].geometry.rotationDegrees, 90);
      expect(spaces[1].geometry.width, 2.5);
      expect(spaces[1].geometry.length, 5);
    });

    test('uses a vertical axis when the row orientation is vertical', () {
      final spaces = generator.generate(
        const ParkingRowSpec(
          zoneCode: 'C',
          rowCode: 'C1',
          spacePrefix: 'C-',
          count: 2,
          anchorX: 3,
          anchorY: 4,
          spaceWidth: 2.5,
          spaceLength: 5,
          gap: 0.5,
          orientation: ParkingRowOrientation.vertical,
        ),
      );

      expect(spaces[1].geometry.centerX, closeTo(3, 1e-10));
      expect(spaces[1].geometry.centerY, closeTo(9.5, 1e-10));
      expect(spaces[1].geometry.rotationDegrees, 90);
    });

    test('rejects a row prefix containing a single backslash', () {
      expect(
        () => generator.generate(
          const ParkingRowSpec(
            zoneCode: 'A',
            rowCode: 'A1',
            spacePrefix: r'BAD\',
            count: 1,
            anchorX: 0,
            anchorY: 0,
            spaceWidth: 2.5,
            spaceLength: 5,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid counts and dimensions before generating', () {
      expect(
        () => generator.generate(
          const ParkingRowSpec(
            zoneCode: 'A',
            rowCode: 'A1',
            spacePrefix: 'A-',
            count: 0,
            anchorX: 0,
            anchorY: 0,
            spaceWidth: 2.5,
            spaceLength: 5,
          ),
        ),
        throwsRangeError,
      );
      expect(
        () => generator.generate(
          const ParkingRowSpec(
            zoneCode: 'A',
            rowCode: 'A1',
            spacePrefix: 'A-',
            count: 1,
            anchorX: 0,
            anchorY: 0,
            spaceWidth: -1,
            spaceLength: 5,
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}
