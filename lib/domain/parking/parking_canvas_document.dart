import 'dart:convert';
import 'dart:math' as math;

import 'parking_geometry.dart';

enum ParkingCanvasLayerType {
  background,
  zones,
  circulation,
  spaces,
  annotations,
}

enum ParkingCanvasObjectType {
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
}

class ParkingCanvasBounds {
  final double minX;
  final double minY;
  final double maxX;
  final double maxY;

  const ParkingCanvasBounds({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  double get width => maxX - minX;
  double get height => maxY - minY;
}

class ParkingCanvasDocument {
  static const int currentSchemaVersion = 1;
  static const int maxLayers = 200;
  static const int maxObjects = 10000;

  final int schemaVersion;
  final List<ParkingCanvasLayer> layers;

  const ParkingCanvasDocument({
    this.schemaVersion = currentSchemaVersion,
    required this.layers,
  });

  factory ParkingCanvasDocument.empty() =>
      const ParkingCanvasDocument(layers: []);

  factory ParkingCanvasDocument.withDefaultLayers() =>
      const ParkingCanvasDocument(
        layers: [
          ParkingCanvasLayer(
            id: 'layer-background',
            type: ParkingCanvasLayerType.background,
            name: 'Fond de plan',
            visible: true,
            locked: true,
            sortOrder: 0,
          ),
          ParkingCanvasLayer(
            id: 'layer-zones',
            type: ParkingCanvasLayerType.zones,
            name: 'Limites et zones',
            visible: true,
            sortOrder: 1,
          ),
          ParkingCanvasLayer(
            id: 'layer-circulation',
            type: ParkingCanvasLayerType.circulation,
            name: 'Circulation',
            visible: true,
            sortOrder: 2,
          ),
          ParkingCanvasLayer(
            id: 'layer-spaces',
            type: ParkingCanvasLayerType.spaces,
            name: 'Places',
            visible: true,
            sortOrder: 3,
          ),
          ParkingCanvasLayer(
            id: 'layer-annotations',
            type: ParkingCanvasLayerType.annotations,
            name: 'Annotations',
            visible: true,
            sortOrder: 4,
          ),
        ],
      );

  factory ParkingCanvasDocument.fromJsonString(String source) {
    dynamic decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw const FormatException('Canvas document must contain valid JSON.');
    }

    final int version;
    final dynamic rawLayers;
    if (decoded is List) {
      // Version 0 was stored as a bare layer array. Keep it readable so
      // existing parking plans can be opened and migrated on their next save.
      version = currentSchemaVersion;
      rawLayers = decoded;
    } else if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final rawVersion = map['schemaVersion'];
      if (rawVersion is! int || rawVersion != currentSchemaVersion) {
        throw const FormatException('Unsupported canvas document version.');
      }
      version = rawVersion;
      rawLayers = map['layers'];
    } else {
      throw const FormatException('Canvas document must be an object or layer array.');
    }

    if (rawLayers is! List) {
      throw const FormatException('Canvas document layers must be an array.');
    }

    final layers = <ParkingCanvasLayer>[];
    for (final rawLayer in rawLayers) {
      if (rawLayer is! Map) {
        throw const FormatException('Canvas layers must be JSON objects.');
      }
      layers.add(
        ParkingCanvasLayer.fromJson(Map<String, dynamic>.from(rawLayer)),
      );
    }
    return ParkingCanvasDocument(schemaVersion: version, layers: layers);
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'layers': layers.map((layer) => layer.toJson()).toList(),
      };

  String encode() => jsonEncode(toJson());

  ParkingCanvasDocument copyWith({
    int? schemaVersion,
    List<ParkingCanvasLayer>? layers,
  }) =>
      ParkingCanvasDocument(
        schemaVersion: schemaVersion ?? this.schemaVersion,
        layers: layers ?? this.layers,
      );

