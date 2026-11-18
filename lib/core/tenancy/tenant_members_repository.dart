import 'dart:convert';

import 'package:appwrite/appwrite.dart';

import '../../providers/client_database.dart';

class TenantMember {
  final String membershipId;
  final String userId;
  final String name;
  final String email;
  final String role;
  final String status;
  final String createdAt;
  final bool isCurrentUser;

  const TenantMember({
    required this.membershipId,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.isCurrentUser,
  });

  factory TenantMember.fromJson(Map<String, dynamic> json) {
    return TenantMember(
      membershipId: json['membershipId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'viewer',
      status: json['status']?.toString() ?? 'active',
      createdAt: json['createdAt']?.toString() ?? '',
      isCurrentUser: json['isCurrentUser'] == true,
    );
  }
}

class TenantMembersRepository {
  static const functionId = 'company-tenant-api';

  Future<Map<String, dynamic>> _execute(Map<String, dynamic> payload) async {
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
    } catch (_) {
      // A non-JSON function response is handled below as a failed request.
    }

    if (execution.responseStatusCode < 200 ||
        execution.responseStatusCode >= 300 ||
        response['ok'] != true) {
      throw StateError(
        response['message']?.toString() ??
            'Le service de gestion des membres a retourné une erreur.',
      );
    }
    return response;
  }

  Future<List<TenantMember>> list(String companyId) async {
    final response = await _execute({
      'action': 'list_members',
      'companyId': companyId,
    });
    final members = response['members'];
    if (members is! List) {
      throw const FormatException('Réponse membres invalide.');
    }
    return members
        .whereType<Map>()
        .map((item) => TenantMember.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<void> add({
    required String companyId,
    required String email,
    required String role,
  }) async {
    await _execute({
      'action': 'add_member',
      'companyId': companyId,
      'email': email.trim(),
      'role': role,
    });
  }

  Future<void> changeRole({
    required String companyId,
    required String membershipId,
    required String role,
  }) async {
    await _execute({
      'action': 'change_role',
      'companyId': companyId,
      'membershipId': membershipId,
      'role': role,
    });
  }

  Future<void> revoke({
    required String companyId,
    required String membershipId,
  }) async {
    await _execute({
      'action': 'revoke',
      'companyId': companyId,
      'membershipId': membershipId,
    });
  }
}
