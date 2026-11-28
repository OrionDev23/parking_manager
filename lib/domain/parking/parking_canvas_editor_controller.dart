import 'parking_canvas_document.dart';
import 'parking_geometry.dart';

enum ParkingCanvasTool {
  select,
  hand,
  rectangle,
  polygon,
  line,
  road,
  wall,
  gate,
  entrance,
  exit,
  obstacle,
  text,
  dimension,
  measure,
}

class ParkingCanvasCamera {
  static const double minScale = 0.05;
  static const double maxScale = 200;

  final double pixelsPerMeter;
  final double offsetX;
  final double offsetY;

  const ParkingCanvasCamera({
    this.pixelsPerMeter = 12,
    this.offsetX = 0,
    this.offsetY = 0,
  });

  void validate() {
    if (!pixelsPerMeter.isFinite ||
        pixelsPerMeter < minScale ||
        pixelsPerMeter > maxScale ||
        !offsetX.isFinite ||
        !offsetY.isFinite) {
      throw ArgumentError('Canvas camera contains invalid scale or offsets.');
    }
  }

  ParkingPoint worldToScreen(
    ParkingPoint point, {
    required double layoutHeightM,
  }) {
    validate();
    if (!layoutHeightM.isFinite || layoutHeightM <= 0) {
      throw ArgumentError.value(layoutHeightM, 'layoutHeightM');
    }
    return ParkingPoint(
      x: offsetX + point.x * pixelsPerMeter,
      y: offsetY + (layoutHeightM - point.y) * pixelsPerMeter,
    );
  }

  ParkingPoint screenToWorld(
    ParkingPoint point, {
    required double layoutHeightM,
  }) {
    validate();
    if (!layoutHeightM.isFinite || layoutHeightM <= 0) {
      throw ArgumentError.value(layoutHeightM, 'layoutHeightM');
    }
    return ParkingPoint(
      x: (point.x - offsetX) / pixelsPerMeter,
      y: layoutHeightM - (point.y - offsetY) / pixelsPerMeter,
    );
  }

  ParkingCanvasCamera panBy(double deltaX, double deltaY) {
    if (!deltaX.isFinite || !deltaY.isFinite) {
      throw ArgumentError('Camera pan must contain finite values.');
    }
    return ParkingCanvasCamera(
      pixelsPerMeter: pixelsPerMeter,
      offsetX: offsetX + deltaX,
      offsetY: offsetY + deltaY,
    );
  }

  /// Zooms around a screen coordinate without moving the world point under it.
  ParkingCanvasCamera zoomAt({
    required double screenX,
    required double screenY,
    required double factor,
    required double layoutHeightM,
  }) {
    validate();
    if (!screenX.isFinite ||
        !screenY.isFinite ||
        !factor.isFinite ||
        factor <= 0) {
      throw ArgumentError('Camera zoom parameters must be finite and positive.');
    }
    final worldAnchor = screenToWorld(
      ParkingPoint(x: screenX, y: screenY),
      layoutHeightM: layoutHeightM,
    );
    final nextScale =
        (pixelsPerMeter * factor).clamp(minScale, maxScale).toDouble();
    final next = ParkingCanvasCamera(
      pixelsPerMeter: nextScale,
      offsetX: screenX - worldAnchor.x * nextScale,
      offsetY: screenY - (layoutHeightM - worldAnchor.y) * nextScale,
    );
    next.validate();
    return next;
  }
}

/// Pure-Dart editing session. UI widgets own rendering and gestures; this
/// controller owns document mutations, selection and undo/redo invariants.
class ParkingCanvasEditorController {
  final double widthM;
  final double heightM;
  final int historyLimit;

  ParkingCanvasDocument _document;
  ParkingCanvasDocument? _transactionBase;
  final List<ParkingCanvasDocument> _undoHistory = [];
  final List<ParkingCanvasDocument> _redoHistory = [];
  Set<String> _selectedObjectIds = {};
  String? _activeLayerId;
  ParkingCanvasTool _activeTool = ParkingCanvasTool.select;

  factory ParkingCanvasEditorController({
    required ParkingCanvasDocument document,
    required double widthM,
    required double heightM,
    int historyLimit = 100,
  }) =>
      ParkingCanvasEditorController._(
        document: document,
        widthM: widthM,
        heightM: heightM,
        historyLimit: historyLimit,
      );

  ParkingCanvasEditorController._({
    required this._document,
    required this.widthM,
    required this.heightM,
    required this.historyLimit,
  }) {
    if (historyLimit < 1 || historyLimit > 1000) {
      throw RangeError.range(historyLimit, 1, 1000, 'historyLimit');
    }
    _document.validate(widthM: widthM, heightM: heightM);
    _activeLayerId = _document.layers.isEmpty ? null : _document.layers.first.id;
  }

  ParkingCanvasDocument get document => _document;
  Set<String> get selectedObjectIds =>
      Set<String>.unmodifiable(_selectedObjectIds);
  String? get activeLayerId => _activeLayerId;