  void validate({
    required double widthM,
    required double heightM,
  }) {
    if (schemaVersion != currentSchemaVersion) {
      throw const FormatException('Unsupported canvas document version.');
    }
    if (!widthM.isFinite ||
        !heightM.isFinite ||
        widthM <= 0 ||
        heightM <= 0) {
      throw ArgumentError('Canvas dimensions must be finite and positive.');
    }
    if (layers.length > maxLayers) {
      throw const FormatException('A canvas cannot contain more than 200 layers.');
    }

    final layerIds = <String>{};
    final objectIds = <String>{};
    var objectCount = 0;
    for (final layer in layers) {
      layer.validate();
      if (!layerIds.add(layer.id)) {
        throw const FormatException('Canvas layer IDs must be unique.');
      }
      objectCount += layer.objects.length;
      if (objectCount > maxObjects) {
        throw const FormatException('A canvas cannot contain more than 10000 objects.');
      }
      for (final object in layer.objects) {
        object.validate();
        if (!objectIds.add(object.id)) {
          throw const FormatException('Canvas object IDs must be unique.');
        }
        for (final point in object.points) {
          if (point.x < 0 ||
              point.y < 0 ||
              point.x > widthM ||
              point.y > heightM) {
            throw const FormatException('Canvas geometry exceeds layout bounds.');
          }
        }
      }
    }
  }
}

class ParkingCanvasLayer {
  final String id;
  final ParkingCanvasLayerType type;
  final String name;
  final bool visible;
  final bool locked;
  final int sortOrder;
  final List<ParkingCanvasObject> objects;

  const ParkingCanvasLayer({
    required this.id,
    required this.type,
    required this.name,
    this.visible = true,
    this.locked = false,
    this.sortOrder = 0,
    this.objects = const [],
  });

  factory ParkingCanvasLayer.fromJson(Map<String, dynamic> json) {
    final id = _requiredString(json, 'id', maxLength: 36);
    final rawType = _requiredString(json, 'type', maxLength: 32);
    final type = _layerTypeFromString(rawType);
    final rawObjects = json['objects'] ?? const [];
    if (rawObjects is! List) {
      throw const FormatException('Canvas layer objects must be an array.');
    }
    final objects = <ParkingCanvasObject>[];
    for (final rawObject in rawObjects) {
      if (rawObject is! Map) {
        throw const FormatException('Canvas objects must be JSON objects.');
      }
      objects.add(
        ParkingCanvasObject.fromJson(
          Map<String, dynamic>.from(rawObject),
        ),
      );
    }

    return ParkingCanvasLayer(
      id: id,
      type: type,
      name: _optionalString(json, 'name') ?? id,
      visible: _optionalBool(json, 'visible') ?? true,
      locked: _optionalBool(json, 'locked') ?? false,
      sortOrder: _optionalInt(json, 'sortOrder') ?? 0,
      objects: objects,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'visible': visible,
        'locked': locked,
        'sortOrder': sortOrder,
        'objects': objects.map((object) => object.toJson()).toList(),
      };

  ParkingCanvasLayer copyWith({
    String? id,
    ParkingCanvasLayerType? type,
    String? name,
    bool? visible,
    bool? locked,
    int? sortOrder,
    List<ParkingCanvasObject>? objects,
  }) =>
      ParkingCanvasLayer(
        id: id ?? this.id,
        type: type ?? this.type,
        name: name ?? this.name,
        visible: visible ?? this.visible,
        locked: locked ?? this.locked,
        sortOrder: sortOrder ?? this.sortOrder,
        objects: objects ?? this.objects,
      );

  void validate() {
    _validateCanvasId(id, 'layer id');
    if (name.trim().isEmpty || name.length > 80) {
      throw ArgumentError.value(name, 'name', 'Layer names must contain 1 to 80 characters.');
    }
    if (sortOrder < 0) {
      throw ArgumentError.value(sortOrder, 'sortOrder');
    }
    if (objects.length > ParkingCanvasDocument.maxObjects) {
      throw const FormatException('A canvas layer contains too many objects.');
    }
  }
}

class ParkingCanvasObject {
  final String id;
  final ParkingCanvasObjectType type;
  final List<ParkingPoint> points;
  final double rotationDegrees;
  final double strokeWidthM;
  final double? textHeightM;
  final String? strokeColorToken;
  final String? fillColorToken;
  final String? label;
  final bool visible;
  final bool locked;
  final int sortOrder;

