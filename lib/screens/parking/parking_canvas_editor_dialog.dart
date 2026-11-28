import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fluent_ui/fluent_ui.dart';

import '../../domain/parking/parking_canvas_document.dart';
import '../../domain/parking/parking_canvas_editor_controller.dart';
import '../../domain/parking/parking_models.dart';

class ParkingCanvasEditorDialog extends StatefulWidget {
  final ParkingLayout layout;
  final ParkingCanvasDocument document;
  final List<ParkingZone> zones;
  final List<ParkingSpace> spaces;
  final Uint8List? backgroundBytes;
  final int? backgroundPixelWidth;
  final int? backgroundPixelHeight;
  final Color primaryColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedColor;

  const ParkingCanvasEditorDialog({
    super.key,
    required this.layout,
    required this.document,
    required this.zones,
    required this.spaces,
    required this.backgroundBytes,
    required this.backgroundPixelWidth,
    required this.backgroundPixelHeight,
    required this.primaryColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  State<ParkingCanvasEditorDialog> createState() =>
      _ParkingCanvasEditorDialogState();
}

class _ParkingCanvasEditorDialogState extends State<ParkingCanvasEditorDialog> {
  late final ParkingCanvasEditorController _editor;
  final TextEditingController _labelController = TextEditingController();
  ParkingCanvasCamera? _camera;
  ui.Image? _backgroundImage;
  int _decodeGeneration = 0;
  int _idCounter = 0;
  double _lastScale = 1;
  ui.Size? _canvasSize;
  String? _error;
  bool _snapToGrid = true;
  bool _draggingSelection = false;
  bool _draggingCamera = false;
  ui.Offset? _lastScreenPosition;
  List<ParkingPoint> _polygonPoints = [];
  ParkingPoint? _draftStart;
  ParkingPoint? _draftEnd;

  @override
  void initState() {
    super.initState();
    _editor = ParkingCanvasEditorController(
      document: widget.document,
      widthM: widget.layout.widthM,
      heightM: widget.layout.heightM,
    );
    _decodeBackground();
  }

  @override
  void dispose() {
    _decodeGeneration++;
    _backgroundImage?.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _decodeBackground() async {
    final generation = ++_decodeGeneration;
    final bytes = widget.backgroundBytes;
    if (bytes == null || bytes.isEmpty) return;

    ui.Codec? codec;
    ui.Image? decoded;
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final sourceWidth =
          widget.backgroundPixelWidth ?? descriptor.width;
      final sourceHeight =
          widget.backgroundPixelHeight ?? descriptor.height;
      final scale = math.min(1.0, 2400 / math.max(sourceWidth, sourceHeight));
      final targetWidth = math.max(1, (sourceWidth * scale).round()).toInt();
      final targetHeight = math.max(1, (sourceHeight * scale).round()).toInt();
      codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      decoded = (await codec.getNextFrame()).image;
    } catch (_) {
      decoded?.dispose();
      return;
    } finally {
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }

    if (!mounted || generation != _decodeGeneration) {
      decoded.dispose();
      return;
    }
    final previous = _backgroundImage;
    setState(() => _backgroundImage = decoded);
    previous?.dispose();
  }

  String _toolLabel(ParkingCanvasTool tool) {
    switch (tool) {
      case ParkingCanvasTool.select:
        return 'Sélection';
      case ParkingCanvasTool.hand:
        return 'Déplacer le plan';
      case ParkingCanvasTool.rectangle:
        return 'Rectangle';
      case ParkingCanvasTool.polygon:
        return 'Polygone';
      case ParkingCanvasTool.line:
        return 'Ligne';
      case ParkingCanvasTool.road:
        return 'Voie';
      case ParkingCanvasTool.wall:
        return 'Mur';
      case ParkingCanvasTool.gate:
        return 'Portail';
      case ParkingCanvasTool.entrance:
        return 'Entrée';
      case ParkingCanvasTool.exit:
        return 'Sortie';
      case ParkingCanvasTool.obstacle:
        return 'Obstacle';
      case ParkingCanvasTool.text:
        return 'Texte';
      case ParkingCanvasTool.dimension:
        return 'Cote';
      case ParkingCanvasTool.measure:
        return 'Mesure';
    }
  }

  ParkingCanvasCamera _fitCamera(ui.Size size) {
    const padding = 32.0;
    final scale = math.min(
      (size.width - padding * 2) / widget.layout.widthM,
      (size.height - padding * 2) / widget.layout.heightM,
    ).clamp(
      ParkingCanvasCamera.minScale,
      ParkingCanvasCamera.maxScale,
    ).toDouble();
    return ParkingCanvasCamera(
      pixelsPerMeter: scale,
      offsetX: (size.width - widget.layout.widthM * scale) / 2,
      offsetY: (size.height - widget.layout.heightM * scale) / 2,
    );
  }

  ParkingCanvasCamera _cameraFor(ui.Size size) =>
      _camera ?? _fitCamera(size);

  ParkingPoint _toWorld(ui.Offset screen, ParkingCanvasCamera camera) =>
      camera.screenToWorld(
        ParkingPoint(x: screen.dx, y: screen.dy),
        layoutHeightM: widget.layout.heightM,
      );

  String? _hitTest(ParkingPoint point) {
    const toleranceM = 0.35;
    for (final layer in _editor.document.layers.reversed) {
      if (!layer.visible) continue;
      for (final object in layer.objects.reversed) {
        if (!object.visible || object.points.isEmpty) continue;
        final bounds = object.bounds;
        if (point.x >= bounds.minX - toleranceM &&
            point.x <= bounds.maxX + toleranceM &&
            point.y >= bounds.minY - toleranceM &&
            point.y <= bounds.maxY + toleranceM) {
          return object.id;
        }
      }
    }
    return null;
  }

  void _syncSelectedLabel() {
    final id = _editor.selectedObjectIds.length == 1
        ? _editor.selectedObjectIds.first
        : null;
    ParkingCanvasObject? selected;
    if (id != null) {
      for (final layer in _editor.document.layers) {
        for (final object in layer.objects) {
          if (object.id == id) selected = object;
        }
      }
    }
    _labelController.text = selected?.label ?? '';
  }

  void _onScaleStart(ScaleStartDetails details) {
    final size = _canvasSize;
    if (size == null) return;
    final camera = _cameraFor(size);
    final tool = _editor.activeTool;
    final screen = details.localFocalPoint;
    _lastScale = 1;

    setState(() {
      _lastScreenPosition = screen;
      _draggingSelection = false;
      _draggingCamera = tool == ParkingCanvasTool.hand;
      _draftStart = null;
      _draftEnd = null;
      if (tool == ParkingCanvasTool.select) {
        final hit = _hitTest(_toWorld(screen, camera));
        if (hit == null) {
          _editor.clearSelection();
        } else {
          _editor.selectObjects([hit]);
          _editor.beginTransaction();
          _draggingSelection = true;
        }
        _syncSelectedLabel();
      } else if (tool != ParkingCanvasTool.hand &&
          tool != ParkingCanvasTool.polygon &&
          tool != ParkingCanvasTool.text) {
        final point = _toWorld(screen, camera);
        _draftStart = point;
        _draftEnd = point;
      }
      _camera = camera;
    });
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final size = _canvasSize;
    if (size == null) return;
    final camera = _cameraFor(size);
    final screen = details.localFocalPoint;
    final previousScreen = _lastScreenPosition ?? screen;

    if (details.pointerCount > 1 && details.scale != 1) {
      final factor = details.scale / _lastScale;
      setState(() {
        _camera = camera.zoomAt(
          screenX: screen.dx,
          screenY: screen.dy,
          factor: factor,
          layoutHeightM: widget.layout.heightM,
        );
        _lastScale = details.scale;
      });
      return;
    }

    if (_draggingCamera) {
      setState(() {
        _camera = camera.panBy(
          screen.dx - previousScreen.dx,
          screen.dy - previousScreen.dy,
        );
        _lastScreenPosition = screen;
      });
      return;
    }

    if (_draftStart != null) {
      setState(() {
        _draftEnd = _toWorld(screen, camera);
        _lastScreenPosition = screen;
      });
      return;
    }

    if (_draggingSelection && _editor.selectedObjectIds.isNotEmpty) {
      final previousWorld = _toWorld(previousScreen, camera);
      final currentWorld = _toWorld(screen, camera);
      try {
        _editor.moveSelection(
          currentWorld.x - previousWorld.x,
          currentWorld.y - previousWorld.y,
        );
        setState(() => _lastScreenPosition = screen);
      } catch (error) {
        _editor.rollbackTransaction();
        setState(() {
          _error = error.toString();
          _draggingSelection = false;
        });
      }
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_draggingSelection && _snapToGrid) {
      try {
        _editor.moveSelection(
          0,
          0,
          snapToGrid: true,
          gridStepM: widget.layout.gridStepM,
        );
      } catch (error) {
        _editor.rollbackTransaction();
        setState(() => _error = error.toString());
      }
    }
    _editor.commitTransaction();
    if (_draftStart != null && _draftEnd != null) {
      _commitDraft(_draftStart!, _draftEnd!);
    }
    setState(() {
      _draftStart = null;
      _draftEnd = null;
      _draggingSelection = false;
      _draggingCamera = false;
      _lastScreenPosition = null;
      _lastScale = 1;
    });
  }

  void _onCanvasTap(TapUpDetails details) {
    final size = _canvasSize;
    if (size == null) return;
    final point = _toWorld(details.localPosition, _cameraFor(size));
    final tool = _editor.activeTool;

    if (tool == ParkingCanvasTool.text) {
      _addObject(
        ParkingCanvasObject(
          id: _newId(),
          type: ParkingCanvasObjectType.text,
          points: [point],
          label: 'Texte',
          textHeightM: 0.6,
          strokeColorToken: 'text',
        ),
      );
    } else if (tool == ParkingCanvasTool.polygon) {
      setState(() {
        _polygonPoints = [..._polygonPoints, point];
        _error = null;
      });
    }
  }

  void _finishPolygon() {
    if (_polygonPoints.length < 3) {
      setState(() => _error = 'Un polygone nécessite au moins trois points.');
      return;
    }
    _addObject(
      ParkingCanvasObject(
        id: _newId(),
        type: ParkingCanvasObjectType.polygon,
        points: [..._polygonPoints],
        strokeWidthM: 0.08,
        strokeColorToken: 'primary',
        fillColorToken: 'primary',
      ),
    );
    setState(() => _polygonPoints = []);
  }

  void _cancelPolygon() {
    setState(() => _polygonPoints = []);
  }

  void _commitDraft(ParkingPoint start, ParkingPoint end) {
    final tool = _editor.activeTool;
    final minX = math.min(start.x, end.x).toDouble();
    final maxX = math.max(start.x, end.x).toDouble();
    final minY = math.min(start.y, end.y).toDouble();
    final maxY = math.max(start.y, end.y).toDouble();
    if (maxX - minX < 0.15 && maxY - minY < 0.15) return;

    if (tool == ParkingCanvasTool.rectangle ||
        tool == ParkingCanvasTool.obstacle) {
      var left = minX;
      var right = maxX;
      var bottom = minY;
      var top = maxY;
      if (_snapToGrid) {
        final step = widget.layout.gridStepM;
        left = (left / step).round() * step;
        right = (right / step).round() * step;
        bottom = (bottom / step).round() * step;
        top = (top / step).round() * step;
      }
      if (right - left < 0.15 || top - bottom < 0.15) return;
      _addObject(
        ParkingCanvasObject(
          id: _newId(),
          type: tool == ParkingCanvasTool.rectangle
              ? ParkingCanvasObjectType.rectangle
              : ParkingCanvasObjectType.obstacle,
          points: [
            ParkingPoint(x: left, y: bottom),
            ParkingPoint(x: right, y: bottom),
            ParkingPoint(x: right, y: top),
            ParkingPoint(x: left, y: top),
          ],
          strokeColorToken: 'primary',
          fillColorToken:
              tool == ParkingCanvasTool.obstacle ? 'warning' : null,
        ),
      );
      return;
    }

    if (_snapToGrid) {
      final step = widget.layout.gridStepM;
      start = ParkingPoint(
        x: (start.x / step).round() * step,
        y: (start.y / step).round() * step,
      );
      end = ParkingPoint(
        x: (end.x / step).round() * step,
        y: (end.y / step).round() * step,
      );
    }
    final distance = math.sqrt(
      math.pow(end.x - start.x, 2) + math.pow(end.y - start.y, 2),
    );
    if (distance < 0.15) return;
    final type = switch (tool) {
      ParkingCanvasTool.line => ParkingCanvasObjectType.line,
      ParkingCanvasTool.road => ParkingCanvasObjectType.road,
      ParkingCanvasTool.wall => ParkingCanvasObjectType.wall,
      ParkingCanvasTool.gate => ParkingCanvasObjectType.gate,
      ParkingCanvasTool.entrance => ParkingCanvasObjectType.entrance,
      ParkingCanvasTool.exit => ParkingCanvasObjectType.exit,
      ParkingCanvasTool.dimension ||
      ParkingCanvasTool.measure => ParkingCanvasObjectType.dimension,
      _ => ParkingCanvasObjectType.line,
    };
    final label = type == ParkingCanvasObjectType.dimension
        ? '${distance.toStringAsFixed(2)} m'
        : null;
    _addObject(
      ParkingCanvasObject(
        id: _newId(),
        type: type,
        points: [start, end],
        strokeWidthM: tool == ParkingCanvasTool.road ? 3 : 0.08,
        strokeColorToken: tool == ParkingCanvasTool.entrance
            ? 'success'
            : tool == ParkingCanvasTool.exit
                ? 'danger'
                : 'primary',
        label: label,
      ),
    );
  }

  String _newId() {
    _idCounter++;
    return 'canvas_${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
  }

  void _addObject(ParkingCanvasObject object) {
    final document = _editor.document;
    final preferredType = object.type == ParkingCanvasObjectType.text ||
            object.type == ParkingCanvasObjectType.dimension
        ? ParkingCanvasLayerType.annotations
        : ParkingCanvasLayerType.circulation;
    ParkingCanvasLayer? target;
    for (final layer in document.layers) {
      if (!layer.locked && layer.type == preferredType) {
        target = layer;
        break;
      }
    }
    if (target == null) {
      for (final layer in document.layers) {
        if (!layer.locked) {
          target = layer;
          break;
        }
      }
    }
    if (target == null) {
      setState(() => _error = 'Aucun calque modifiable n’est disponible.');
      return;
    }
    try {
      _editor.addObject(target.id, object);
      _editor.selectObjects([object.id]);
      _syncSelectedLabel();
      setState(() => _error = null);
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }

  ParkingCanvasObject? get _singleSelectedObject {
    if (_editor.selectedObjectIds.length != 1) return null;
    final id = _editor.selectedObjectIds.first;
    for (final layer in _editor.document.layers) {
      for (final object in layer.objects) {
        if (object.id == id) return object;
      }
    }
    return null;
  }

  ParkingCanvasLayer? get _layerForSelectedObject {
    final selected = _singleSelectedObject;
    if (selected == null) return null;
    for (final layer in _editor.document.layers) {
      if (layer.objects.any((object) => object.id == selected.id)) {
        return layer;
      }
    }
    return null;
  }

  void _applyLabel() {
    final object = _singleSelectedObject;
    final layer = _layerForSelectedObject;
    if (object == null || layer == null) return;
    try {
      _editor.updateObject(
        layer.id,
        object.copyWith(label: _labelController.text.trim()),
      );
      setState(() => _error = null);
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }

  void _duplicateSelection() {
    try {
      _editor.duplicateSelection(idFactory: (_) => _newId());
      _syncSelectedLabel();
      setState(() => _error = null);
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }

  void _deleteSelection() {
    try {
      _editor.deleteSelection();
      _syncSelectedLabel();
      setState(() => _error = null);
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }

  Widget _toolbar() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 190,
          child: ComboBox<ParkingCanvasTool>(
            value: _editor.activeTool,
            isExpanded: true,
            items: [
              for (final tool in ParkingCanvasTool.values)
                ComboBoxItem(
                  value: tool,
                  child: Text(_toolLabel(tool)),
                ),
            ],
            onChanged: (tool) {
              if (tool == null) return;
              setState(() {
                _editor.setActiveTool(tool);
                _draftStart = null;
                _draftEnd = null;
                _polygonPoints = [];
              });
            },
          ),
        ),
        Button(
          onPressed: _editor.canUndo
              ? () => setState(() {
                    _editor.undo();
                    _syncSelectedLabel();
                  })
              : null,
          child: const Text('Annuler'),
        ),
        Button(
          onPressed: _editor.canRedo
              ? () => setState(() {
                    _editor.redo();
                    _syncSelectedLabel();
                  })
              : null,
          child: const Text('Rétablir'),
        ),
        Button(
          onPressed: _editor.selectedObjectIds.isEmpty
              ? null
              : _duplicateSelection,
          child: const Text('Dupliquer'),
        ),
        Button(
          onPressed: _editor.selectedObjectIds.isEmpty
              ? null
              : _deleteSelection,
          child: const Text('Supprimer'),
        ),
        Checkbox(
          checked: _snapToGrid,
          onChanged: (value) => setState(() => _snapToGrid = value ?? false),
          content: const Text('Accrochage'),
        ),
        Button(
          onPressed: () => setState(() => _camera = null),
          child: const Text('Recentrer'),
        ),
      ],
    );
  }

  Widget _layerControls() {
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      children: [
        for (final layer in _editor.document.layers)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                checked: layer.visible,
                onChanged: (value) => setState(
                  () => _editor.setLayerVisibility(layer.id, value ?? false),
                ),
                content: Text(layer.name),
              ),
              Checkbox(
                checked: layer.locked,
                onChanged: (value) => setState(
                  () => _editor.setLayerLocked(layer.id, value ?? false),
                ),
                content: const Text('Verrou'),
              ),
            ],
          ),
      ],
    );
  }

  Widget _inspector() {
    final selected = _singleSelectedObject;
    final layer = _layerForSelectedObject;
    if (selected == null || layer == null) {
      return Center(
        child: Text(
          'Sélectionne un objet pour afficher ses propriétés.',
          textAlign: TextAlign.center,
          style: TextStyle(color: widget.mutedColor),
        ),
      );
    }
    final bounds = selected.bounds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'PROPRIÉTÉS',
          style: FluentTheme.of(context).typography.caption?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
        ),
        const SizedBox(height: 8),
        Text(_toolLabel(_toolForObject(selected.type))),
        const SizedBox(height: 4),
        Text(
          'Calque : ${layer.name}',
          style: TextStyle(color: widget.mutedColor),
        ),
        const SizedBox(height: 10),
        Text(
          'Emprise : ${bounds.width.toStringAsFixed(2)} × '
          '${bounds.height.toStringAsFixed(2)} m',
          style: TextStyle(color: widget.mutedColor),
        ),
        const SizedBox(height: 12),
        const Text('Libellé'),
        const SizedBox(height: 5),
        TextBox(
          controller: _labelController,
          maxLines: 2,
          placeholder: 'Nom ou annotation',
          onSubmitted: (_) => _applyLabel(),
        ),
        const SizedBox(height: 8),
        Button(
          onPressed: _applyLabel,
          child: const Text('Appliquer'),
        ),
      ],
    );
  }

  ParkingCanvasTool _toolForObject(ParkingCanvasObjectType type) {
    switch (type) {
      case ParkingCanvasObjectType.rectangle:
        return ParkingCanvasTool.rectangle;
      case ParkingCanvasObjectType.polygon:
        return ParkingCanvasTool.polygon;
      case ParkingCanvasObjectType.line:
        return ParkingCanvasTool.line;
      case ParkingCanvasObjectType.road:
        return ParkingCanvasTool.road;
      case ParkingCanvasObjectType.wall:
        return ParkingCanvasTool.wall;
      case ParkingCanvasObjectType.gate:
        return ParkingCanvasTool.gate;
      case ParkingCanvasObjectType.entrance:
        return ParkingCanvasTool.entrance;
      case ParkingCanvasObjectType.exit:
        return ParkingCanvasTool.exit;
      case ParkingCanvasObjectType.obstacle:
        return ParkingCanvasTool.obstacle;
      case ParkingCanvasObjectType.text:
        return ParkingCanvasTool.text;
      case ParkingCanvasObjectType.dimension:
        return ParkingCanvasTool.dimension;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(1200.0, screen.width - 32).toDouble();
    final dialogHeight = math.min(820.0, screen.height - 32).toDouble();

    return ContentDialog(
      constraints: BoxConstraints.tight(Size(dialogWidth, dialogHeight)),
      title: const Text('Concepteur vectoriel du parking'),
      content: SizedBox(
        width: dialogWidth,
        height: dialogHeight - 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _toolbar(),
            const SizedBox(height: 8),
            _layerControls(),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 760;
                  final inspectorWidth =
                      math.min(240.0, constraints.maxWidth * 0.32).toDouble();
                  final canvas = ClipRect(
                    child: LayoutBuilder(
                      builder: (context, canvasConstraints) {
                        final size = ui.Size(
                          canvasConstraints.maxWidth,
                          canvasConstraints.maxHeight,
                        );
                        _canvasSize = size;
                        final camera = _cameraFor(size);
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: _onCanvasTap,
                          onScaleStart: _onScaleStart,
                          onScaleUpdate: _onScaleUpdate,
                          onScaleEnd: _onScaleEnd,
                          child: CustomPaint(
                            size: size,
                            painter: _ParkingCanvasEditorPainter(
                              layout: widget.layout,
                              document: _editor.document,
                              zones: widget.zones,
                              spaces: widget.spaces,
                              camera: camera,
                              backgroundImage: _backgroundImage,
                              backgroundPixelWidth:
                                  widget.backgroundPixelWidth,
                              backgroundPixelHeight:
                                  widget.backgroundPixelHeight,
                              draftStart: _draftStart,
                              draftEnd: _draftEnd,
                              polygonPoints: _polygonPoints,
                              selectedObjectIds: _editor.selectedObjectIds,
                              primaryColor: widget.primaryColor,
                              backgroundColor: widget.backgroundColor,
                              borderColor: widget.borderColor,
                              textColor: widget.textColor,
                              mutedColor: widget.mutedColor,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                  final inspector = Container(
                    width: narrow ? constraints.maxWidth : inspectorWidth,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.backgroundColor,
                      border: Border(
                        left: BorderSide(color: widget.borderColor),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: _inspector(),
                    ),
                  );
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: widget.borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: narrow
                        ? Column(
                            children: [
                              Expanded(child: canvas),
                              SizedBox(height: 124, child: inspector),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: canvas),
                              inspector,
                            ],
                          ),
                  );
                },
              ),
            ),
            if (_polygonPoints.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('${_polygonPoints.length} sommet(s) en cours'),
                  const Spacer(),
                  Button(
                    onPressed: _cancelPolygon,
                    child: const Text('Annuler le polygone'),
                  ),
                  const SizedBox(width: 6),
                  Button(
                    onPressed:
                        _polygonPoints.length >= 3 ? _finishPolygon : null,
                    child: const Text('Terminer le polygone'),
                  ),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 6),
              InfoBar(
                title: const Text('Édition impossible'),
                content: Text(_error!),
                severity: InfoBarSeverity.warning,
              ),
            ],
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            try {
              _editor.document.validate(
                widthM: widget.layout.widthM,
                heightM: widget.layout.heightM,
              );
              Navigator.of(context).pop(_editor.document);
            } catch (error) {
              setState(() => _error = error.toString());
            }
          },
          child: const Text('Enregistrer le plan'),
        ),
      ],
    );
  }
}

