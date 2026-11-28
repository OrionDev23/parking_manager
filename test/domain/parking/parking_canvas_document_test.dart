import 'package:flutter_test/flutter_test.dart';
import 'package:parc_oto/domain/parking/parking_canvas_document.dart';
import 'package:parc_oto/domain/parking/parking_geometry.dart';

void main() {
  group('ParkingCanvasDocument', () {
    test('round trips versioned layers and world-coordinate geometry', () {
      final document = ParkingCanvasDocument(
        layers: [
          ParkingCanvasLayer(
            id: 'layer-circulation',
            type: ParkingCanvasLayerType.circulation,
            name: 'Circulation',
            objects: [
              ParkingCanvasObject(
                id: 'road-main',
                type: ParkingCanvasObjectType.road,
                points: const [
                  ParkingPoint(x: 2, y: 3),
                  ParkingPoint(x: 18, y: 3),
                  ParkingPoint(x: 18, y: 7),
                ],
                strokeWidthM: 0.2,
                strokeColorToken: 'border',
                fillColorToken: 'surfaceMuted',
              ),
              ParkingCanvasObject(
                id: 'entry-label',
                type: ParkingCanvasObjectType.text,
                points: const [ParkingPoint(x: 4, y: 8)],
                label: 'Entrée principale',
                textHeightM: 0.5,
                strokeColorToken: 'foreground',
              ),
            ],
          ),
        ],
      );

      document.validate(widthM: 20, heightM: 12);
      final encoded = document.encode();
      final decoded = ParkingCanvasDocument.fromJsonString(encoded);

      expect(decoded.schemaVersion, ParkingCanvasDocument.currentSchemaVersion);
      expect(decoded.layers, hasLength(1));
      expect(decoded.layers.single.type, ParkingCanvasLayerType.circulation);
      expect(decoded.layers.single.objects, hasLength(2));
      expect(decoded.layers.single.objects.first.points[1].x, 18);
      expect(decoded.layers.single.objects.first.strokeWidthM, 0.2);
      expect(decoded.layers.single.objects.last.label, 'Entrée principale');
    });

    test('provides default editor layers with a locked reference background',
        () {
      final document = ParkingCanvasDocument.withDefaultLayers();

      expect(document.layers, hasLength(5));
      expect(document.layers.first.type, ParkingCanvasLayerType.background);
      expect(document.layers.first.locked, isTrue);
      expect(document.layers.last.type, ParkingCanvasLayerType.annotations);
      document.validate(widthM: 80, heightM: 45);
    });

    test('reads legacy layer arrays without losing layer visibility or IDs', () {
      const legacy = '''
        [
          {"id":"spaces","type":"spaces","visible":true},
          {"id":"annotations","type":"annotations","locked":false}
        ]
      ''';

      final document = ParkingCanvasDocument.fromJsonString(legacy);

      expect(document.layers.map((layer) => layer.id), [
        'spaces',
        'annotations',
      ]);
      expect(
        document.layers.map((layer) => layer.type),
        [
          ParkingCanvasLayerType.spaces,
          ParkingCanvasLayerType.annotations,
        ],
      );
      expect(document.layers.first.visible, isTrue);
      expect(document.layers.last.locked, isFalse);
      document.validate(widthM: 80, heightM: 45);

      final migrated = ParkingCanvasDocument.fromJsonString(document.encode());
      expect(migrated.layers.map((layer) => layer.id), [
        'spaces',
        'annotations',
      ]);
    });

    test('translates all points without changing style or object identity', () {
      const object = ParkingCanvasObject(
        id: 'wall-01',
        type: ParkingCanvasObjectType.wall,
        points: [
          ParkingPoint(x: 2, y: 3),
          ParkingPoint(x: 8, y: 3),
        ],
        strokeWidthM: 0.15,
        rotationDegrees: 12,
      );

      final moved = object.translated(1.5, -1);

      expect(moved.id, object.id);
      expect(moved.points.first.x, 3.5);
      expect(moved.points.first.y, 2);
      expect(moved.points.last.x, 9.5);
      expect(moved.strokeWidthM, 0.15);
      expect(moved.rotationDegrees, 12);
    });

    test('rejects geometry outside the plan bounds', () {
      final document = ParkingCanvasDocument(
        layers: [
          ParkingCanvasLayer(
            id: 'layer-circulation',
            type: ParkingCanvasLayerType.circulation,
            name: 'Circulation',
            objects: [
              ParkingCanvasObject(
                id: 'road-outside',
                type: ParkingCanvasObjectType.line,
                points: const [
                  ParkingPoint(x: 2, y: 2),
                  ParkingPoint(x: 21, y: 2),
                ],
              ),
            ],
          ),
        ],
      );

      expect(
        () => document.validate(widthM: 20, heightM: 12),
        throwsFormatException,
      );
    });

    test('rejects duplicate layer IDs and duplicate object IDs', () {
      const firstLayer = ParkingCanvasLayer(
        id: 'layer-one',
        type: ParkingCanvasLayerType.annotations,
        name: 'First',
        objects: [
          ParkingCanvasObject(
            id: 'same-object',
            type: ParkingCanvasObjectType.text,
            points: [ParkingPoint(x: 1, y: 1)],
            label: 'First',
          ),
        ],
      );

      final duplicateLayerDocument = ParkingCanvasDocument(
        layers: [
          firstLayer,
          firstLayer.copyWith(name: 'Duplicate layer'),
        ],
      );
      expect(
        () => duplicateLayerDocument.validate(widthM: 10, heightM: 10),
        throwsFormatException,
      );

      final duplicateObjectDocument = ParkingCanvasDocument(
        layers: [
          firstLayer,
          const ParkingCanvasLayer(
            id: 'layer-two',
            type: ParkingCanvasLayerType.annotations,
            name: 'Second',
            objects: [
              ParkingCanvasObject(
                id: 'same-object',
                type: ParkingCanvasObjectType.text,
                points: [ParkingPoint(x: 2, y: 2)],
                label: 'Second',
              ),
            ],
          ),
        ],
      );
      expect(
        () => duplicateObjectDocument.validate(widthM: 10, heightM: 10),
        throwsFormatException,
      );
    });

    test('rejects unsupported schema versions and malformed object geometry',
        () {
      expect(
        () => ParkingCanvasDocument.fromJsonString(
          '{"schemaVersion":2,"layers":[]}',
        ),
        throwsFormatException,
      );

      final invalidRectangle = ParkingCanvasDocument(
        layers: [
          ParkingCanvasLayer(
            id: 'layer-zones',
            type: ParkingCanvasLayerType.zones,
            name: 'Zones',
            objects: [
              ParkingCanvasObject(
                id: 'invalid-rectangle',
                type: ParkingCanvasObjectType.rectangle,
                points: const [
                  ParkingPoint(x: 1, y: 1),
                  ParkingPoint(x: 4, y: 1),
                  ParkingPoint(x: 4, y: 4),
                ],
              ),
            ],
          ),
        ],
      );

      expect(
        () => invalidRectangle.validate(widthM: 10, heightM: 10),
        throwsFormatException,
      );
    });

    test('rejects unsafe color tokens', () {
      final document = ParkingCanvasDocument(
        layers: [
          ParkingCanvasLayer(
            id: 'layer-obstacles',
            type: ParkingCanvasLayerType.circulation,
            name: 'Circulation',
            objects: [
              ParkingCanvasObject(
                id: 'obstacle-01',
                type: ParkingCanvasObjectType.obstacle,
                points: const [
                  ParkingPoint(x: 1, y: 1),
                  ParkingPoint(x: 3, y: 1),
                  ParkingPoint(x: 2, y: 3),
                ],
                fillColorToken: '#FF0000',
              ),
            ],
          ),
        ],
      );

      expect(
        () => document.validate(widthM: 10, heightM: 10),
        throwsArgumentError,
      );
    });
  });
}