  const ParkingCanvasObject({
    required this.id,
    required this.type,
    required this.points,
    this.rotationDegrees = 0,
    this.strokeWidthM = 0.05,
    this.textHeightM,
    this.strokeColorToken,
    this.fillColorToken,
    this.label,
    this.visible = true,
    this.locked = false,
    this.sortOrder = 0,
  });

  factory ParkingCanvasObject.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'];
    if (rawPoints is! List) {
      throw const FormatException('Canvas object points must be an array.');
    }
    final points = <ParkingPoint>[];
    for (final rawPoint in rawPoints) {
      if (rawPoint is! Map) {
        throw const FormatException('Canvas points must be JSON objects.');
      }
      final point = Map<String, dynamic>.from(rawPoint);
      final x = point['xM'] ?? point['x'];
      final y = point['yM'] ?? point['y'];
      if (x is! num || y is! num || !x.isFinite || !y.isFinite) {
        throw const FormatException('Canvas point coordinates must be finite numbers.');
      }
      points.add(ParkingPoint(x: x.toDouble(), y: y.toDouble()));
    }

    final typeName = _requiredString(json, 'type', maxLength: 32);
    return ParkingCanvasObject(
      id: _requiredString(json, 'id', maxLength: 36),
      type: _objectTypeFromString(typeName),
      points: points,
      rotationDegrees:
          _optionalDouble(json, 'rotationDeg') ??
              _optionalDouble(json, 'rotationDegrees') ??
              0,
      strokeWidthM: _optionalDouble(json, 'strokeWidthM') ?? 0.05,
      textHeightM: _optionalDouble(json, 'textHeightM'),
      strokeColorToken:
          _optionalString(json, 'strokeColorToken', maxLength: 32),
      fillColorToken:
          _optionalString(json, 'fillColorToken', maxLength: 32),
      label: _optionalString(json, 'label', maxLength: 300),
      visible: _optionalBool(json, 'visible') ?? true,
      locked: _optionalBool(json, 'locked') ?? false,
      sortOrder: _optionalInt(json, 'sortOrder') ?? 0,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'points': [
          for (final point in points) {'xM': point.x, 'yM': point.y},
        ],
        'rotationDeg': rotationDegrees,
        'strokeWidthM': strokeWidthM,
        'textHeightM': textHeightM,
        'strokeColorToken': strokeColorToken,
        'fillColorToken': fillColorToken,
        'label': label,
        'visible': visible,
        'locked': locked,
        'sortOrder': sortOrder,
      };

  ParkingCanvasBounds get bounds {
    if (points.isEmpty) {
      throw StateError('Canvas object has no geometry points.');
    }
    final xs = points.map((point) => point.x);
    final ys = points.map((point) => point.y);
    return ParkingCanvasBounds(
      minX: xs.reduce(math.min),
      minY: ys.reduce(math.min),
      maxX: xs.reduce(math.max),
      maxY: ys.reduce(math.max),
    );
  }

