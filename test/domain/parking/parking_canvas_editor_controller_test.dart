import 'package:flutter_test/flutter_test.dart';
import 'package:parc_oto/domain/parking/parking_canvas_document.dart';
import 'package:parc_oto/domain/parking/parking_canvas_editor_controller.dart';
import 'package:parc_oto/domain/parking/parking_geometry.dart';

void main() {
  ParkingCanvasDocument documentWithObject() => ParkingCanvasDocument(
        layers: [
          const ParkingCanvasLayer(
            id: 'layer-circulation',
            type: ParkingCanvasLayerType.circulation,
            name: 'Circulation',
            objects: [
              ParkingCanvasObject(
                id: 'road-01',
                type: ParkingCanvasObjectType.line,
                points: [
                  ParkingPoint(x: 2, y: 2),
                  ParkingPoint(x: 8, y: 2),
                ],
              ),
            ],
          ),
          const ParkingCanvasLayer(
            id: 'layer-annotations',
            type: ParkingCanvasLayerType.annotations,
            name: 'Annotations',
          ),
        ],
      );

  group('ParkingCanvasCamera', () {
    test('converts world and screen coordinates in a metric plan', () {
      const camera = ParkingCanvasCamera(
        pixelsPerMeter: 10,
        offsetX: 20,
        offsetY: 30,
      );
      final screen = camera.worldToScreen(
        const ParkingPoint(x: 4, y: 3),
        layoutHeightM: 12,
      );
      final world = camera.screenToWorld(screen, layoutHeightM: 12);

      expect(screen.x, 60);
      expect(screen.y, 120);
      expect(world.x, closeTo(4, 1e-10));
      expect(world.y, closeTo(3, 1e-10));
    });

    test('keeps the cursor world position fixed when zooming', () {
      const camera = ParkingCanvasCamera(
        pixelsPerMeter: 10,
        offsetX: 15,
        offsetY: 20,
      );
      const cursor = ParkingPoint(x: 150, y: 90);
      final before = camera.screenToWorld(cursor, layoutHeightM: 20);
      final zoomed = camera.zoomAt(
        screenX: cursor.x,
        screenY: cursor.y,
        factor: 2,
        layoutHeightM: 20,
      );
      final after = zoomed.screenToWorld(cursor, layoutHeightM: 20);

      expect(zoomed.pixelsPerMeter, 20);
      expect(after.x, closeTo(before.x, 1e-10));
      expect(after.y, closeTo(before.y, 1e-10));
    });

    test('pans without changing the metric scale', () {
      const camera = ParkingCanvasCamera(pixelsPerMeter: 15);
      final moved = camera.panBy(12, -8);

      expect(moved.offsetX, 12);
      expect(moved.offsetY, -8);
      expect(moved.pixelsPerMeter, 15);
    });
  });

  group('ParkingCanvasEditorController', () {
    test('moves selected objects and snaps the anchor to the metric grid', () {
      final editor = ParkingCanvasEditorController(
        document: documentWithObject(),
        widthM: 20,
        heightM: 12,
      );

      editor.selectObjects(['road-01']);
      editor.moveSelection(1.2, 0.2, snapToGrid: true, gridStepM: 0.5);

      final object = editor.document.layers.first.objects.single;
      expect(object.points.first.x, 3);
      expect(object.points.first.y, 2);
      expect(object.points.last.x, 9);
      expect(object.points.last.y, 2);
    });

    test('supports undo and redo for document mutations', () {
      final editor = ParkingCanvasEditorController(
        document: documentWithObject(),
        widthM: 20,
        heightM: 12,
      );
      editor.selectObjects(['road-01']);
      editor.moveSelection(2, 1);

      expect(editor.document.layers.first.objects.single.points.first.x, 4);
      expect(editor.canUndo, isTrue);

      editor.undo();
      expect(editor.document.layers.first.objects.single.points.first.x, 2);
      expect(editor.canRedo, isTrue);

      editor.redo();
      expect(editor.document.layers.first.objects.single.points.first.x, 4);
    });

    test('adds and deletes objects in editable layers', () {
      final editor = ParkingCanvasEditorController(
        document: documentWithObject(),
        widthM: 20,
        heightM: 12,
      );
      editor.addObject(
        'layer-annotations',
        const ParkingCanvasObject(
          id: 'label-01',
          type: ParkingCanvasObjectType.text,
          points: [ParkingPoint(x: 4, y: 5)],
          label: 'Entrée',
        ),
      );
      expect(editor.selectedObjectIds, {'label-01'});

      editor.deleteSelection();
      expect(
        editor.document.layers.last.objects,
        isEmpty,
      );
    });

    test('duplicates selected objects with new IDs and stable geometry', () {
      final editor = ParkingCanvasEditorController(
        document: documentWithObject(),
        widthM: 20,
        heightM: 12,
      );
      editor.selectObjects(['road-01']);
      editor.duplicateSelection(
        idFactory: (sourceId) => '$sourceId-copy',
      );

      expect(editor.document.layers.first.objects, hasLength(2));
      expect(editor.selectedObjectIds, {'road-01-copy'});
      expect(
        editor.document.layers.first.objects.last.points.first.x,
        2.5,
      );
    });

    test('refuses mutations on locked layers or objects', () {
      final document = ParkingCanvasDocument(
        layers: [
          const ParkingCanvasLayer(
            id: 'layer-locked',
            type: ParkingCanvasLayerType.annotations,
            name: 'Locked',
            locked: true,
            objects: [
              ParkingCanvasObject(
                id: 'locked-label',
                type: ParkingCanvasObjectType.text,
                points: [ParkingPoint(x: 1, y: 1)],
                label: 'Locked',
              ),
            ],
          ),
        ],
      );
      final editor = ParkingCanvasEditorController(
        document: document,
        widthM: 10,
        heightM: 10,
      );
      editor.selectObjects(['locked-label']);
      expect(
        () => editor.moveSelection(1, 1),
        throwsStateError,
      );
      expect(
        () => editor.addObject(
          'layer-locked',
          const ParkingCanvasObject(
            id: 'other-label',
            type: ParkingCanvasObjectType.text,
            points: [ParkingPoint(x: 2, y: 2)],
            label: 'Other',
          ),
        ),
        throwsStateError,
      );
    });

    test('groups a continuous drag into one undo transaction', () {
      final editor = ParkingCanvasEditorController(
        document: documentWithObject(),
        widthM: 20,
        heightM: 12,
      );
      editor.selectObjects(['road-01']);
      editor.beginTransaction();
      editor.moveSelection(0.5, 0);
      editor.moveSelection(0.5, 0);
      editor.moveSelection(1, 0);

      expect(editor.canUndo, isFalse);
      editor.commitTransaction();
      expect(editor.canUndo, isTrue);

      editor.undo();
      expect(editor.document.layers.first.objects.single.points.first.x, 2);
      expect(editor.canUndo, isFalse);
    });

    test('undo history is bounded', () {
      final editor = ParkingCanvasEditorController(
        document: documentWithObject(),
        widthM: 20,
        heightM: 12,
        historyLimit: 2,
      );
      editor.selectObjects(['road-01']);
      editor.moveSelection(1, 0);
      editor.moveSelection(1, 0);
      editor.moveSelection(1, 0);

      editor.undo();
      editor.undo();
      expect(editor.canUndo, isFalse);
      expect(editor.document.layers.first.objects.single.points.first.x, 3);
    });
  });
}
