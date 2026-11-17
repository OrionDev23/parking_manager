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
  int get priceAmount =>
      (entitlement['priceAmount'] as num?)?.toInt() ?? 0;
  String get currency => entitlement['currency']?.toString() ?? 'DZD';
}

class PlatformCompanyAdministrator {
  final String membershipId;
  final String userId;
  final String name;
  final String email;
  final String role;
  final String status;
  final bool isPlatformSuperAdmin;
  final String createdAt;

  const PlatformCompanyAdministrator({
    required this.membershipId,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.isPlatformSuperAdmin,
    required this.createdAt,
  });

  factory PlatformCompanyAdministrator.fromJson(Map<String, dynamic> json) {
    return PlatformCompanyAdministrator(
      membershipId: json['membershipId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'admin',
      status: json['status']?.toString() ?? 'active',
      isPlatformSuperAdmin: json['isPlatformSuperAdmin'] == true,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class PlatformCompaniesRepository {
  static const functionId = 'company-tenant-api';

  bool canCreateCompany = false;
  String createCompanyReason =
      'La création des entreprises n’est pas encore activée.';

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
    final capabilities = response['capabilities'];
    canCreateCompany = capabilities is Map &&
        capabilities['canCreateCompany'] == true;
    createCompanyReason = capabilities is Map
        ? capabilities['createCompanyReason']?.toString() ?? ''
        : 'La création des entreprises n’est pas encore activée.';
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

  Future<Map<String, dynamic>> preparePermissions(String companyId) {
    return _execute({
      'action': 'platform_prepare_company_rows',
      'companyId': companyId,
    });
  }

  Future<Map<String, dynamic>> create({
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
    required int priceAmount,
    required String billingCycle,
    required String currency,
    required String notes,
    String address = '',
    String phone = '',
    String companyEmail = '',
    String nif = '',
    String nis = '',
    String rc = '',
    String art = '',
    String description = '',
  }) {
    return _execute({
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
      'priceAmount': priceAmount,
      'billingCycle': billingCycle,
      'currency': currency,
      'notes': notes,
      'address': address,
      'phone': phone,
      'companyEmail': companyEmail,
      'nif': nif,
      'nis': nis,
      'rc': rc,
      'art': art,
      'description': description,
    });
  }

  Future<List<PlatformCompanyAdministrator>> listAdministrators(
    String companyId,
  ) async {
    final response = await _execute({
      'action': 'platform_list_company_admins',
      'companyId': companyId,
    });
    final values = response['administrators'];
    if (values is! List) {
      throw const FormatException('Liste des administrateurs invalide.');
    }
    return values
        .whereType<Map>()
        .map((value) => PlatformCompanyAdministrator.fromJson(
              Map<String, dynamic>.from(value),
            ))
        .toList(growable: false);
  }

  Future<void> addAdministrator({
    required String companyId,
    required String name,
    required String email,
    required String password,
  }) async {
    await _execute({
      'action': 'platform_add_company_admin',
      'companyId': companyId,
      'name': name,
      'email': email,
      'password': password,
    });
  }

  Future<void> updateAdministratorName({
    required String companyId,
    required String membershipId,
    required String name,
  }) async {
    await _execute({
      'action': 'platform_update_company_admin',
      'companyId': companyId,
      'membershipId': membershipId,
      'name': name,
    });
  }

  Future<void> revokeAdministrator({
    required String companyId,
    required String membershipId,
  }) async {
    await _execute({
      'action': 'platform_revoke_company_admin',
      'companyId': companyId,
      'membershipId': membershipId,
    });
  }

  Future<void> updateCompany({
    required String companyId,
    required String name,
    required String slug,
    required String status,
    DateTime? startsAt,
    DateTime? expiresAt,
    int? maxUsers,
    int? maxVehicles,
    int? maxEmployees,
    int? maxDrivers,
    int? maxSites,
    int? priceAmount,
    String? billingCycle,
    String? currency,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'action': 'platform_update_company',
      'companyId': companyId,
      'name': name,
      'slug': slug,
      'status': status,
    };
    if (startsAt != null) {
      payload['startsAt'] = startsAt.toUtc().toIso8601String();
    }
    if (expiresAt != null) {
      payload['expiresAt'] = expiresAt.toUtc().toIso8601String();
    }
    if (maxUsers != null) payload['maxUsers'] = maxUsers;
    if (maxVehicles != null) payload['maxVehicles'] = maxVehicles;
    if (maxEmployees != null) payload['maxEmployees'] = maxEmployees;
    if (maxDrivers != null) payload['maxDrivers'] = maxDrivers;
    if (maxSites != null) payload['maxSites'] = maxSites;
    if (priceAmount != null) payload['priceAmount'] = priceAmount;
    if (billingCycle != null) payload['billingCycle'] = billingCycle;
    if (currency != null) payload['currency'] = currency;
    if (notes != null) payload['notes'] = notes;
    await _execute(payload);
  }
}
