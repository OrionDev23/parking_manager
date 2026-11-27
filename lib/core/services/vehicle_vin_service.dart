import 'dart:convert';

import 'package:appwrite/appwrite.dart';

import '../../providers/client_database.dart';

class VehicleVinDecodeResult {
  final String vin;
  final String status;
  final List<String> providers;
  final Map<String, dynamic> data;
  final List<String> warnings;
  final String? note;

  const VehicleVinDecodeResult({
    required this.vin,
    required this.status,
    required this.providers,
    required this.data,
    required this.warnings,
    this.note,
  });

  factory VehicleVinDecodeResult.fromJson(Map<String, dynamic> json) {
    return VehicleVinDecodeResult(
      vin: json['vin']?.toString() ?? '',
      status: json['status']?.toString() ?? 'not_found',
      providers: (json['providers'] as List? ?? const [])
          .map((value) => value.toString())
          .toList(growable: false),
      data: Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
      warnings: (json['warnings'] as List? ?? const [])
          .map((value) => value.toString())
          .toList(growable: false),
      note: json['note']?.toString(),
    );
  }

  bool get hasVehicleIdentity =>
      data['make'] != null &&
      data['model'] != null &&
      data['modelYear'] != null;
}

class VehicleVinService {
  VehicleVinService._();

  static const String functionId = 'company-tenant-api';

  static Future<VehicleVinDecodeResult> decode({
    required String companyId,
    required String vin,
  }) async {
    final client = DatabaseGetter.client;
    if (client == null) {
      throw StateError('Le client Appwrite n’est pas initialisé.');
    }

    final normalizedVin = vin.replaceAll(RegExp(r'\\s+'), '').toUpperCase();
    final execution = await Functions(client).createExecution(
      functionId: functionId,
      body: jsonEncode({
        'action': 'vehicle_vin_decode',
        'companyId': companyId,
        'vin': normalizedVin,
      }),
      xasync: false,
    );

    Map<String, dynamic> response = {};
    try {
      final decoded = jsonDecode(execution.responseBody);
      if (decoded is Map) response = Map<String, dynamic>.from(decoded);
    } catch (_) {
      // The response is validated below; do not leak raw server data.
    }

    if (execution.responseStatusCode < 200 ||
        execution.responseStatusCode >= 300 ||
        response['ok'] != true) {
      throw StateError(
        response['message']?.toString() ??
            'Le service de décodage VIN a répondu avec le code ${execution.responseStatusCode}.',
      );
    }

    return VehicleVinDecodeResult.fromJson(response);
  }
}
