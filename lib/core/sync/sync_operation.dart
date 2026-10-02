enum SyncOperationType { create, update, delete }
enum SyncOperationStatus { pending, processing, completed, failed, conflict }

class SyncOperation {
  final String id;
  final String companyId;
  final String deviceId;
  final String entity;
  final String entityId;
  final SyncOperationType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final SyncOperationStatus status;
  final int attempts;

  const SyncOperation({
    required this.id,
    required this.companyId,
    required this.deviceId,
    required this.entity,
    required this.entityId,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.status = SyncOperationStatus.pending,
    this.attempts = 0,
  });
}
