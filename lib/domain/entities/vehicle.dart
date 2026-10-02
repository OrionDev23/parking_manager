enum VehicleStatus { active, inactive, archived }

class Vehicle {
  final String id;
  final String companyId;
  final String? siteId;
  final String registration;
  final String? brand;
  final String? model;
  final String? color;
  final VehicleStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Vehicle({
    required this.id,
    required this.companyId,
    this.siteId,
    required this.registration,
    this.brand,
    this.model,
    this.color,
    this.status = VehicleStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });
}
