import 'dart:convert';
import 'dart:typed_data';

import 'package:appwrite/appwrite.dart';

import '../../providers/client_database.dart';

class VehicleImageResolution {
  final bool found;
  final String? imageUrl;
  final String? fileId;
  final String source;
  final String? reason;
  final bool colorFallback;
  final bool replacementFound;
  final bool fromSharedCache;
  final String? license;
  final String? licenseUrl;
  final String? attribution;
  final String? sourceUrl;

  const VehicleImageResolution({
    required this.found,
    required this.source,
    this.imageUrl,
    this.fileId,
    this.reason,
    this.colorFallback = false,
    this.replacementFound = false,
    this.fromSharedCache = false,
    this.license,
    this.licenseUrl,
    this.attribution,
    this.sourceUrl,
  });

  factory VehicleImageResolution.fromJson(Map<String, dynamic> json) {
    return VehicleImageResolution(
      found: json['found'] == true,
      source: json['source']?.toString() ?? 'unknown',
      imageUrl: json['imageUrl']?.toString(),
      fileId: json['fileId']?.toString(),
      reason: json['reason']?.toString(),
      colorFallback: json['colorFallback'] == true,
      replacementFound: json['replacementFound'] == true,
      fromSharedCache: json['fromSharedCache'] == true,
      license: json['license']?.toString(),
      licenseUrl: json['licenseUrl']?.toString(),
      attribution: json['attribution']?.toString(),
      sourceUrl: json['sourceUrl']?.toString(),
    );
  }
}

class VehicleImageCandidate {
  final String token;
  final String source;
  final String imageUrl;
  final String? title;
  final String? license;
  final String? licenseUrl;
  final String? attribution;
  final String? sourceUrl;
  final bool colorFallback;
  final String? matchedColor;
  final bool forceRefresh;

  const VehicleImageCandidate({
    required this.token,
    required this.source,
    required this.imageUrl,
    this.title,
    this.license,
    this.licenseUrl,
    this.attribution,
    this.sourceUrl,
    this.colorFallback = false,
    this.matchedColor,
    this.forceRefresh = false,
  });

  factory VehicleImageCandidate.fromJson(Map<String, dynamic> json) {
    return VehicleImageCandidate(
      token: json['token']?.toString() ?? '',
      source: json['source']?.toString() ?? 'unknown',
      imageUrl: json['imageUrl']?.toString() ?? '',
      title: json['title']?.toString(),
      license: json['license']?.toString(),
      licenseUrl: json['licenseUrl']?.toString(),
      attribution: json['attribution']?.toString(),
      sourceUrl: json['sourceUrl']?.toString(),
      colorFallback: json['colorFallback'] == true,
      matchedColor: json['matchedColor']?.toString(),
      forceRefresh: json['forceRefresh'] == true,
    );
  }
}

class VehicleImageSearchResult {
  final List<VehicleImageCandidate> candidates;
  final VehicleImageResolution? cachedImage;
  final String? reason;

  const VehicleImageSearchResult({
    this.candidates = const [],
    this.cachedImage,
    this.reason,
  });

  factory VehicleImageSearchResult.fromJson(Map<String, dynamic> json) {
    final raw = json['candidates'];
    final candidates = raw is List
        ? raw
            .whereType<Map>()
            .map((item) => VehicleImageCandidate.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .where((item) => item.imageUrl.isNotEmpty && item.token.isNotEmpty)
            .toList(growable: false)
        : const <VehicleImageCandidate>[];
    return VehicleImageSearchResult(
      candidates: candidates,
      cachedImage: json['cachedImage'] is Map
          ? VehicleImageResolution.fromJson(
              Map<String, dynamic>.from(json['cachedImage'] as Map),
            )
          : null,
      reason: json['reason']?.toString(),
    );
  }
}

class VehicleImageCapabilities {
  final bool canUpload;
  final bool canForceRefresh;
  final bool isPlatformSuperAdmin;

