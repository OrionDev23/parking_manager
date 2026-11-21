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
      attribution: json['attribution']?.toString(),
      sourceUrl: json['sourceUrl']?.toString(),
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