  ParkingCanvasObject copyWith({
    String? id,
    ParkingCanvasObjectType? type,
    List<ParkingPoint>? points,
    double? rotationDegrees,
    double? strokeWidthM,
    double? textHeightM,
    String? strokeColorToken,
    String? fillColorToken,
    String? label,
    bool? visible,
    bool? locked,
    int? sortOrder,
  }) =>
      ParkingCanvasObject(
        id: id ?? this.id,
        type: type ?? this.type,
        points: points ?? this.points,
        rotationDegrees: rotationDegrees ?? this.rotationDegrees,
        strokeWidthM: strokeWidthM ?? this.strokeWidthM,
        textHeightM: textHeightM ?? this.textHeightM,
        strokeColorToken: strokeColorToken ?? this.strokeColorToken,
        fillColorToken: fillColorToken ?? this.fillColorToken,
        label: label ?? this.label,
        visible: visible ?? this.visible,
        locked: locked ?? this.locked,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  ParkingCanvasObject translated(double dx, double dy) {
    if (!dx.isFinite || !dy.isFinite) {
      throw ArgumentError('Canvas translation must be finite.');
    }
    return copyWith(
      points: [
        for (final point in points)
          ParkingPoint(x: point.x + dx, y: point.y + dy),
      ],
    );
  }

  void validate() {
    _validateCanvasId(id, 'object id');
    if (points.isEmpty) {
      throw const FormatException('Canvas objects require geometry points.');
    }
    switch (type) {
      case ParkingCanvasObjectType.rectangle:
        if (points.length != 4) {
          throw const FormatException('Rectangle objects require four points.');
        }
        break;
      case ParkingCanvasObjectType.polygon:
      case ParkingCanvasObjectType.obstacle:
        if (points.length < 3) {
          throw const FormatException('Polygon objects require at least three points.');
        }
        break;
      case ParkingCanvasObjectType.text:
        if (points.length != 1 || (label?.trim().isEmpty ?? true)) {
          throw const FormatException('Text objects require one anchor point and a label.');
        }
        break;
      case ParkingCanvasObjectType.dimension:
        if (points.length != 2) {
          throw const FormatException('Dimension objects require two points.');
        }
        break;
      case ParkingCanvasObjectType.line:
      case ParkingCanvasObjectType.road:
      case ParkingCanvasObjectType.wall:
      case ParkingCanvasObjectType.gate:
      case ParkingCanvasObjectType.entrance:
      case ParkingCanvasObjectType.exit:
        if (points.length < 2) {
          throw const FormatException('Line objects require at least two points.');
        }
        break;
    }
    if (!rotationDegrees.isFinite ||
        !strokeWidthM.isFinite ||
        strokeWidthM <= 0 ||
        strokeWidthM > 10) {
      throw ArgumentError('Canvas object style values must be finite and positive.');
    }
    if (textHeightM != null &&
        (!textHeightM!.isFinite || textHeightM! <= 0 || textHeightM! > 20)) {
      throw ArgumentError.value(textHeightM, 'textHeightM');
    }
    if ((label?.length ?? 0) > 300) {
      throw ArgumentError.value(label, 'label', 'Maximum 300 characters.');
    }
    _validateColorToken(strokeColorToken);
    _validateColorToken(fillColorToken);
    if (sortOrder < 0) {
      throw ArgumentError.value(sortOrder, 'sortOrder');
    }
    for (final point in points) {
      if (!point.x.isFinite || !point.y.isFinite) {
        throw const FormatException('Canvas coordinates must be finite.');
      }
    }
  }
}

ParkingCanvasLayerType _layerTypeFromString(String value) {
  switch (value) {
    case 'background':
    case 'base':
      return ParkingCanvasLayerType.background;
    case 'zones':
    case 'zone':
    case 'limits':
    case 'boundaries':
      return ParkingCanvasLayerType.zones;
    case 'circulation':
    case 'traffic':
      return ParkingCanvasLayerType.circulation;
    case 'spaces':
    case 'space':
      return ParkingCanvasLayerType.spaces;
    case 'annotations':
    case 'annotation':
      return ParkingCanvasLayerType.annotations;
    default:
      throw FormatException('Unsupported canvas layer type: $value');
  }
}

ParkingCanvasObjectType _objectTypeFromString(String value) {
  for (final type in ParkingCanvasObjectType.values) {
    if (type.name == value) return type;
  }
  throw FormatException('Unsupported canvas object type: $value');
}

String _requiredString(
  Map<String, dynamic> json,
  String key, {
  required int maxLength,
}) {
  final value = json[key];
  if (value is! String ||
      value.trim().isEmpty ||
      value.length > maxLength) {
    throw FormatException('Invalid canvas field: $key');
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
  if (value is! String || (maxLength != null && value.length > maxLength)) {
    throw FormatException('Invalid canvas field: $key');
  }
  return value;
}

bool? _optionalBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! bool) throw FormatException('Invalid canvas field: $key');
  return value;
}

int? _optionalInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! int) throw FormatException('Invalid canvas field: $key');
  return value;
}

double? _optionalDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! num || !value.isFinite) {
    throw FormatException('Invalid canvas field: $key');
  }
  return value.toDouble();
}

void _validateCanvasId(String value, String field) {
  if (value.trim().isEmpty ||
      value.length > 36 ||
      !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value)) {
    throw ArgumentError.value(value, field, 'Invalid canvas identifier.');
  }
}

void _validateColorToken(String? value) {
  if (value == null) return;
  if (value.length > 32 ||
      !RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(value)) {
    throw ArgumentError.value(value, 'colorToken');
  }
}
