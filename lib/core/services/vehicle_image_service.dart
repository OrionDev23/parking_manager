import 'dart:convert';

import 'package:appwrite/appwrite.dart';

import '../../providers/client_database.dart';

class VehicleImageResolution {
  final bool found;
  final String? imageUrl;
  final String? fileId;
  final String source;
  final String? reason;

  const VehicleImageResolution({
    required this.found,
    required this.source,
    this.imageUrl,
    this.fileId,
    this.reason,
  });

  factory VehicleImageResolution.fromJson(Map<String, dynamic> json) {
    return VehicleImageResolution(
      found: json['found'] == true,
      source: json['source']?.toString() ?? 'unknown',
      imageUrl: json['imageUrl']?.toString(),
      fileId: json['fileId']?.toString(),
      reason: json['reason']?.toString(),
    );
  }
}

class VehicleImageService {
  static const String functionId = 'company-tenant-api';

  static Future<VehicleImageResolution> resolve({
    required String companyId,
    required String make,
    required String model,
    required int year,
    required String color,
  }) async {
    final client = DatabaseGetter.client;
    if (client == null) {
      throw StateError('Le client Appwrite n’est pas initialisé.');
    }

    final execution = await Functions(client).createExecution(
      functionId: functionId,
      body: jsonEncode({
        'action': 'vehicle_image_resolve',
        'companyId': companyId,
        'make': make,
        'model': model,
        'year': year,
        'color': color,
      }),
      xasync: false,
    );

    if (execution.responseStatusCode < 200 ||
        execution.responseStatusCode >= 300) {
      Map<String, dynamic> failure = {};
      try {
        failure = jsonDecode(execution.responseBody) as Map<String, dynamic>;
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
    return VehicleImageResolution.fromJson(decoded);
  }
}
