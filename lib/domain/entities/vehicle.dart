class Vehicle {
  final String id;
  final String companyId;
  final String? siteId;
  final String registration;
  final bool foreignRegistration;
  final int? wilaya;
  final String? commune;
  final String? daira;
  final String? address;
  final DateTime? registrationDate;
  final double? receiptAmount;
  final String? receiptNumber;
  final String? ownerLastName;
  final String? ownerFirstName;
  final String? ownerProfession;
  final String? serialNumber;
  final String? type;
  final String? brand;
  final String? genre;
  final int? usefulLoad;
  final int? totalWeight;
  final int? seats;
  final int? power;
  final String? energy;
  final String? body;
  final int? usageYear;
  final List<String> previousRegistrations;
  final String? createdBy;
  final String? country;
  final String? state;
  final int? currentState;
  final String? subsidiary;
  final String? department;
  final String? direction;
  final String? ownership;
  final String? driverOwnership;
  final bool service;
  final String? driverRegistration;
  final bool heavy;
  final bool decision;
  final String? location;
  final int perimeter;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Vehicle({
    required this.id, required this.companyId, this.siteId, required this.registration,
    required this.foreignRegistration, this.wilaya, this.commune, this.daira,
    this.address, this.registrationDate, this.receiptAmount, this.receiptNumber,
    this.ownerLastName, this.ownerFirstName, this.ownerProfession, this.serialNumber,
    this.type, this.brand, this.genre, this.usefulLoad, this.totalWeight, this.seats,
    this.power, this.energy, this.body, this.usageYear,
    this.previousRegistrations = const [], this.createdBy, this.country, this.state,
    this.currentState, this.subsidiary, this.department, this.direction,
    this.ownership, this.driverOwnership, this.service = false, this.driverRegistration,
    this.heavy = false, this.decision = false, this.location, this.perimeter = 0,
    required this.createdAt, required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'companyId': companyId, 'siteId': siteId, 'registration': registration,
    'foreignRegistration': foreignRegistration, 'wilaya': wilaya, 'commune': commune,
    'daira': daira, 'address': address, 'registrationDate': registrationDate?.toIso8601String(),
    'receiptAmount': receiptAmount, 'receiptNumber': receiptNumber,
    'ownerLastName': ownerLastName, 'ownerFirstName': ownerFirstName,
    'ownerProfession': ownerProfession, 'serialNumber': serialNumber, 'type': type,
    'brand': brand, 'genre': genre, 'usefulLoad': usefulLoad, 'totalWeight': totalWeight,
    'seats': seats, 'power': power, 'energy': energy, 'body': body, 'usageYear': usageYear,
    'previousRegistrations': previousRegistrations, 'createdBy': createdBy, 'country': country,
    'state': state, 'currentState': currentState, 'subsidiary': subsidiary,
    'department': department, 'direction': direction, 'ownership': ownership,
    'driverOwnership': driverOwnership, 'service': service, 'driverRegistration': driverRegistration,
    'heavy': heavy, 'decision': decision, 'location': location, 'perimeter': perimeter,
    'createdAt': createdAt.toIso8601String(), 'updatedAt': updatedAt.toIso8601String(),
  };

  factory Vehicle.fromMap(Map<String, dynamic> map) => Vehicle(
    id: map['id'] as String,
    companyId: map['companyId'] as String,
    siteId: map['siteId'] as String?,
    registration: map['registration'] as String,
    foreignRegistration: map['foreignRegistration'] as bool? ?? false,
    wilaya: (map['wilaya'] as num?)?.toInt(), commune: map['commune'] as String?,
    daira: map['daira'] as String?, address: map['address'] as String?,
    registrationDate: _date(map['registrationDate']),
    receiptAmount: (map['receiptAmount'] as num?)?.toDouble(),
    receiptNumber: map['receiptNumber'] as String?, ownerLastName: map['ownerLastName'] as String?,
    ownerFirstName: map['ownerFirstName'] as String?, ownerProfession: map['ownerProfession'] as String?,
    serialNumber: map['serialNumber'] as String?, type: map['type'] as String?,
    brand: map['brand'] as String?, genre: map['genre'] as String?,
    usefulLoad: (map['usefulLoad'] as num?)?.toInt(), totalWeight: (map['totalWeight'] as num?)?.toInt(),
    seats: (map['seats'] as num?)?.toInt(), power: (map['power'] as num?)?.toInt(),
    energy: map['energy'] as String?, body: map['body'] as String?,
    usageYear: (map['usageYear'] as num?)?.toInt(),
    previousRegistrations: List<String>.from(map['previousRegistrations'] as List? ?? const []),
    createdBy: map['createdBy'] as String?, country: map['country'] as String?,
    state: map['state'] as String?, currentState: (map['currentState'] as num?)?.toInt(),
    subsidiary: map['subsidiary'] as String?, department: map['department'] as String?,
    direction: map['direction'] as String?, ownership: map['ownership'] as String?,
    driverOwnership: map['driverOwnership'] as String?, service: map['service'] as bool? ?? false,
    driverRegistration: map['driverRegistration'] as String?, heavy: map['heavy'] as bool? ?? false,
    decision: map['decision'] as bool? ?? false, location: map['location'] as String?,
    perimeter: (map['perimeter'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.parse(map['createdAt'] as String),
    updatedAt: DateTime.parse(map['updatedAt'] as String),
  );

  static DateTime? _date(dynamic value) => value == null ? null : DateTime.tryParse(value.toString());
}