class _ParkingCanvasEditorPainter extends CustomPainter {
  final ParkingLayout layout;
  final ParkingCanvasDocument document;
  final List<ParkingZone> zones;
  final List<ParkingSpace> spaces;
  final ParkingCanvasCamera camera;
  final ui.Image? backgroundImage;
  final int? backgroundPixelWidth;
  final int? backgroundPixelHeight;
  final ParkingPoint? draftStart;
  final ParkingPoint? draftEnd;
  final List<ParkingPoint> polygonPoints;
  final Set<String> selectedObjectIds;
  final Color primaryColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedColor;

  _ParkingCanvasEditorPainter({
    required this.layout,
    required this.document,
    required this.zones,
    required this.spaces,
    required this.camera,
    required this.backgroundImage,
    required this.backgroundPixelWidth,
    required this.backgroundPixelHeight,
    required this.draftStart,
    required this.draftEnd,
    required this.polygonPoints,
    required this.selectedObjectIds,
    required this.primaryColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedColor,
  });

  ui.Offset _screen(ParkingPoint point) {
    final transformed = camera.worldToScreen(
      point,
      layoutHeightM: layout.heightM,
    );
    return ui.Offset(transformed.x, transformed.y);
  }

  ui.Path _path(List<ParkingPoint> points, {bool close = false}) {
    final path = ui.Path();
    if (points.isEmpty) return path;
    final first = _screen(points.first);
    path.moveTo(first.dx, first.dy);
    for (final point in points.skip(1)) {
      final next = _screen(point);
      path.lineTo(next.dx, next.dy);
    }
    if (close) path.close();
    return path;
  }

