import 'edition.dart';

class License {
  final String id;
  final String companyId;
  final ParcotoEdition edition;
  final DateTime? expiresAt;
  final int? maxUsers;
  final int? maxVehicles;

  const License({
    required this.id,
    required this.companyId,
    required this.edition,
    this.expiresAt,
    this.maxUsers,
    this.maxVehicles,
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
}
