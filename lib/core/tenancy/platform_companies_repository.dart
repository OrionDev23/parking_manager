import 'dart:convert';

import 'package:appwrite/appwrite.dart';

import '../../providers/client_database.dart';

class PlatformCompany {
  final String companyId;
  final String name;
  final String slug;
  final String status;
  final String createdAt;
  final int activeUsers;
  final Map<String, dynamic> entitlement;

  const PlatformCompany({
    required this.companyId,
    required this.name,
    required this.slug,
    required this.status,
    required this.createdAt,
    required this.activeUsers,
    required this.entitlement,
  });

  factory PlatformCompany.fromJson(Map<String, dynamic> json) {
    return PlatformCompany(
      companyId: json['companyId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      status: json['status']?.toString() ?? 'unknown',
      createdAt: json['createdAt']?.toString() ?? '',
      activeUsers: (json['activeUsers'] as num?)?.toInt() ?? 0,
      entitlement: json['entitlement'] is Map
          ? Map<String, dynamic>.from(json['entitlement'] as Map)
          : const {},
    );
  }

  DateTime? get expiresAt =>
      DateTime.tryParse(entitlement['expiresAt']?.toString() ?? '');

  int quota(String key) => (entitlement[key] as num?)?.toInt() ?? 0;
  int get monthlyPrice =>
      (entitlement['monthlyPrice'] as num?)?.toInt() ?? 0;
  String get currency => entitlement['currency']?.toString() ?? 'DZD';
}

class PlatformCompaniesRepository {
  static const functionId = 'company-tenant-api';

  Future<Map<String, dynamic>> _execute(
    Map<String, dynamic> payload,
  ) async {
    final client = DatabaseGetter.client;
    if (client == null) {
      throw StateError('Le client Appwrite n’est pas initialisé.');
    }
    final execution = await Functions(client).createExecution(
      functionId: functionId,
      body: jsonEncode(payload),
    );
    Map<String, dynamic> response = {};
    try {
      response = Map<String, dynamic>.from(
        jsonDecode(execution.responseBody) as Map,
      );
    } catch (_) {}
    if (execution.responseStatusCode < 200 ||
        execution.responseStatusCode >= 300 ||
        response['ok'] != true) {
      throw StateError(
        response['message']?.toString() ??
            'Le service plateforme a retourné une erreur.',
      );
    }
    return response;
  }

  Future<List<PlatformCompany>> list() async {
    final response = await _execute({'action': 'platform_list_companies'});
    final values = response['companies'];
    if (values is! List) {
      throw const FormatException('Liste des entreprises invalide.');
    }
    return values
        .whereType<Map>()
        .map((value) => PlatformCompany.fromJson(
              Map<String, dynamic>.from(value),
            ))
        .toList(growable: false);
  }

  Future<void> create({
    required String name,
    required String slug,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
    required DateTime startsAt,
    required DateTime expiresAt,
    required int maxUsers,
    required int maxVehicles,
    required int maxEmployees,
    required int maxDrivers,
    required int maxSites,
    required int monthlyPrice,
    required String billingCycle,
    required String currency,
    required String notes,
  }) async {
    await _execute({
      'action': 'create_company',
      'name': name,
      'slug': slug,
      'adminName': adminName,
      'adminEmail': adminEmail,
      'adminPassword': adminPassword,
      'startsAt': startsAt.toUtc().toIso8601String(),
      'expiresAt': expiresAt.toUtc().toIso8601String(),
      'maxUsers': maxUsers,
      'maxVehicles': maxVehicles,
      'maxEmployees': maxEmployees,
      'maxDrivers': maxDrivers,
      'maxSites': maxSites,
      'monthlyPrice': monthlyPrice,
      'billingCycle': billingCycle,
      'currency': currency,
      'notes': notes,
    });
  }
}
