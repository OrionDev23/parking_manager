import 'dart:convert';

import 'package:appwrite/appwrite.dart';

import '../../providers/client_database.dart';
import '../permissions/permission_catalog.dart';

class CompanySelectionRequired implements Exception {
  final List<CompanyMembership> memberships;
  const CompanySelectionRequired(this.memberships);
}

class CompanyMembership {
  final String companyId;
  final String companyName;
  final String companySlug;
  final String teamId;
  final String profileRowId;
  final String role;
  final String membershipId;
  final Map<String, dynamic> entitlement;

  const CompanyMembership({
    required this.companyId,
    required this.companyName,
    required this.companySlug,
    required this.teamId,
    required this.profileRowId,
    required this.role,
    required this.membershipId,
    this.entitlement = const {},
  });

  factory CompanyMembership.fromJson(Map<String, dynamic> json) {
    return CompanyMembership(
      companyId: json['companyId']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      companySlug: json['companySlug']?.toString() ?? '',
      teamId: json['teamId']?.toString() ?? '',
      profileRowId: json['profileRowId']?.toString() ?? '',
      role: json['role']?.toString() ?? 'viewer',
      membershipId: json['membershipId']?.toString() ?? '',
      entitlement: json['entitlement'] is Map
          ? Map<String, dynamic>.from(json['entitlement'] as Map)
          : const {},
    );
  }

  Set<String> get permissions {
    if (role == 'owner' || role == 'admin') {
      return PermissionCatalog.all.map((permission) => permission.id).toSet();
    }
    if (role == 'manager') return PermissionCatalog.preset('Gestionnaire');
    // employee and viewer deliberately receive the least-privilege preset
    // until company-specific custom permission profiles are migrated.
    return PermissionCatalog.preset('Lecture seule');
  }

  bool matches(String selector) {
    final normalized = selector.trim().toLowerCase();
    return normalized.isEmpty ||
        companyId.toLowerCase() == normalized ||
        companySlug.toLowerCase() == normalized;
  }
}

/// Calls the server-side tenant API using the currently authenticated
/// Appwrite session. No admin API key is stored in the Flutter application.
class CompanyMembershipResolver {
  static const functionId = 'company-tenant-api';

  Future<bool> resolvePlatformSession() async {
    final client = DatabaseGetter.client;
    if (client == null) throw StateError('Appwrite client is not initialized.');
    final execution = await Functions(client).createExecution(
      functionId: functionId,
      body: jsonEncode({'action': 'platform_resolve'}),
    );
    if (execution.responseStatusCode < 200 || execution.responseStatusCode >= 300) {
      return false;
    }
    final decoded = jsonDecode(execution.responseBody);
    return decoded is Map && decoded['ok'] == true && decoded['isPlatformSuperAdmin'] == true;
  }

  Future<void> returnToPlatformContext() async {
    final client = DatabaseGetter.client;
    if (client == null) {
      throw StateError('Appwrite client is not initialized.');
    }
    final execution = await Functions(client).createExecution(
      functionId: functionId,
      body: jsonEncode({'action': 'platform_return_to_platform'}),
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
            'Impossible de restaurer les droits du Super Admin.',
      );
    }
  }

  Future<void> returnToPlatform() async {
    final client = DatabaseGetter.client;
    if (client == null) {
      throw StateError('Appwrite client is not initialized.');
    }
    final execution = await Functions(client).createExecution(
      functionId: functionId,
      body: jsonEncode({'action': 'platform_return_to_platform'}),
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
            'Impossible de restaurer la console Super Admin.',
      );
    }
  }

  Future<Map<String, dynamic>> authorizePlatformCompany(String companyId) async {
    final client = DatabaseGetter.client;
    if (client == null) {
      throw StateError('Appwrite client is not initialized.');
    }
    final execution = await Functions(client).createExecution(
      functionId: functionId,
      body: jsonEncode({
        'action': 'platform_select_company',
        'companyId': companyId,
      }),
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
            'Impossible d’ouvrir le contexte de cette entreprise.',
      );
    }
    final company = response['company'] is Map
        ? Map<String, dynamic>.from(response['company'] as Map)
        : const <String, dynamic>{};
    return {
      'teamId': company['teamId']?.toString() ?? '',
      'profileRowId': company['profileRowId']?.toString() ?? '',
      'entitlement': response['entitlement'] is Map
          ? Map<String, dynamic>.from(response['entitlement'] as Map)
          : const <String, dynamic>{},
    };
  }

  Future<List<CompanyMembership>> resolve() async {
    final client = DatabaseGetter.client;
    if (client == null) {
      throw StateError('Appwrite client is not initialized.');
    }

    final execution = await Functions(client).createExecution(
      functionId: functionId,
      body: jsonEncode({'action': 'resolve'}),
    );

    if (execution.responseStatusCode < 200 ||
        execution.responseStatusCode >= 300) {
      Map<String, dynamic> failure = {};
      try {
        failure = Map<String, dynamic>.from(
          jsonDecode(execution.responseBody) as Map,
        );
      } catch (_) {}
      throw StateError(
        failure['message']?.toString() ??
            'Unable to resolve the companies linked to this account.',
      );
    }

    final decoded = jsonDecode(execution.responseBody);
    if (decoded is! Map) {
      throw const FormatException('Invalid tenant API response.');
    }
    final payload = Map<String, dynamic>.from(decoded);
    final values = payload['memberships'];
    if (values is! List) {
      throw const FormatException('Membership list is missing.');
    }

    return values
        .whereType<Map>()
        .map(
          (item) => CompanyMembership.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((membership) => membership.companyId.isNotEmpty)
        .toList(growable: false);
  }

  Future<CompanyMembership> select({String? selector}) async {
    final memberships = await resolve();
    if (memberships.isEmpty) {
      throw StateError(
        'Ce compte n’est associé à aucune entreprise Parcoto active.',
      );
    }

    final requested = selector?.trim() ?? '';
    if (requested.isNotEmpty) {
      final matches = memberships
          .where((membership) => membership.matches(requested))
          .toList(growable: false);
      if (matches.length == 1) return matches.single;
      if (matches.isEmpty) {
        throw StateError(
          'Aucune entreprise active ne correspond au code renseigné.',
        );
      }
      throw StateError(
        'Le code entreprise est ambigu. Utilisez son identifiant exact.',
      );
    }

    if (memberships.length == 1) return memberships.single;
    throw CompanySelectionRequired(memberships);
  }
}