  List<ParkingPoint> _spacePoints(ParkingSpace space) {
    if (space.polygon != null) return space.polygon!.points;
    final geometry = space.rectangle;
    if (geometry == null) return const [];
    final angle = geometry.rotationDegrees * math.pi / 180;
    final cosine = math.cos(angle);
    final sine = math.sin(angle);
    final halfWidth = geometry.width / 2;
    final halfLength = geometry.length / 2;
    return [
      for (final corner in const [
        ParkingPoint(x: -1, y: -1),
        ParkingPoint(x: 1, y: -1),
        ParkingPoint(x: 1, y: 1),
        ParkingPoint(x: -1, y: 1),
      ])
        ParkingPoint(
          x: geometry.centerX +
              corner.x * halfWidth * cosine -
              corner.y * halfLength * sine,
          y: geometry.centerY +
              corner.x * halfWidth * sine +
              corner.y * halfLength * cosine,
        ),
    ];
  }

  Color _tokenColor(String? token, Color fallback) {
    switch (token) {
      case 'primary':
        return primaryColor;
      case 'success':
        return const Color(0xFF24B47E);
      case 'warning':
        return const Color(0xFFE3A33D);
      case 'danger':
        return const Color(0xFFE05B67);
      case 'border':
        return borderColor;
      case 'muted':
        return mutedColor;
      case 'text':
        return textColor;
      case 'surface':
        return backgroundColor;
      default:
        return fallback;
    }
  }