  void beginTransaction() {
    if (_transactionBase != null) {
      throw StateError('A canvas edit transaction is already open.');
    }
    _transactionBase = _document;
  }

  void commitTransaction() {
    final base = _transactionBase;
    if (base == null) return;
    _transactionBase = null;
    if (identical(base, _document)) return;
    _recordUndo(base);
    _redoHistory.clear();
  }

  void rollbackTransaction() {
    final base = _transactionBase;
    if (base == null) return;
    _transactionBase = null;
    _document = base;
    _retainValidSelection();
  }
  ParkingCanvasTool get activeTool => _activeTool;
  bool get canUndo => _undoHistory.isNotEmpty;
  bool get canRedo => _redoHistory.isNotEmpty;

  void setActiveTool(ParkingCanvasTool tool) {
    _activeTool = tool;
  }

  void setActiveLayer(String layerId) {
    if (!_document.layers.any((layer) => layer.id == layerId)) {
      throw StateError('Canvas layer does not exist.');
    }
    _activeLayerId = layerId;
  }

  void selectObjects(Iterable<String> ids, {bool additive = false}) {
    final available = <String>{
      for (final layer in _document.layers)
        if (layer.visible)
          for (final object in layer.objects)
            if (object.visible) object.id,
    };
    final next = additive ? {..._selectedObjectIds} : <String>{};
    next.addAll(ids.where(available.contains));
    _selectedObjectIds = next;
  }

  void clearSelection() {
    _selectedObjectIds = {};
  }

  void addObject(String layerId, ParkingCanvasObject object) {
    final layerIndex =
        _document.layers.indexWhere((layer) => layer.id == layerId);
    if (layerIndex < 0) throw StateError('Canvas layer does not exist.');
    final layer = _document.layers[layerIndex];
    if (layer.locked) throw StateError('Canvas layer is locked.');
    object.validate();
    if (_findObject(object.id) != null) {
      throw StateError('Canvas object ID already exists.');
    }
    final nextLayers = [..._document.layers];
    nextLayers[layerIndex] = layer.copyWith(
      objects: [...layer.objects, object],
    );
    _commit(_document.copyWith(layers: nextLayers));
    _activeLayerId = layerId;
    _selectedObjectIds = {object.id};
  }

  void updateObject(String layerId, ParkingCanvasObject updated) {
    final layerIndex =
        _document.layers.indexWhere((layer) => layer.id == layerId);
    if (layerIndex < 0) throw StateError('Canvas layer does not exist.');
    final layer = _document.layers[layerIndex];
    if (layer.locked) throw StateError('Canvas layer is locked.');
    final objectIndex =
        layer.objects.indexWhere((object) => object.id == updated.id);
    if (objectIndex < 0) throw StateError('Canvas object does not exist.');
    if (layer.objects[objectIndex].locked) {
      throw StateError('Canvas object is locked.');
    }
    updated.validate();
    final nextObjects = [...layer.objects];
    nextObjects[objectIndex] = updated;
    final nextLayers = [..._document.layers];
    nextLayers[layerIndex] = layer.copyWith(objects: nextObjects);
    _commit(_document.copyWith(layers: nextLayers));
  }

  void moveSelection(
    double deltaX,
    double deltaY, {
    bool snapToGrid = false,
    double? gridStepM,
  }) {
    if (_selectedObjectIds.isEmpty) return;
    if (!deltaX.isFinite || !deltaY.isFinite) {
      throw ArgumentError('Canvas movement must contain finite values.');
    }
    var effectiveX = deltaX;
    var effectiveY = deltaY;

    if (snapToGrid) {
      final step = gridStepM;
      if (step == null || !step.isFinite || step <= 0) {
        throw ArgumentError.value(step, 'gridStepM');
      }
      final firstPoint = _firstSelectedPoint();
      if (firstPoint == null) return;
      effectiveX =
          ((firstPoint.x + deltaX) / step).round() * step - firstPoint.x;
      effectiveY =
          ((firstPoint.y + deltaY) / step).round() * step - firstPoint.y;
    }
    if (effectiveX == 0 && effectiveY == 0) return;

    final selectedLayers = <String, ParkingCanvasLayer>{};
    for (final layer in _document.layers) {
      final selected = layer.objects
          .where((object) => _selectedObjectIds.contains(object.id))
          .toList(growable: false);
      if (selected.isEmpty) continue;
      if (layer.locked || selected.any((object) => object.locked)) {
        throw StateError('A selected canvas object is locked.');
      }
      selectedLayers[layer.id] = layer.copyWith(
        objects: [
          for (final object in layer.objects)
            _selectedObjectIds.contains(object.id)
                ? object.translated(effectiveX, effectiveY)
                : object,
        ],
      );
    }
    final nextLayers = [
      for (final layer in _document.layers)
        selectedLayers[layer.id] ?? layer,
    ];
    _commit(_document.copyWith(layers: nextLayers));
  }