  const VehicleImageCapabilities({
    this.canUpload = false,
    this.canForceRefresh = false,
    this.isPlatformSuperAdmin = false,
  });

  factory VehicleImageCapabilities.fromJson(Map<String, dynamic> json) {
    return VehicleImageCapabilities(
      canUpload: json['canUpload'] == true,
      canForceRefresh: json['canForceRefresh'] == true,
      isPlatformSuperAdmin: json['isPlatformSuperAdmin'] == true,
    );
  }
}

class VehicleImageService {
  static const String functionId = 'company-tenant-api';

  static Future<Map<String, dynamic>> _execute({
    required Map<String, dynamic> body,
  }) async {
    final client = DatabaseGetter.client;
    if (client == null) {
      throw StateError('Le client Appwrite n’est pas initialisé.');
    }

    final execution = await Functions(client).createExecution(
      functionId: functionId,
      body: jsonEncode(body),
      xasync: false,
    );

    if (execution.responseStatusCode < 200 ||
        execution.responseStatusCode >= 300) {
      Map<String, dynamic> failure = {};
      try {
        final decoded = jsonDecode(execution.responseBody);
        if (decoded is Map<String, dynamic>) failure = decoded;
      } catch (_) {}
      throw StateError(
        failure['message']?.toString() ??
            'La fonction image a répondu avec le code ${execution.responseStatusCode}.',
      );
    }

    final decoded = jsonDecode(execution.responseBody);
    if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
      throw StateError('Réponse invalide du service d’images.');
    }
    return decoded;
  }

  static Future<VehicleImageCapabilities> capabilities({
    required String companyId,
  }) async {
    final result = await _execute(
      body: {
        'action': 'vehicle_image_capabilities',
        'companyId': companyId,
      },
    );
    return VehicleImageCapabilities.fromJson(result);
  }

  static Future<VehicleImageSearchResult> searchCandidates({
    required String companyId,
    required String make,
    required String model,
    required int year,
    required String color,
    bool forceRefresh = false,
  }) async {
    final result = await _execute(
      body: {
        'action': 'vehicle_image_search_candidates',
        'companyId': companyId,
        'make': make,
        'model': model,
        'year': year,
        'color': color,
        if (forceRefresh) 'forceRefresh': true,
      },
    );
    return VehicleImageSearchResult.fromJson(result);
  }

  static Future<VehicleImageResolution> selectCandidate({
    required String companyId,
    required String make,
    required String model,
    required int year,
    required String color,
    required VehicleImageCandidate candidate,
  }) async {
    final result = await _execute(
      body: {
        'action': 'vehicle_image_select_candidate',
        'companyId': companyId,
        'make': make,
        'model': model,
        'year': year,
        'color': color,
        'candidateToken': candidate.token,
        if (candidate.forceRefresh) 'forceRefresh': true,
      },
    );
    return VehicleImageResolution.fromJson(result);
  }

  static Future<VehicleImageResolution> resolve({
    required String companyId,
    required String make,
    required String model,
    required int year,
    required String color,
    bool forceRefresh = false,
  }) async {
    final result = await _execute(
      body: {
        'action': 'vehicle_image_resolve',
        'companyId': companyId,
        'make': make,
        'model': model,
        'year': year,
        'color': color,
        if (forceRefresh) 'forceRefresh': true,
      },
    );
    return VehicleImageResolution.fromJson(result);
  }

  static Future<VehicleImageResolution> uploadCustom({
    required String companyId,
    required String make,
    required String model,
    required int year,
    required String color,
    required Uint8List bytes,
    required String mimeType,
    String? fileName,
  }) async {
    final result = await _execute(
      body: {
        'action': 'vehicle_image_upload',
        'companyId': companyId,
        'make': make,
        'model': model,
        'year': year,
        'color': color,
        'mimeType': mimeType,
        'fileName': fileName,
        'imageBase64': base64Encode(bytes),
      },
    );
    return VehicleImageResolution.fromJson(result);
  }
}
