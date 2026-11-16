import 'dart:convert';

import 'package:appwrite/appwrite.dart';

import '../../providers/client_database.dart';

class CompanyMembership {
  final String companyId;
  final String companyName;
  final String companySlug;
  final String role;
  final String membershipId;

  const CompanyMembership({
    required this.companyId,
    required this.companyName,
    required this.companySlug,
    required this.role,
    required this.membershipId,
  });

  factory CompanyMembership.fromJson(Map<String, dynamic> json) {
    return CompanyMembership(
      companyId: json['companyId']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      companySlug: json['companySlug']?.toString() ?? '',
      role: json['role']?.toString() ?? 'viewer',
      membershipId: json['membershipId']?.toString() ?? '',
    );
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
    throw StateError(
      'Ce compte appartient à plusieurs entreprises. Sélectionnez une entreprise.',
    );
  }
}