  void _drawText(
    ui.Canvas canvas,
    String text,
    ui.Offset position, {
    required Color color,
    required double fontSize,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize.clamp(8.0, 40.0).toDouble(),
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: 220);
    painter.paint(
      canvas,
      position.translate(-painter.width / 2, -painter.height / 2),
    );
  }

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    canvas.drawColor(backgroundColor, ui.BlendMode.src);
    final scale = camera.pixelsPerMeter;
    final topLeft = _screen(ParkingPoint(x: 0, y: layout.heightM));
    final bottomRight = _screen(ParkingPoint(x: layout.widthM, y: 0));
    final planRect = ui.Rect.fromPoints(topLeft, bottomRight);
    canvas.drawRect(
      planRect,
      ui.Paint()
        ..color = backgroundColor.withValues(alpha: 0.4)
        ..style = ui.PaintingStyle.fill,
    );

    final image = backgroundImage;
    final transform = layout.backgroundTransform;
    ParkingCanvasLayer? backgroundLayer;
    for (final layer in document.layers) {
      if (layer.type == ParkingCanvasLayerType.background) {
        backgroundLayer = layer;
        break;
      }
    }
    final showBackground = backgroundLayer?.visible ?? true;
    if (image != null && transform != null && showBackground) {
      final metersPerPixel =
          transform.calibration?.metersPerPixel ?? transform.metersPerPixel;
      final sourceWidth = (backgroundPixelWidth ?? image.width).toDouble();
      final sourceHeight = (backgroundPixelHeight ?? image.height).toDouble();
      final center = _screen(
        transform.imageToWorld(
          ParkingPoint(x: sourceWidth / 2, y: sourceHeight / 2),
        ),
      );
      final imageWidth = sourceWidth * metersPerPixel * scale;
      final imageHeight = sourceHeight * metersPerPixel * scale;
      canvas.save();
      canvas.clipRect(planRect);
      canvas.translate(center.dx, center.dy);
      canvas.rotate(-transform.rotationDegrees * math.pi / 180);
      canvas.drawImageRect(
        image,
        ui.Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        ),
        ui.Rect.fromLTWH(
          -imageWidth / 2,
          -imageHeight / 2,
          imageWidth,
          imageHeight,
        ),
        ui.Paint()
          ..color = ui.Color.fromARGB(
            (transform.opacity * 255).round(),
            255,
            255,
            255,
          )
          ..filterQuality = ui.FilterQuality.medium,
      );
      canvas.restore();
    }

    var gridStep = math.max(
      layout.gridStepM,
      math.max(layout.widthM, layout.heightM) / 100,
    ).toDouble();
    while (gridStep * scale < 18) {
      gridStep *= 2;
    }
    final gridPaint = ui.Paint()
      ..color = borderColor.withValues(alpha: 0.28)
      ..strokeWidth = 0.7;
    for (var x = 0.0; x <= layout.widthM; x += gridStep) {
      final a = _screen(ParkingPoint(x: x, y: 0));
      final b = _screen(ParkingPoint(x: x, y: layout.heightM));
      canvas.drawLine(a, b, gridPaint);
    }
    for (var y = 0.0; y <= layout.heightM; y += gridStep) {
      final a = _screen(ParkingPoint(x: 0, y: y));
      final b = _screen(ParkingPoint(x: layout.widthM, y: y));
      canvas.drawLine(a, b, gridPaint);
    }

    for (final zone in zones) {
      final boundary = zone.boundary;
      if (boundary == null) continue;
      final path = _path(boundary.points, close: true);
      canvas.drawPath(
        path,
        ui.Paint()
          ..color = primaryColor.withValues(alpha: 0.04)
          ..style = ui.PaintingStyle.fill,
      );
      canvas.drawPath(
        path,
        ui.Paint()
          ..color = primaryColor.withValues(alpha: 0.6)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      if (boundary.points.isNotEmpty) {
        _drawText(
          canvas,
          zone.code,
          _screen(boundary.points.first),
          color: mutedColor,
          fontSize: 12,
        );
      }
    }

    for (final space in spaces) {
      final points = _spacePoints(space);
      if (points.length < 3) continue;
      final path = _path(points, close: true);
      canvas.drawPath(
        path,
        ui.Paint()
          ..color = primaryColor.withValues(alpha: 0.08)
          ..style = ui.PaintingStyle.fill,
      );
      canvas.drawPath(
        path,
        ui.Paint()
          ..color = borderColor
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      final center = ParkingPoint(
        x: points.map((point) => point.x).reduce(
              (left, right) => left + right,
            ) /
            points.length,
        y: points.map((point) => point.y).reduce(
              (left, right) => left + right,
            ) /
            points.length,
      );
      _drawText(
        canvas,
        space.code,
        _screen(center),
        color: textColor,
        fontSize: math.min(11, scale * 0.65).toDouble(),
      );
    }

    for (final layer in document.layers) {
      if (!layer.visible) continue;
      for (final object in layer.objects) {
        if (!object.visible) continue;
        final closed = object.type == ParkingCanvasObjectType.rectangle ||
            object.type == ParkingCanvasObjectType.polygon ||
            object.type == ParkingCanvasObjectType.obstacle;
        final path = _path(object.points, close: closed);
        final strokeColor =
            _tokenColor(object.strokeColorToken, primaryColor);
        if (closed && object.fillColorToken != null) {
          canvas.drawPath(
            path,
            ui.Paint()
              ..color = _tokenColor(
                object.fillColorToken,
                primaryColor,
              ).withValues(alpha: 0.18)
              ..style = ui.PaintingStyle.fill,
          );
        }
        final strokeWidth = math.max(
          1.0,
          object.strokeWidthM * scale,
        ).toDouble();
        canvas.drawPath(
          path,
          ui.Paint()
            ..color = strokeColor
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = ui.StrokeCap.round
            ..strokeJoin = ui.StrokeJoin.round,
        );
        if (object.type == ParkingCanvasObjectType.text ||
            object.type == ParkingCanvasObjectType.dimension ||
            object.label != null) {
          final label = object.label ??
              (object.type == ParkingCanvasObjectType.dimension
                  ? '${object.bounds.width.toStringAsFixed(2)} m'
                  : '');
          if (label.isNotEmpty) {
            _drawText(
              canvas,
              label,
              _screen(object.points.first),
              color: strokeColor,
              fontSize: (object.textHeightM ?? 0.5) * scale,
            );
          }
        }
        if (selectedObjectIds.contains(object.id)) {
          final bounds = object.bounds;
          final corners = [
            ParkingPoint(x: bounds.minX, y: bounds.minY),
            ParkingPoint(x: bounds.maxX, y: bounds.minY),
            ParkingPoint(x: bounds.maxX, y: bounds.maxY),
            ParkingPoint(x: bounds.minX, y: bounds.maxY),
          ];
          canvas.drawPath(
            _path(corners, close: true),
            ui.Paint()
              ..color = primaryColor
              ..style = ui.PaintingStyle.stroke
              ..strokeWidth = 1.8
              ..strokeJoin = ui.StrokeJoin.round,
          );
        }
      }
    }

    if (polygonPoints.isNotEmpty) {
      canvas.drawPath(
        _path(polygonPoints),
        ui.Paint()
          ..color = primaryColor
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      for (final point in polygonPoints) {
        final position = _screen(point);
        canvas.drawCircle(position, 4, ui.Paint()..color = primaryColor);
      }
    }

    final start = draftStart;
    final end = draftEnd;
    if (start != null && end != null) {
      final previewPoints = [
        start,
        ParkingPoint(x: end.x, y: start.y),
        end,
        ParkingPoint(x: start.x, y: end.y),
      ];
      canvas.drawPath(
        _path(previewPoints, close: true),
        ui.Paint()
          ..color = primaryColor.withValues(alpha: 0.12)
          ..style = ui.PaintingStyle.fill,
      );
      canvas.drawPath(
        _path([start, end]),
        ui.Paint()
          ..color = primaryColor
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    canvas.drawRect(
      planRect,
      ui.Paint()
        ..color = borderColor
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _ParkingCanvasEditorPainter oldDelegate) => true;
}