  void deleteSelection() {
    if (_selectedObjectIds.isEmpty) return;
    final nextLayers = <ParkingCanvasLayer>[];
    var removed = 0;
    for (final layer in _document.layers) {
      final selected = layer.objects
          .where((object) => _selectedObjectIds.contains(object.id))
          .toList(growable: false);
      if (selected.isEmpty) {
        nextLayers.add(layer);
        continue;
      }
      if (layer.locked || selected.any((object) => object.locked)) {
        throw StateError('A selected canvas object is locked.');
      }
      final retained = layer.objects
          .where((object) => !_selectedObjectIds.contains(object.id))
          .toList(growable: false);
      removed += selected.length;
      nextLayers.add(layer.copyWith(objects: retained));
    }
    if (removed == 0) {
      _selectedObjectIds = {};
      return;
    }
    _commit(_document.copyWith(layers: nextLayers));
    _selectedObjectIds = {};
  }

  void duplicateSelection({
    required String Function(String sourceId) idFactory,
    double offsetXM = 0.5,
    double offsetYM = 0.5,
  }) {
    if (_selectedObjectIds.isEmpty) return;
    if (!offsetXM.isFinite || !offsetYM.isFinite) {
      throw ArgumentError('Duplicate offset must be finite.');
    }
    final newIds = <String>{};
    final nextLayers = <ParkingCanvasLayer>[];
    for (final layer in _document.layers) {
      final selected = layer.objects
          .where((object) => _selectedObjectIds.contains(object.id))
          .toList(growable: false);
      if (selected.isEmpty) {
        nextLayers.add(layer);
        continue;
      }
      if (layer.locked || selected.any((object) => object.locked)) {
        throw StateError('A selected canvas object is locked.');
      }
      final duplicates = <ParkingCanvasObject>[];
      for (final object in selected) {
        final id = idFactory(object.id);
        if (!newIds.add(id)) {
          throw StateError('Duplicate ID factory returned a repeated ID.');
        }
        duplicates.add(
          object.translated(offsetXM, offsetYM).copyWith(id: id),
        );
      }
      nextLayers.add(
        layer.copyWith(objects: [...layer.objects, ...duplicates]),
      );
    }
    if (newIds.isEmpty) return;
    _commit(_document.copyWith(layers: nextLayers));
    _selectedObjectIds = newIds;
  }

  void setLayerVisibility(String layerId, bool visible) {
    final index = _document.layers.indexWhere((layer) => layer.id == layerId);
    if (index < 0) throw StateError('Canvas layer does not exist.');
    final layer = _document.layers[index];
    if (layer.visible == visible) return;
    final layers = [..._document.layers];
    layers[index] = layer.copyWith(visible: visible);
    _commit(_document.copyWith(layers: layers));
    if (!visible) {
      _selectedObjectIds.removeWhere(
        (id) => layer.objects.any((object) => object.id == id),
      );
    }
  }

  void setLayerLocked(String layerId, bool locked) {
    final index = _document.layers.indexWhere((layer) => layer.id == layerId);
    if (index < 0) throw StateError('Canvas layer does not exist.');
    final layer = _document.layers[index];
    if (layer.locked == locked) return;
    final layers = [..._document.layers];
    layers[index] = layer.copyWith(locked: locked);
    _commit(_document.copyWith(layers: layers));
    if (locked) {
      _selectedObjectIds.removeWhere(
        (id) => layer.objects.any((object) => object.id == id),
      );
    }
  }

  void undo() {
    commitTransaction();
    if (!canUndo) return;
    _redoHistory.add(_document);
    _document = _undoHistory.removeLast();
    _retainValidSelection();
  }

  void redo() {
    commitTransaction();
    if (!canRedo) return;
    _undoHistory.add(_document);
    _document = _redoHistory.removeLast();
    _retainValidSelection();
  }

  void _commit(ParkingCanvasDocument next) {
    next.validate(widthM: widthM, heightM: heightM);
    if (_transactionBase == null) {
      _recordUndo(_document);
      _redoHistory.clear();
    }
    _document = next;
  }

  void _recordUndo(ParkingCanvasDocument document) {
    _undoHistory.add(document);
    if (_undoHistory.length > historyLimit) {
      _undoHistory.removeAt(0);
    }
  }

  ParkingCanvasObject? _findObject(String id) {
    for (final layer in _document.layers) {
      for (final object in layer.objects) {
        if (object.id == id) return object;
      }
    }
    return null;
  }

  ParkingPoint? _firstSelectedPoint() {
    for (final layer in _document.layers) {
      for (final object in layer.objects) {
        if (_selectedObjectIds.contains(object.id) && object.points.isNotEmpty) {
          return object.points.first;
        }
      }
    }
    return null;
  }

  void _retainValidSelection() {
    final available = <String>{
      for (final layer in _document.layers)
        if (layer.visible && !layer.locked)
          for (final object in layer.objects)
            if (object.visible && !object.locked) object.id,
    };
    _selectedObjectIds.retainAll(available);
    if (!_document.layers.any((layer) => layer.id == _activeLayerId)) {
      _activeLayerId =
          _document.layers.isEmpty ? null : _document.layers.first.id;
    }
  }
}
