import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../../providers/client_database.dart';
import '../../utilities/vehicle_brands.dart';

class VehicleMake {
  final String id;
  final String name;
  final String normalizedName;
  final String category;
  final List<String> aliases;
  final String? logoUrl;
  final String? logoFileId;
  final bool isActive;
  final String source;

  const VehicleMake({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.category,
    this.aliases = const [],
    this.logoUrl,
    this.logoFileId,
    this.isActive = true,
    this.source = 'global_catalogue',
  });

  factory VehicleMake.fromRow({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return VehicleMake(
      id: id,
      name: data['name']?.toString() ?? id,
      normalizedName: data['normalizedName']?.toString() ??
          VehicleMakeService.normalize(data['name']?.toString() ?? id),
      category: data['category']?.toString() ?? 'other',
      aliases: (data['aliases'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(growable: false),
      logoUrl: data['logoUrl']?.toString(),
      logoFileId: data['logoFileId']?.toString(),
      isActive: data['isActive'] != false,
      source: data['source']?.toString() ?? 'global_catalogue',
    );
  }
}

class VehicleMakeService {
  VehicleMakeService._();

  static const String tableId = 'vehicle_makes';
  static const String functionId = 'company-tenant-api';

  static List<VehicleMake> _cache = const [];
  static DateTime? _loadedAt;
  static Future<List<VehicleMake>>? _pendingLoad;

  static List<VehicleMake> get cached => List.unmodifiable(_cache);

  static Future<List<VehicleMake>> load({bool forceRefresh = false}) async {
    final loadedAt = _loadedAt;
    if (!forceRefresh &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) < const Duration(minutes: 15)) {
      return cached;
    }

    final pending = _pendingLoad;
    if (pending != null) return pending;

    final future = _loadFromDatabase();
    _pendingLoad = future;
    try {
      return await future;
    } finally {
      if (identical(_pendingLoad, future)) {
        _pendingLoad = null;
      }
    }
  }

  static Future<List<VehicleMake>> _loadFromDatabase() async {
    final database = DatabaseGetter.database;
    if (database == null) {
      throw StateError('La base Appwrite n’est pas initialisée.');
    }

    final result = await database.listRows(
      databaseId: databaseId,
      tableId: tableId,
      queries: [Query.limit(500)],
    );
    final makes = result.rows
        .map(
          (row) => VehicleMake.fromRow(
            id: row.$id,
            data: Map<String, dynamic>.from(row.data),
          ),
        )
        .where((make) => make.isActive && make.name.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _cache = makes;
    _loadedAt = DateTime.now();
    return cached;
  }

  static Future<void> invalidate() async {
    _loadedAt = null;
  }

  static String normalize(String value) {
    return value
        .normalizeVehicleMakeText();
  }

  static String _slug(String value) {
    return normalize(value).replaceAll(' ', '-');
  }

  static VehicleMake? byId(String? id) {
    final value = id?.trim() ?? '';
    if (value.isEmpty) return null;
    for (final make in _cache) {
      if (make.id == value) return make;
    }
    return null;
  }

  static VehicleMake? _findByNameOrAlias(String value) {
    final normalized = normalize(value);
    if (normalized.isEmpty) return null;
    for (final make in _cache) {
      if (make.normalizedName == normalized ||
          make.aliases.any((alias) => normalize(alias) == normalized)) {
        return make;
      }
    }
    return null;
  }

  /// Converts historical numeric values to stable catalogue IDs.
  /// Unknown legacy values are retained as slugs instead of being lost.
  static String? canonicalId(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty || raw == '-1' || raw.toLowerCase() == 'nonind') {
      return null;
    }

    final legacyIndex = int.tryParse(raw);
    if (legacyIndex != null) {
      if (legacyIndex <= 0 || legacyIndex >= vehiculeBrands.length) {
        return null;
      }
      final legacyName = vehiculeBrands[legacyIndex];
      final matched = _findByNameOrAlias(legacyName);
      return matched?.id ?? _slug(legacyName);
    }

    VehicleMake? matched;
    for (final make in _cache) {
      if (make.id == raw) {
        matched = make;
        break;
      }
    }
    matched ??= _findByNameOrAlias(raw);
    return matched?.id ?? _slug(raw);
  }

  static String nameFor(String? value) {
    final id = canonicalId(value);
    if (id == null) return '';
    final make = byId(id);
    if (make != null) return make.name;

    final numeric = int.tryParse(value ?? '');
    if (numeric != null &&
        numeric > 0 &&
        numeric < vehiculeBrands.length) {
      return vehiculeBrands[numeric];
    }
    return value?.trim() ?? '';
  }

  static String? logoFor(String? value) {
    final make = byId(canonicalId(value));
    final url = make?.logoUrl?.trim();
    return url == null || url.isEmpty ? null : url;
  }

  static String? legacyLogoAssetFor(String? value) {
    final make = byId(canonicalId(value));
    if (make == null) return null;
    final candidates = <String>[make.name, ...make.aliases]
        .map(normalize)
        .toSet();
    final index = vehiculeBrands.indexWhere(
      (legacyName) => candidates.contains(normalize(legacyName)),
    );
    return index > 0 ? 'assets/images/marques/$index.webp' : null;
  }

  static List<VehicleMake> search(String query) {
    final normalized = normalize(query);
    if (normalized.isEmpty) return cached;
    return _cache.where((make) {
      return make.normalizedName.contains(normalized) ||
          make.aliases.any((alias) => normalize(alias).contains(normalized));
    }).toList(growable: false);
  }

  static Future<List<String>> searchIds(String query) async {
    return search(query).map((make) => make.id).toList(growable: false);
  }

  static Future<Map<String, dynamic>> capabilities({
    required String companyId,
  }) async {
    final client = DatabaseGetter.client;
    if (client == null) {
      throw StateError('Le client Appwrite n’est pas initialisé.');
    }
    final execution = await Functions(client).createExecution(
      functionId: functionId,
      body: jsonEncode({
        'action': 'vehicle_make_capabilities',
        'companyId': companyId,
      }),
      xasync: false,
    );
    Map<String, dynamic> response = {};
    try {
      final decoded = jsonDecode(execution.responseBody);
      if (decoded is Map) response = Map<String, dynamic>.from(decoded);
    } catch (_) {}
    if (execution.responseStatusCode < 200 ||
        execution.responseStatusCode >= 300 ||
        response['ok'] != true) {
      throw StateError(
        response['message']?.toString() ??
            'Impossible de vérifier les droits sur le catalogue des marques.',
      );
    }
    return response;
  }

  static Future<Map<String, dynamic>> create({
    required String companyId,
    required String name,
    required String category,
    List<String> aliases = const [],
  }) async {
    final client = DatabaseGetter.client;
    if (client == null) {
      throw StateError('Le client Appwrite n’est pas initialisé.');
    }
    final execution = await Functions(client).createExecution(
      functionId: functionId,
      body: jsonEncode({
        'action': 'vehicle_make_create',
        'companyId': companyId,
        'name': name,
        'category': category,
        'aliases': aliases,
      }),
      xasync: false,
    );
    Map<String, dynamic> response = {};
    try {
      final decoded = jsonDecode(execution.responseBody);
      if (decoded is Map) response = Map<String, dynamic>.from(decoded);
    } catch (_) {}

    if (execution.responseStatusCode < 200 ||
        execution.responseStatusCode >= 300 ||
        response['ok'] != true) {
      throw StateError(
        response['message']?.toString() ??
            'Impossible d’ajouter cette marque au catalogue partagé.',
      );
    }
    await invalidate();
    return response;
  }

  static Future<void> update({
    required String makeId,
    String? name,
    String? category,
    List<String>? aliases,
    bool? isActive,
    String? logoUrl,
  }) async {
    final client = DatabaseGetter.client;
    if (client == null) {
      throw StateError('Le client Appwrite n’est pas initialisé.');
    }
    final execution = await Functions(client).createExecution(
      functionId: functionId,
      body: jsonEncode({
        'action': 'vehicle_make_update',
        'makeId': makeId,
        if (name != null) 'name': name,
        if (category != null) 'category': category,
        if (aliases != null) 'aliases': aliases,
        if (isActive != null) 'isActive': isActive,
        if (logoUrl != null) 'logoUrl': logoUrl,
      }),
      xasync: false,
    );
    Map<String, dynamic> response = {};
    try {
      final decoded = jsonDecode(execution.responseBody);
      if (decoded is Map) response = Map<String, dynamic>.from(decoded);
    } catch (_) {}

    if (execution.responseStatusCode < 200 ||
        execution.responseStatusCode >= 300 ||
        response['ok'] != true) {
      throw StateError(
        response['message']?.toString() ??
            'Impossible de modifier la marque.',
      );
    }
    await invalidate();
  }
}

extension on String {
  String normalizeVehicleMakeText() {
    const accents = {
      'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a',
      'ç': 'c', 'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
      'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
      'ñ': 'n', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o',
      'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
      'ý': 'y', 'ÿ': 'y',
    };
    var value = toLowerCase();
    for (final entry in accents.entries) {
      value = value.replaceAll(entry.key, entry.value);
    }
    return value
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}

class VehicleMakeLogo extends StatelessWidget {
  final String? makeId;
  final double size;

  const VehicleMakeLogo({
    super.key,
    required this.makeId,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final make = VehicleMakeService.byId(
      VehicleMakeService.canonicalId(makeId),
    );
    final logoUrl = make?.logoUrl?.trim();
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * .2),
        child: Image.network(
          logoUrl,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _legacyOrFallback(context, make?.name),
        ),
      );
    }
    return _legacyOrFallback(context, make?.name);
  }

  Widget _legacyOrFallback(BuildContext context, String? name) {
    final asset = VehicleMakeService.legacyLogoAssetFor(makeId);
    if (asset == null) return _fallback(context, name);
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => _fallback(context, name),
    );
  }

  Widget _fallback(BuildContext context, String? name) {
    final label = name?.trim().isNotEmpty == true
        ? name!.trim().substring(0, 1).toUpperCase()
        : null;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: FluentTheme.of(context).micaBackgroundColor,
        borderRadius: BorderRadius.circular(size * .2),
        border: Border.all(color: Colors.grey[50]),
      ),
      child: label == null
          ? Icon(FluentIcons.car, size: size * .55)
          : Text(
              label,
              style: TextStyle(
                fontSize: size * .48,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
