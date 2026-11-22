import 'dart:convert';

import 'package:appwrite/appwrite.dart';

/// A permanent server-side rejection returned by the tenant quota API.
class TenantResourceException implements Exception {
  final int statusCode;
  final String code;
  final String message;

  const TenantResourceException({
    required this.statusCode,
    required this.code,
    required this.message,
  });

  bool get isPermanent =>
      statusCode >= 400 && statusCode < 500 &&
      statusCode != 401 && statusCode != 429;

  @override
  String toString() => message;
}

/// Routes vehicle and driver mutations through the authenticated tenant API.
/// The function owns quota checks, atomic usage counters and row permissions.
class TenantResourceApi {
  static const String functionId = 'company-tenant-api';

  final Client client;

  const TenantResourceApi(this.client);

  Future<Map<String, dynamic>> createResource({
    required String resource,
    required String companyId,
    required String rowId,
    required Map<String, dynamic> data,
  }) {
    return _execute({
      'action': 'tenant_create_resource',
      'resource': resource,
      'companyId': companyId,
      'rowId': rowId,
      'data': data,
    });
  }

  Future<Map<String, dynamic>> deleteResource({
    required String resource,
    required String companyId,
    required String rowId,
  }) {
    return _execute({
      'action': 'tenant_delete_resource',
      'resource': resource,
      'companyId': companyId,
      'rowId': rowId,
    });
  }

  Future<Map<String, dynamic>> _execute(
    Map<String, dynamic> payload,
  ) async {
    final execution = await Functions(client).createExecution(
      functionId: functionId,
      body: jsonEncode(payload),
      // The function reads req.bodyJson. Explicitly mark the execution body
      // as JSON; otherwise the function can receive the raw text without a
      // parsed action and answer with "Unknown action".
      headers: const {'content-type': 'application/json'},
      // The outbox must inspect the function's structured response before
      // acknowledging the local operation.
      xasync: false,
    );

    Map<String, dynamic> response = {};
    try {
      final decoded = jsonDecode(execution.responseBody);
      if (decoded is Map) {
        response = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Preserve the HTTP execution status as the primary failure signal.
    }

    final status = execution.responseStatusCode;
    if (status < 200 ||
        status >= 300 ||
        response['ok'] != true) {
      throw TenantResourceException(
        statusCode: status >= 400 && status < 600 ? status : 502,
        code: response['code']?.toString() ?? 'tenant_resource_rejected',
        message: response['message']?.toString() ??
            'Le service de licence a refusé cette opération.',
      );
    }

    return response;
  }
}
